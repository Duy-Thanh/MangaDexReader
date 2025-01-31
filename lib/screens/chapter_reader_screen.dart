import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chapter.dart';
import '../services/mangadex_service.dart';
import '../widgets/manga_image.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../providers/bookmark_provider.dart';
import '../models/bookmark.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import '../services/image_cache_service.dart';

class PreviousChapterIntent extends Intent {
  const PreviousChapterIntent();
}

class NextChapterIntent extends Intent {
  const NextChapterIntent();
}

class PreviousPageIntent extends Intent {
  const PreviousPageIntent();
}

class NextPageIntent extends Intent {
  const NextPageIntent();
}

class ChapterReaderScreen extends StatefulWidget {
  final Chapter chapter;
  final String mangaId;

  const ChapterReaderScreen({
    super.key,
    required this.chapter,
    required this.mangaId,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late Future<List<String>> _pagesFuture;
  final PageController _pageController = PageController();
  int _currentPage = 1;
  bool _showControls = true;
  bool _isLoadingNewChapter = false;
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;
  List<String>? _pages;
  bool _isLoading = false;

  final Map<ShortcutActivator, Intent> _shortcuts = {
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousChapterIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextChapterIntent(),
    LogicalKeySet(LogicalKeyboardKey.audioVolumeUp): const PreviousPageIntent(),
    LogicalKeySet(LogicalKeyboardKey.audioVolumeDown): const NextPageIntent(),
  };

  @override
  void initState() {
    super.initState();
    _pagesFuture = _loadPages();
    _loadChapterPages();
  }

  Future<List<String>> _loadPages() async {
    try {
      final pages = await MangaDexService.getChapterPages(widget.chapter.id);
      if (pages.isEmpty) {
        throw Exception('No pages found for this chapter');
      }
      return pages;
    } catch (e) {
      print('Error loading pages: $e');
      throw Exception('Failed to load chapter: ${e.toString()}');
    }
  }

  Future<void> _loadChapterPages() async {
    try {
      setState(() => _isLoading = true);

      final pages = await MangaDexService.getChapterPages(widget.chapter.id);
      ImageCacheService.cacheChapterUrls(widget.chapter.id, pages);

      // Check both system and app data saving settings
      final shouldLimit = await ImageCacheService.shouldLimitDataUsage(context);

      // Only preload if data saving is not enabled
      if (!shouldLimit) {
        _preloadImages(pages);

        if (widget.chapter.nextChapterId != null) {
          _preloadNextChapter();
        }
      }

      setState(() {
        _pages = pages;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chapter: $e');
    }
  }

  Future<void> _preloadImages(List<String> pages) async {
    await ImageCacheService.preloadChapterImages(
      widget.chapter.id,
      pages,
      context,
    );
  }

  Future<void> _preloadNextChapter() async {
    try {
      final nextChapter =
          await MangaDexService.getChapter(widget.chapter.nextChapterId!);
      if (nextChapter != null) {
        final nextPages = await MangaDexService.getChapterPages(nextChapter.id);
        ImageCacheService.cacheChapterUrls(nextChapter.id, nextPages);
        await ImageCacheService.preloadChapterImages(
          nextChapter.id,
          nextPages.take(3).toList(),
          context,
        );
      }
    } catch (e) {
      print('Error preloading next chapter: $e');
    }
  }

  Future<void> _navigateToChapter(String? chapterId) async {
    if (chapterId == null || _isLoadingNewChapter) return;

    setState(() {
      _isLoadingNewChapter = true;
    });

    try {
      // Get all chapters first
      final chapters = await MangaDexService.getChapters(
        widget.mangaId,
        translatedLanguages:
            context.read<SettingsProvider>().enabledLanguageCodes,
      );

      // Sort chapters by number
      chapters.sort((a, b) {
        final aNum = double.tryParse(a.chapter ?? '0') ?? 0;
        final bNum = double.tryParse(b.chapter ?? '0') ?? 0;
        return aNum.compareTo(bNum);
      });

      // Find the target chapter
      final targetChapter = chapters.firstWhere(
        (c) => c.id == chapterId,
        orElse: () => throw Exception('Chapter not found'),
      );

      // Update navigation links
      final currentIndex = chapters.indexWhere((c) => c.id == chapterId);
      if (currentIndex != -1) {
        targetChapter.prevChapterId =
            currentIndex > 0 ? chapters[currentIndex - 1].id : null;
        targetChapter.nextChapterId = currentIndex < chapters.length - 1
            ? chapters[currentIndex + 1].id
            : null;
      }

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterReaderScreen(
              chapter: targetChapter,
              mangaId: widget.mangaId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNewChapter = false;
        });
      }
    }
  }

  void _handleDoubleTap() {
    if (_transformationController.value.getMaxScaleOnAxis() > 1.0) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Platform.isIOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
          const SizedBox(height: 16),
          const Text(
            'Loading chapter...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: {
          PreviousChapterIntent: CallbackAction<PreviousChapterIntent>(
            onInvoke: (intent) {
              if (!_isLoadingNewChapter &&
                  widget.chapter.prevChapterId != null) {
                _navigateToChapter(widget.chapter.prevChapterId);
              }
              return null;
            },
          ),
          NextChapterIntent: CallbackAction<NextChapterIntent>(
            onInvoke: (intent) {
              if (!_isLoadingNewChapter &&
                  widget.chapter.nextChapterId != null) {
                _navigateToChapter(widget.chapter.nextChapterId);
              }
              return null;
            },
          ),
          PreviousPageIntent: CallbackAction<PreviousPageIntent>(
            onInvoke: (intent) {
              if (_currentPage > 1) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              return null;
            },
          ),
          NextPageIntent: CallbackAction<NextPageIntent>(
            onInvoke: (intent) {
              if (_pages != null && _currentPage < _pages!.length) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: context.watch<SettingsProvider>().brightnessMode ==
                  BrightnessMode.DARK
              ? Colors.black
              : context.watch<SettingsProvider>().brightnessMode ==
                      BrightnessMode.LIGHT
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
          body: GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Stack(
              children: [
                // Main content
                FutureBuilder<List<String>>(
                  future: _pagesFuture,
                  builder: (context, snapshot) {
                    if (_isLoadingNewChapter ||
                        snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.red.withOpacity(0.8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                snapshot.error.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _pagesFuture = _loadPages();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final pages = snapshot.data!;
                    return Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          reverse: context
                                  .watch<SettingsProvider>()
                                  .readingDirection ==
                              ReadingDirection.RTL,
                          physics: _transformationController.value
                                      .getMaxScaleOnAxis() >
                                  1.0
                              ? const NeverScrollableScrollPhysics()
                              : const PageScrollPhysics(),
                          itemCount: pages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index + 1;
                            });
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onDoubleTap: _handleDoubleTap,
                              child: InteractiveViewer(
                                transformationController:
                                    _transformationController,
                                minScale: 1.0,
                                maxScale: 3.0,
                                panEnabled: true,
                                scaleEnabled: true,
                                boundaryMargin: EdgeInsets.zero,
                                constrained: true,
                                clipBehavior: Clip.none,
                                onInteractionUpdate: (details) {
                                  setState(() {
                                    _isZoomed = _transformationController.value
                                            .getMaxScaleOnAxis() >
                                        1.0;
                                  });
                                },
                                child: Center(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width,
                                      maxHeight:
                                          MediaQuery.of(context).size.height,
                                    ),
                                    child: Image(
                                      image: ImageCacheService.getCachedImage(
                                              widget.chapter.id,
                                              pages[index]) ??
                                          NetworkImage(
                                            pages[index],
                                            headers: {
                                              'User-Agent':
                                                  'MangaDexReader/1.0.0 (Flutter App)',
                                              'Accept': 'image/*',
                                              'Referer':
                                                  'https://mangadex.org/',
                                            },
                                          ),
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Page indicator
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Page $_currentPage of ${pages.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Controls overlay
                        if (_showControls) ...[
                          // Top bar
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              child: AppBar(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chapter ${widget.chapter.chapter ?? 'N/A'}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    if (widget.chapter.scanlationGroup != null)
                                      Text(
                                        'Scanlated by ${widget.chapter.scanlationGroup!}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                leading: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: Colors.white,
                                  onPressed: () => Navigator.pop(context),
                                ),
                                actions: [
                                  IconButton(
                                    icon: Icon(
                                      context
                                                  .watch<SettingsProvider>()
                                                  .readingDirection ==
                                              ReadingDirection.LTR
                                          ? Icons.format_textdirection_l_to_r
                                          : Icons.format_textdirection_r_to_l,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      context
                                          .read<SettingsProvider>()
                                          .toggleReadingDirection();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      context
                                                  .watch<SettingsProvider>()
                                                  .brightnessMode ==
                                              BrightnessMode.LIGHT
                                          ? Icons.brightness_7
                                          : context
                                                      .watch<SettingsProvider>()
                                                      .brightnessMode ==
                                                  BrightnessMode.DARK
                                              ? Icons.brightness_4
                                              : Icons.brightness_auto,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      context
                                          .read<SettingsProvider>()
                                          .toggleBrightnessMode();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom controls
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.black54,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous),
                                    color: widget.chapter.prevChapterId != null
                                        ? Colors.white
                                        : Colors.grey,
                                    onPressed:
                                        widget.chapter.prevChapterId != null
                                            ? () => _navigateToChapter(
                                                widget.chapter.prevChapterId)
                                            : null,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white24,
                                          thumbColor: Colors.white,
                                          overlayColor:
                                              Colors.white.withOpacity(0.3),
                                        ),
                                        child: Slider(
                                          value: _currentPage.toDouble(),
                                          min: 1,
                                          max: pages.length.toDouble(),
                                          divisions: pages.length - 1,
                                          label: 'Page $_currentPage',
                                          onChanged: (value) {
                                            _pageController
                                                .jumpToPage(value.toInt() - 1);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next),
                                    color: widget.chapter.nextChapterId != null
                                        ? Colors.white
                                        : Colors.grey,
                                    onPressed:
                                        widget.chapter.nextChapterId != null
                                            ? () => _navigateToChapter(
                                                widget.chapter.nextChapterId)
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
