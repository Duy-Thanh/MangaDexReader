import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';
import '../models/chapter.dart';
import 'dart:async';

class MangaDexService {
  static const String baseUrl = 'https://api.mangadex.org';
  static final Map<String, String> _imageEtags = {};
  
  // Connection timeout settings
  static const Duration _timeout = Duration(seconds: 30);

  // Common headers required by MangaDex API
  static final Map<String, String> _headers = {
    'User-Agent': 'MangaDexReader/1.0.0',
    'Accept': 'application/json',
  };

  // Create a fresh client for each request to avoid connection reuse issues
  static http.Client _createClient() {
    return http.Client();
  }

  static Future<List<Manga>> searchManga(String query) async {
    final client = _createClient();
    try {
      final uri = Uri.parse('$baseUrl/manga?title=$query&limit=20&includes[]=cover_art');
      
      final response = await client
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
    } finally {
      client.close();
    }
  }

  static Future<Manga> getMangaDetails(String mangaId) async {
    final client = _createClient();
    try {
      final response = await client.get(
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
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      throw Exception('Error fetching manga details: $e');
    } finally {
      client.close();
    }
  }

  static Future<List<Chapter>> getChapters(
    String mangaId, {
    List<String>? translatedLanguages,
  }) async {
    final client = _createClient();
    try {
      final languagesQuery = translatedLanguages
              ?.map((l) => 'translatedLanguage[]=$l')
              .join('&') ??
          'translatedLanguage[]=en';

      final response = await client.get(
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
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      print('Error fetching chapters: $e');
      throw Exception(e.toString());
    } finally {
      client.close();
    }
  }

  static Future<Chapter?> getChapter(String chapterId) async {
    final client = _createClient();
    try {
      final response = await client.get(
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
    } finally {
      client.close();
    }
  }

  static Future<List<String>> getChapterPages(String chapterId) async {
    final client = _createClient();
    try {
      final response = await client.get(
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
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      print('Error getting chapter pages: $e');
      throw Exception('Error loading chapter. Please try again later.');
    } finally {
      client.close();
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
    final client = _createClient();
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

      final response = await client.get(
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
      throw Exception('Connection error. Please try again.');
    } catch (e) {
      print('Error fetching $type manga: $e');
      throw Exception('Failed to load manga list');
    } finally {
      client.close();
    }
  }
}
