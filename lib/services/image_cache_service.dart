import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/navigation_service.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_saver/data_saver.dart';
import 'dart:io' show Platform;

class ImageCacheService {
  static final Map<String, List<String>> _chapterUrlCache = {};
  static final Map<String, ImageProvider> _imageCache = {};
  static const int _maxCachedChapters = 3;
  static const int _maxPreloadPagesNormal = 5; // Normal mode
  static const int _maxPreloadPagesDataSaving = 2; // Data saving mode
  static final _dataSaver = DataSaver();

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

  // Update preload method to use new check
  static Future<void> preloadChapterImages(
    String chapterId,
    List<String> urls,
    BuildContext context,
  ) async {
    final shouldLimit = await shouldLimitDataUsage(context);
    final maxPages =
        shouldLimit ? _maxPreloadPagesDataSaving : _maxPreloadPagesNormal;

    final urlsToPreload = urls.take(maxPages).toList();

    for (var url in urlsToPreload) {
      final cacheKey = '${chapterId}_$url';
      if (!_imageCache.containsKey(cacheKey)) {
        try {
          final imageProvider = NetworkImage(
            url,
            headers: {
              'User-Agent': 'MangaDexReader/1.0.0 (Flutter App)',
              'Accept': 'image/*',
              'Referer': 'https://mangadex.org/',
            },
          );
          await precacheImage(imageProvider, context);
          _imageCache[cacheKey] = imageProvider;
        } catch (e) {
          print('Error preloading image: $e');
        }
      }
    }
  }

  // Get cached image if available
  static ImageProvider? getCachedImage(String chapterId, String url) {
    final cacheKey = '${chapterId}_$url';
    return _imageCache[cacheKey];
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
