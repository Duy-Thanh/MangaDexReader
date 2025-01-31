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

class ImageCacheService {
  static final Map<String, List<String>> _chapterUrlCache = {};
  static final Map<String, ImageProvider> _imageCache = {};
  static const int _maxCachedChapters = 5;
  static const int _maxPreloadPagesNormal = 8;
  static const int _maxPreloadPagesDataSaving = 3;
  static final _dataSaver = DataSaver();

  static final cacheManager = DefaultCacheManager();

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
      // Try to get from cache first
      final fileInfo = await cacheManager.getFileFromCache(url);
      if (fileInfo == null) {
        // Download and cache if not found
        final imageProvider = ExtendedNetworkImageProvider(
          url,
          cache: true,
          headers: {
            'User-Agent': 'MangaDexReader/1.0.0 (Flutter App)',
            'Accept': 'image/*',
            'Referer': 'https://mangadex.org/',
          },
        );

        await precacheImage(imageProvider, context);
        _imageCache[cacheKey] = imageProvider;
      }
    } catch (e) {
      print('Error preloading image: $e');
    }
  }

  // Get cached image with fallback
  static ImageProvider getCachedImage(String chapterId, String url) {
    final cacheKey = '${chapterId}_$url';
    return _imageCache[cacheKey] ??
        ExtendedNetworkImageProvider(
          url,
          cache: true,
          headers: {
            'User-Agent': 'MangaDexReader/1.0.0 (Flutter App)',
            'Accept': 'image/*',
            'Referer': 'https://mangadex.org/',
          },
        );
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
  static void clearCache() {
    _chapterUrlCache.clear();
    _imageCache.clear();
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
  static void handleLowMemory() {
    clearCache();
  }
}
