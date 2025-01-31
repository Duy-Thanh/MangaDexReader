import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/navigation_service.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_saver/data_saver.dart';
import 'dart:io' show Platform;
import 'package:extended_image/extended_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/mangadex_service.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ImageCacheService {
  static final Map<String, List<String>> _chapterUrlCache = {};
  static final Map<String, ImageProvider> _imageCache = {};
  static const int _maxCachedChapters = 5;
  static const int _maxPreloadPagesNormal = 8;
  static const int _maxPreloadPagesDataSaving = 3;
  static final _dataSaver = DataSaver();

  static final cacheManager = DefaultCacheManager();

  // Add cache metadata to track image versions
  static const String _cacheMetadataKey = 'image_cache_metadata';

  // Structure to store cache metadata
  static Map<String, CacheMetadata> _cacheMetadata = {};

  // Load cache metadata on app start
  static Future<void> initCache() async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString(_cacheMetadataKey);
    if (metadataJson != null) {
      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      _cacheMetadata = metadata.map((key, value) =>
          MapEntry(key, CacheMetadata.fromJson(value as Map<String, dynamic>)));
    }
  }

  // Save cache metadata when updated
  static Future<void> _saveCacheMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = json.encode(
        _cacheMetadata.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString(_cacheMetadataKey, metadataJson);
  }

  // Cache chapter URLs
  static void cacheChapterUrls(String chapterId, List<String> urls) {
    _chapterUrlCache[chapterId] = urls;
    // Remove old cached chapters if exceeding limit
    if (_chapterUrlCache.length > _maxCachedChapters) {
      final oldestChapter = _chapterUrlCache.keys.first;
      _chapterUrlCache.remove(oldestChapter);
      // Also remove associated images
      _imageCache.removeWhere((key, _) => key.startsWith(oldestChapter));
    }
  }

  // Check system data saving settings
  static Future<bool> isSystemDataSavingEnabled() async {
    final mode = await _dataSaver.checkMode();
    return mode == DataSaverMode.enabled || mode == DataSaverMode.whitelisted;
  }

  // Check both system and app data saving settings
  static Future<bool> shouldLimitDataUsage(BuildContext context) async {
    // First check system data saving settings
    if (await isSystemDataSavingEnabled()) {
      return true;
    }

    // If system data saving is off, check app settings
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return settings.dataSavingMode;
  }

  // Preload with better error handling and parallel loading
  static Future<void> preloadChapterImages(
    String chapterId,
    List<String> urls,
    BuildContext context,
  ) async {
    final shouldLimit = await shouldLimitDataUsage(context);
    final maxPages =
        shouldLimit ? _maxPreloadPagesDataSaving : _maxPreloadPagesNormal;

    final urlsToPreload = urls.take(maxPages).toList();

    // Parallel preloading with rate limiting
    final futures = <Future>[];
    for (var i = 0; i < urlsToPreload.length; i++) {
      final url = urlsToPreload[i];
      final cacheKey = '${chapterId}_$url';

      if (!_imageCache.containsKey(cacheKey)) {
        // Add small delay between parallel requests to prevent rate limiting
        await Future.delayed(Duration(milliseconds: i * 100));

        futures.add(_preloadSingleImage(url, cacheKey, context));
      }
    }

    // Wait for all preloads to complete
    await Future.wait(futures);
  }

  static Future<void> _preloadSingleImage(
    String url,
    String cacheKey,
    BuildContext context,
  ) async {
    try {
      final etag =
          MangaDexService.getImageEtag(url) ?? DateTime.now().toString();
      await getCachedImageWithValidation(
        cacheKey.split('_')[0], // chapterId
        url,
        etag,
      );
    } catch (e) {
      print('Error preloading image: $e');
    }
  }

  // Get cached image with validation
  static Future<ImageProvider> getCachedImageWithValidation(
    String chapterId,
    String url,
    String etag, // From server response headers
  ) async {
    final cacheKey = '${chapterId}_$url';

    // Check if we have valid cached image
    if (_cacheMetadata.containsKey(cacheKey)) {
      final metadata = _cacheMetadata[cacheKey]!;
      if (metadata.etag == etag &&
          metadata.timestamp.isAfter(DateTime.now()
                  .subtract(const Duration(days: 7)) // Cache for 7 days
              )) {
        // Try to get from cache first
        final fileInfo = await cacheManager.getFileFromCache(url);
        if (fileInfo != null) {
          return FileImage(fileInfo.file);
        }
      }
    }

    // If no valid cache, download and cache
    final imageProvider = ExtendedNetworkImageProvider(
      url,
      cache: true,
      headers: {
        'User-Agent': 'MangaDexReader/1.0.0 (Flutter App)',
        'Accept': 'image/*',
        'Referer': 'https://mangadex.org/',
        'If-None-Match': _cacheMetadata[cacheKey]?.etag ?? '', // Add ETag check
      },
    );

    // Update cache metadata
    _cacheMetadata[cacheKey] = CacheMetadata(
      etag: etag,
      timestamp: DateTime.now(),
      url: url,
    );
    await _saveCacheMetadata();

    return imageProvider;
  }

  // Preload next chapter more aggressively
  static Future<void> preloadNextChapter(String nextChapterId) async {
    try {
      final nextPages = await MangaDexService.getChapterPages(nextChapterId);
      // Cache URLs immediately
      cacheChapterUrls(nextChapterId, nextPages);

      // Start preloading first few pages in background
      for (var url in nextPages.take(3)) {
        await cacheManager.downloadFile(url);
      }
    } catch (e) {
      print('Error preloading next chapter: $e');
    }
  }

  // Clear cache
  static Future<void> clearCache() async {
    _chapterUrlCache.clear();
    _imageCache.clear();

    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheDirs = [
        Directory('${cacheDir.path}/cacheimage'),
        Directory('${cacheDir.path}/libCachedImageData'),
      ];

      for (final dir in cacheDirs) {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          await dir.create(); // Recreate empty directory
        }
      }

      // Also clear extended_image memory cache
      clearMemoryImageCache();

      // And clear cache manager
      await cacheManager.emptyCache();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Check if on mobile data
  static Future<bool> isOnMobileData() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile) {
      // Check data saver mode when on mobile
      final mode = await _dataSaver.checkMode();
      return mode == DataSaverMode.enabled;
    }
    return false;
  }

  // Clear cache when low on memory
  static Future<void> handleLowMemory() async {
    await clearCache();
  }

  // Add this method to calculate cache size
  static Future<String> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheDirs = [
        Directory('${cacheDir.path}/cacheimage'), // extended_image cache
        Directory(
            '${cacheDir.path}/libCachedImageData'), // flutter_cache_manager
      ];

      int totalSize = 0;
      int fileCount = 0;

      for (final dir in cacheDirs) {
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              try {
                final size = await entity.length();
                totalSize += size;
                fileCount++;
              } catch (e) {
                print('Error reading file size: ${entity.path} - $e');
              }
            }
          }
        }
      }

      print('Total cached files: $fileCount');

      // Convert to appropriate unit with better precision
      if (totalSize < 1024) return '$totalSize B';
      if (totalSize < 1024 * 1024) {
        return '${(totalSize / 1024).toStringAsFixed(1)} KB';
      }
      if (totalSize < 1024 * 1024 * 1024) {
        return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      print('Error calculating cache size: $e');
      return 'Error';
    }
  }

  // Clear old cache entries
  static Future<void> cleanupOldCache() async {
    final now = DateTime.now();
    final oldEntries = _cacheMetadata.entries
        .where((entry) => entry.value.timestamp
            .isBefore(now.subtract(const Duration(days: 7))))
        .toList();

    for (final entry in oldEntries) {
      _cacheMetadata.remove(entry.key);
      final file = await cacheManager.getFileFromCache(entry.value.url);
      if (file != null) {
        await file.file.delete();
      }
    }
    await _saveCacheMetadata();
  }
}

// Add this class to store cache metadata
class CacheMetadata {
  final String etag;
  final DateTime timestamp;
  final String url;

  CacheMetadata({
    required this.etag,
    required this.timestamp,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'etag': etag,
        'timestamp': timestamp.toIso8601String(),
        'url': url,
      };

  factory CacheMetadata.fromJson(Map<String, dynamic> json) => CacheMetadata(
        etag: json['etag'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        url: json['url'] as String,
      );
}
