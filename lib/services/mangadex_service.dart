import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import 'dart:async';

class MangaDexService {
  static const String baseUrl = 'https://api.mangadex.org';
  static final Map<String, String> _imageEtags = {};
  
  // Connection timeout settings
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _clientLifetime = Duration(seconds: 30);

  // Rate limiting: MangaDex allows 5 requests per second per IP
  static final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerSecond = 5;
  static const Duration _rateLimitWindow = Duration(seconds: 1);

  // Singleton client with periodic refresh to prevent stale connections
  static http.Client? _client;
  static DateTime? _clientCreatedAt;

  // Common headers required by MangaDex API
  static final Map<String, String> _headers = {
    'User-Agent': 'MangaDexReader/1.0.0',
    'Accept': 'application/json',
  };

  // Get or create client, refreshing if too old
  static http.Client _getClient() {
    final now = DateTime.now();
    
    // Refresh client if it doesn't exist or is older than 5 minutes
    if (_client == null || 
        _clientCreatedAt == null || 
        now.difference(_clientCreatedAt!) > _clientLifetime) {
      _client?.close();
      
      // Create IOClient with custom HttpClient that doesn't reuse connections
      final httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..idleTimeout = const Duration(seconds: 15);
      
      _client = IOClient(httpClient);
      _clientCreatedAt = now;
    }
    
    return _client!;
  }

  // Manually reset client if connection issues occur
  static void resetClient() {
    _client?.close();
    _client = null;
    _clientCreatedAt = null;
  }

