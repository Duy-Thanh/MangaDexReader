import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../widgets/manga_image.dart';

class MangaCard extends StatefulWidget {
  final Manga manga;
  final VoidCallback onTap;

  const MangaCard({
    super.key,
    required this.manga,
    required this.onTap,
  });

  @override
  State<MangaCard> createState() => _MangaCardState();
}

class _MangaCardState extends State<MangaCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _truncateTag(String tag) {
    const maxLength = 12;
    if (tag.length <= maxLength) return tag;
    return '${tag.substring(0, maxLength)}...';
  }

  Color _getTagColor(String tag, ColorScheme colorScheme) {
    final lowerTag = tag.toLowerCase();
    
    // Generate a bright color based on tag name if no match
    if (lowerTag.contains('action')) {
      return const Color(0xFFFF5252); // Bright red
    } else if (lowerTag.contains('adventure')) {
      return const Color(0xFFFF9800); // Orange
    } else if (lowerTag.contains('romance')) {
      return const Color(0xFFE91E63); // Pink
    } else if (lowerTag.contains('drama')) {
      return const Color(0xFFAB47BC); // Purple
    } else if (lowerTag.contains('comedy')) {
      return const Color(0xFF66BB6A); // Green
    } else if (lowerTag.contains('gore')) {
      return const Color(0xFFEF5350); // Bright red
    } else if (lowerTag.contains('horror')) {
      return const Color(0xFF9C27B0); // Bright purple
    } else if (lowerTag.contains('thriller')) {
      return const Color(0xFF78909C); // Bright gray-blue
    } else if (lowerTag.contains('award') || lowerTag.contains('winning')) {
      return const Color(0xFFFFC107); // Amber/Gold
    } else if (lowerTag.contains('fantasy')) {
      return const Color(0xFF29B6F6); // Light blue
    } else if (lowerTag.contains('monster')) {
      return const Color(0xFF66BB6A); // Green
    } else if (lowerTag.contains('slice')) {
      return const Color(0xFF26C6DA); // Cyan
    } else if (lowerTag.contains('supernatural')) {
      return const Color(0xFF7E57C2); // Deep purple
    } else if (lowerTag.contains('mystery')) {
      return const Color(0xFF5C6BC0); // Indigo
    } else if (lowerTag.contains('sci') || lowerTag.contains('science')) {
      return const Color(0xFF26A69A); // Teal
    } else if (lowerTag.contains('historical')) {
      return const Color(0xFFFF7043); // Deep orange
    } else {
      // Generate a bright color from the tag string
      final hash = tag.hashCode.abs();
      final colors = [
        const Color(0xFF42A5F5), // Blue
        const Color(0xFFEC407A), // Pink
        const Color(0xFF66BB6A), // Green
        const Color(0xFFFFCA28), // Amber
        const Color(0xFFAB47BC), // Purple
        const Color(0xFFFF7043), // Deep orange
        const Color(0xFF26C6DA), // Cyan
        const Color(0xFF5C6BC0), // Indigo
      ];
      return colors[hash % colors.length];
    }
  }

  Color _getTagTextColor(String tag, ColorScheme colorScheme) {
    return Colors.white; // Always use white text for maximum visibility
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainer,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'manga_${widget.manga.id}',
                          child: widget.manga.coverUrl != null
                              ? MangaImage(
                                  imageUrl: widget.manga.coverUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colorScheme.primaryContainer.withOpacity(0.3),
                                        colorScheme.tertiaryContainer.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.auto_stories_rounded,
                                    size: 56,
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                                  ),
                                ),
                        ),
                        // Gradient overlay for better text readability
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.95),
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.manga.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.manga.tags.isNotEmpty) ...[
                            const Spacer(),
                            SizedBox(
                              height: 24,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ...widget.manga.tags.take(2).map((tag) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getTagColor(tag, colorScheme),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _getTagTextColor(tag, colorScheme).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _truncateTag(tag),
                                          style: TextStyle(
                                            color: _getTagTextColor(tag, colorScheme),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  if (widget.manga.tags.length > 2)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+${widget.manga.tags.length - 2}',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
