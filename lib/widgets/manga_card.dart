import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../widgets/manga_image.dart';

class MangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onTap;

  const MangaCard({
    super.key,
    required this.manga,
    required this.onTap,
  });

  String _truncateTag(String tag) {
    const maxLength = 12;
    if (tag.length <= maxLength) return tag;
    return '${tag.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'manga_${manga.id}',
              child: manga.coverUrl != null
                  ? MangaImage(
                      imageUrl: manga.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 50),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (manga.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final tag in manga.tags.take(2))
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _truncateTag(tag),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
