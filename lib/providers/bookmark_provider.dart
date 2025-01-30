import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/bookmark.dart';

class BookmarkProvider with ChangeNotifier {
  List<Bookmark> _bookmarks = [];
  final SharedPreferences _prefs;

  BookmarkProvider(this._prefs) {
    _loadBookmarks();
  }

  List<Bookmark> get bookmarks => _bookmarks;

  void _loadBookmarks() {
    final String? bookmarksJson = _prefs.getString('bookmarks');
    if (bookmarksJson != null) {
      final List<dynamic> decoded = json.decode(bookmarksJson);
      _bookmarks = decoded.map((item) => Bookmark.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    // Remove existing bookmark for the same manga if exists
    _bookmarks.removeWhere((b) => b.mangaId == bookmark.mangaId);
    _bookmarks.insert(0, bookmark); // Add new bookmark at the beginning
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmark(String mangaId) async {
    _bookmarks.removeWhere((b) => b.mangaId == mangaId);
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> _saveBookmarks() async {
    final String encoded =
        json.encode(_bookmarks.map((b) => b.toJson()).toList());
    await _prefs.setString('bookmarks', encoded);
  }

  Bookmark? getBookmark(String mangaId) {
    try {
      return _bookmarks.firstWhere((b) => b.mangaId == mangaId);
    } catch (e) {
      return null;
    }
  }
}
