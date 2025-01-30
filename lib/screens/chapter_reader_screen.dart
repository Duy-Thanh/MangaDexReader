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

  @override
  void initState() {
    super.initState();
    _pagesFuture = _loadPages();
  }

  Future<List<String>> _loadPages() async {
    try {
      return await MangaDexService.getChapterPages(widget.chapter.id);
    } catch (e) {
      print('Error loading pages: $e');
      rethrow;
    }
  }

  Future<void> _navigateToChapter(String? chapterId) async {
    if (chapterId == null || _isLoadingNewChapter) return;

    setState(() {
      _isLoadingNewChapter = true;
    });

    try {
      // Get the next/prev chapter with its navigation links
      final chapters = await MangaDexService.getChapters(widget.mangaId);
      final currentChapterIndex = chapters.indexWhere((c) => c.id == chapterId);

      if (currentChapterIndex != -1 && mounted) {
        final nextChapter = chapters[currentChapterIndex];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterReaderScreen(
              chapter: nextChapter,
              mangaId: widget.mangaId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chapter: $e'),
            backgroundColor: Colors.red,
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Loading chapter...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleDoubleTap() {
    if (_transformationController.value.getMaxScaleOnAxis() > 1.0) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (widget.chapter.prevChapterId != null) {
              _navigateToChapter(widget.chapter.prevChapterId);
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (widget.chapter.nextChapterId != null) {
              _navigateToChapter(widget.chapter.nextChapterId);
            }
          } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
            if (_currentPage > 1) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
            final pages = context.read<SettingsProvider>().readingDirection;
            if (_currentPage < pages.length) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.watch<SettingsProvider>().brightnessMode ==
                BrightnessMode.dark
            ? Colors.black
            : context.watch<SettingsProvider>().brightnessMode ==
                    BrightnessMode.light
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Platform.isIOS
                              ? const CupertinoActivityIndicator()
                              : const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading chapter...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _pagesFuture = _loadPages();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
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
                            ReadingDirection.rtl,
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
                                    maxWidth: MediaQuery.of(context).size.width,
                                    maxHeight:
                                        MediaQuery.of(context).size.height,
                                  ),
                                  child: MangaImage(
                                    imageUrl: pages[index],
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image,
                                              size: 48, color: Colors.red),
                                          SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
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
                            child: SafeArea(
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
                                              ReadingDirection.ltr
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
                                              BrightnessMode.light
                                          ? Icons.brightness_7
                                          : context
                                                      .watch<SettingsProvider>()
                                                      .brightnessMode ==
                                                  BrightnessMode.dark
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
                        ),

                        // Bottom controls
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.black54,
                            child: SafeArea(
                              top: false,
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
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
}
