import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import 'dart:async';

class MangaDexService {
  static const String baseUrl = 'https://api.mangadex.org';
  static HttpClient? _httpClient;

  // Common headers required by MangaDex API
  static final Map<String, String> _headers = {
    'User-Agent':
        'MangaDexReader/1.0.0 (Open Source Flutter App - github.com/yourusername/mangareader)',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static http.Client _getClient() {
    if (_httpClient == null) {
      _httpClient = HttpClient();
      _httpClient!.findProxy = (uri) {
        // Add your proxy configuration here
        // Example for using system proxy:
        return HttpClient.findProxyFromEnvironment(uri);

        // Or use a specific proxy:
        // return 'PROXY proxy.yourvpn.com:8080';

        // Or for SOCKS proxy:
        // return 'SOCKS5 proxy.yourvpn.com:1080';
      };

      // Optional: Disable certificate verification if needed
      _httpClient!.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    }

    return IOClient(_httpClient!);
  }

  static Future<List<Manga>> searchManga(String query) async {
    try {
      final client = _getClient();
      final response = await client
          .get(
        Uri.parse('$baseUrl/manga?title=$query&limit=20&includes[]=cover_art'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
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
    } on FormatException catch (e) {
      print('Format Exception: $e');
      throw Exception('Invalid response from server. Please try again later.');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  static Future<Manga> getMangaDetails(String mangaId) async {
    try {
      final client = _getClient();
      final response = await client.get(
        Uri.parse(
            '$baseUrl/manga/$mangaId?includes[]=cover_art&includes[]=author&includes[]=artist'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Manga.fromJson(data['data']);
      } else {
        throw Exception('Failed to fetch manga details');
      }
    } catch (e) {
      throw Exception('Error fetching manga details: $e');
    }
  }

  static Future<List<Chapter>> getChapters(
    String mangaId, {
    List<String>? translatedLanguages,
  }) async {
    try {
      final languagesQuery = translatedLanguages
              ?.map((l) => 'translatedLanguage[]=$l')
              .join('&') ??
          'translatedLanguage[]=en';

      final response = await _getClient().get(
        Uri.parse(
          '$baseUrl/manga/$mangaId/feed?limit=500&order[chapter]=asc&$languagesQuery&includes[]=scanlation_group',
        ),
        headers: _headers,
      );

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
    } catch (e) {
      print('Error fetching chapters: $e');
      throw Exception(e.toString());
    }
  }

  static Future<Chapter?> getChapter(String chapterId) async {
    try {
      final client = _getClient();
      final response = await client.get(
        Uri.parse('$baseUrl/chapter/$chapterId?includes[]=scanlation_group'),
        headers: _headers,
      );

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
    try {
      final client = _getClient();
      final response = await client.get(
        Uri.parse('$baseUrl/at-home/server/$chapterId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final baseUrl = data['baseUrl'];
        final chapter = data['chapter'];
        final hash = chapter['hash'];

        // Try data-saver first, fall back to original quality if not available
        final pages = List<String>.from(chapter['dataSaver']?.isNotEmpty == true
            ? chapter['dataSaver']
            : chapter['data']);

        if (pages.isEmpty) {
          throw Exception('No pages available for this chapter.');
        }

        return pages.map((page) {
          final quality =
              chapter['dataSaver']?.isNotEmpty == true ? 'data-saver' : 'data';
          return '$baseUrl/$quality/$hash/$page';
        }).toList();
      } else {
        final error = json.decode(response.body);
        print('Failed to fetch pages: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 404) {
          throw Exception('Chapter not available or has been removed.');
        }

        throw Exception(
            error['errors']?[0]?['detail'] ?? 'Failed to fetch chapter pages');
      }
    } catch (e) {
      print('Error fetching pages: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error loading chapter. Please try again later.');
    }
  }
}