  // Rate limiting: Wait if necessary to respect API limits
  static Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    
    // Remove timestamps older than the rate limit window
    _requestTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp) > _rateLimitWindow
    );
    
    // If we've hit the limit, wait until the oldest request expires
    if (_requestTimestamps.length >= _maxRequestsPerSecond) {
      final oldestRequest = _requestTimestamps.first;
      final waitTime = _rateLimitWindow - now.difference(oldestRequest);
      
      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime + const Duration(milliseconds: 100));
      }
      
      // Clean up again after waiting
      _requestTimestamps.removeWhere(
        (timestamp) => DateTime.now().difference(timestamp) > _rateLimitWindow
      );
    }
    
    // Record this request
    _requestTimestamps.add(DateTime.now());
  }

  static Future<List<Manga>> searchManga(String query) async {
    await _waitForRateLimit();
    
    try {
      final uri = Uri.parse('$baseUrl/manga?title=$query&limit=20&includes[]=cover_art');
      
      final response = await _getClient()
          .get(uri, headers: _headers)
          .timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((mangaData) => Manga.fromJson(mangaData))
            .toList();
      } else if (response.statusCode == 403 || response.statusCode == 451) {
        throw Exception(
          'Access to MangaDex is restricted in your region. Please try using a VPN.',
        );
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search manga. Please try again later.');
      }
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      throw Exception(
          'Unable to connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      print('HTTP Exception: $e');
      throw Exception('Unable to reach MangaDex. Please try again later.');
    } on http.ClientException catch (e) {
      print('Client Exception: $e');
      throw Exception('Connection error. Please try again.');
    } on FormatException catch (e) {
      print('Format Exception: $e');
      throw Exception('Invalid response from server. Please try again later.');
    } on TimeoutException catch (e) {
      print('Timeout Exception: $e');
      throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    } 
  }

  static Future<Manga> getMangaDetails(String mangaId) async {
    await _waitForRateLimit();
    
    try {
      final response = await _getClient().get(
        Uri.parse(
            '$baseUrl/manga/$mangaId?includes[]=cover_art&includes[]=author&includes[]=artist'),
        headers: _headers,
      ).timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Manga.fromJson(data['data']);
      } else {
        throw Exception('Failed to fetch manga details');
      }
    } on http.ClientException catch (e) {
      print('Client Exception in getMangaDetails: $e');
      resetClient();
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      throw Exception('Error fetching manga details: $e');
    } 
  }

  static Future<List<Chapter>> getChapters(
    String mangaId, {
    List<String>? translatedLanguages,
  }) async {
    await _waitForRateLimit();
    
    try {
      final languagesQuery = translatedLanguages
              ?.map((l) => 'translatedLanguage[]=$l')
              .join('&') ??
          'translatedLanguage[]=en';

      final response = await _getClient().get(
        Uri.parse(
            '$baseUrl/manga/$mangaId/feed?limit=500&order[chapter]=asc&$languagesQuery&includes[]=scanlation_group'),
        headers: _headers,
      ).timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Chapter> chapters = (data['data'] as List)
            .where((chapter) =>
                chapter['attributes']['pages'] >
                    0 && // Only chapters with pages
                chapter['attributes']['externalUrl'] ==
                    null && // No external chapters
                chapter['attributes']['publishAt'] !=
                    null) // Only published chapters
            .map((chapterData) => Chapter.fromJson(chapterData))
            .toList();

        // Sort chapters by number
        chapters.sort((a, b) {
          final aNum = double.tryParse(a.chapter ?? '0') ?? 0;
          final bNum = double.tryParse(b.chapter ?? '0') ?? 0;
          return aNum.compareTo(bNum);
        });

        // Set previous and next chapter IDs
        for (int i = 0; i < chapters.length; i++) {
          final chapter = chapters[i];
          if (i > 0) {
            chapter.prevChapterId = chapters[i - 1].id;
          }
          if (i < chapters.length - 1) {
            chapter.nextChapterId = chapters[i + 1].id;
          }
        }

        return chapters;
      } else if (response.statusCode == 403 || response.statusCode == 451) {
        throw Exception(
          'Access to MangaDex is restricted in your region. Please try using a VPN.',
        );
      } else {
        print('Failed to fetch chapters: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
          'Failed to fetch chapters (${response.statusCode}). Please check your connection or try using a VPN.',
        );
      }
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      throw Exception(
        'Unable to connect to MangaDex. Please check your internet connection or try using a VPN.',
      );
    } on http.ClientException catch (e) {
      print('Client Exception in getChapters: $e');
      resetClient();
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      print('Error fetching chapters: $e');
      throw Exception(e.toString());
    } 
  }

  static Future<Chapter?> getChapter(String chapterId) async {
    
    try {
      final response = await _getClient().get(
        Uri.parse('$baseUrl/chapter/$chapterId?includes[]=scanlation_group'),
        headers: _headers,
      ).timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Chapter.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching chapter: $e');
      return null;
    } 
  }

  static Future<List<String>> getChapterPages(String chapterId) async {
    await _waitForRateLimit();
    
    try {
      final response = await _getClient().get(
        Uri.parse('$baseUrl/at-home/server/$chapterId'),
        headers: _headers,
      ).timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hash = data['chapter']['hash'];
        final images = List<String>.from(data['chapter']['data']);

        return images.map((image) {
          final url = 'https://uploads.mangadex.org/data/$hash/$image';
          final etag = response.headers['etag'] ?? DateTime.now().toString();
          // Store URL and ETag mapping
          _imageEtags[url] = etag;
          return url;
        }).toList();
      }
      throw Exception('Failed to load chapter pages');
    } on http.ClientException catch (e) {
      print('Client Exception in getChapterPages: $e');
      resetClient();
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      print('Error getting chapter pages: $e');
      throw Exception('Error loading chapter. Please try again later.');
    } 
  }

  static String? getImageEtag(String url) {
    return _imageEtags[url];
  }

  static Future<List<Manga>> getTopManga() async {
    return _getMangaList('top');
  }

  static Future<List<Manga>> getTrendingManga() async {
    return _getMangaList('trending');
  }

  static Future<List<Manga>> getLatestManga() async {
    return _getMangaList('latest');
  }

  static Future<List<Manga>> getPopularManga() async {
    return _getMangaList('popular');
  }

  static Future<List<Manga>> _getMangaList(String type) async {
    await _waitForRateLimit();
    
    try {
      String orderQuery;
      switch (type) {
        case 'top':
          orderQuery = 'order[rating]=desc';
          break;
        case 'trending':
          orderQuery = 'order[followedCount]=desc';
          break;
        case 'latest':
          orderQuery = 'order[latestUploadedChapter]=desc';
          break;
        case 'popular':
          orderQuery = 'order[followedCount]=desc';
          break;
        default:
          orderQuery = '';
      }

      final response = await _getClient().get(
        Uri.parse('$baseUrl/manga?limit=20&includes[]=cover_art&$orderQuery'),
        headers: _headers,
      ).timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((mangaData) => Manga.fromJson(mangaData))
            .toList();
      }
      throw Exception('Failed to load manga list');
    } on http.ClientException catch (e) {
      print('Client Exception fetching $type manga: $e');
      resetClient();
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      print('Error fetching $type manga: $e');
      throw Exception('Failed to load manga list');
    }
  }
}


