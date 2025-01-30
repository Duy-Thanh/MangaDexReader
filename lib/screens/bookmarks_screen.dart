import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/manga_image.dart';
import 'chapter_reader_screen.dart';
import 'manga_details_screen.dart';
import '../models/manga.dart';
import 'dart:io' show Platform;

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Manga'),
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, child) {
          if (bookmarkProvider.bookmarks.isEmpty) {
            return const Center(
              child: Text('No bookmarked manga yet'),
            );
          }

          return ListView.builder(
            itemCount: bookmarkProvider.bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarkProvider.bookmarks[index];
              return Dismissible(
                key: Key(bookmark.mangaId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                      Platform.isIOS ? CupertinoIcons.delete : Icons.delete,
                      color: Colors.white),
                ),
                onDismissed: (_) {
                  bookmarkProvider.removeBookmark(bookmark.mangaId);
                },
                child: ListTile(
                  leading: bookmark.coverUrl != null
                      ? SizedBox(
                          width: 50,
                          height: 70,
                          child: MangaImage(
                            imageUrl: bookmark.coverUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.book),
                  title: Text(bookmark.title),
                  subtitle: Wrap(
                    spacing: 4,
                    children: bookmark.tags
                        .take(3)
                        .map((tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                  trailing: Text(
                    _formatDate(bookmark.timestamp),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaDetailsScreen(
                          manga: Manga(
                            id: bookmark.mangaId,
                            title: bookmark.title,
                            coverUrl: bookmark.coverUrl,
                            tags: bookmark.tags,
                            status: bookmark.status,
                            description: bookmark.description,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
