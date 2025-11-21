import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/mangadex_service.dart';
import '../screens/settings_screen.dart';
import 'bookmarks_screen.dart';
import '../widgets/manga_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _tabs = ['Top', 'Trending', 'Latest', 'Popular'];
  int _selectedIndex = 0;

  // Cache futures to prevent re-fetching on tab switch
  late Future<List<Manga>> _topMangaFuture;
  late Future<List<Manga>> _trendingMangaFuture;
  late Future<List<Manga>> _latestMangaFuture;
  late Future<List<Manga>> _popularMangaFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Add listener to rebuild when tab changes
    _tabController!.addListener(() {
      setState(() {});
    });
    
    // Initialize futures once - they will be cached
    _topMangaFuture = MangaDexService.getTopManga();
    _trendingMangaFuture = MangaDexService.getTrendingManga();
    _latestMangaFuture = MangaDexService.getLatestManga();
    _popularMangaFuture = MangaDexService.getPopularManga();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Refresh all manga lists
  void _refreshMangaLists() {
    setState(() {
      _topMangaFuture = MangaDexService.getTopManga();
      _trendingMangaFuture = MangaDexService.getTrendingManga();
      _latestMangaFuture = MangaDexService.getLatestManga();
      _popularMangaFuture = MangaDexService.getPopularManga();
    });
  }

  Widget _buildCurrentView() {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (_selectedIndex) {
      case 0:
        // Home view with manga tabs - return the widget directly for SliverFillRemaining
        return Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surfaceContainerHighest.withOpacity(0.95),
                    colorScheme.surfaceContainer.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 6),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AnimatedBuilder(
                  animation: _tabController!,
                  builder: (context, _) {
                    return Row(
                      children: _tabs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tab = entry.value;
                        final isSelected = _tabController!.index == index;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _tabController!.animateTo(index);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.primary.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -2,
                                ),
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ] : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                Text(
                                  tab,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 15,
                                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant.withOpacity(0.8),
                                    letterSpacing: isSelected ? 0.5 : 0.3,
                                    shadows: isSelected ? [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ] : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController!,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Top Manga Tab
                  RefreshIndicator(
                    onRefresh: () async {
                      _refreshMangaLists();
                      await _topMangaFuture;
                    },
                    child: _buildMangaList(_topMangaFuture),
                  ),
                  // Trending Manga Tab
                  RefreshIndicator(
                    onRefresh: () async {
                      _refreshMangaLists();
                      await _trendingMangaFuture;
                    },
                    child: _buildMangaList(_trendingMangaFuture),
                  ),
                  // Latest Updates Tab
                  RefreshIndicator(
                    onRefresh: () async {
                      _refreshMangaLists();
                      await _latestMangaFuture;
                    },
                    child: _buildMangaList(_latestMangaFuture),
                  ),
                  // Popular Manga Tab
                  RefreshIndicator(
                    onRefresh: () async {
                      _refreshMangaLists();
                      await _popularMangaFuture;
                    },
                    child: _buildMangaList(_popularMangaFuture),
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
        // Bookmarks view
        return const BookmarksScreen();
      case 2:
        // Settings view
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMangaList(Future<List<Manga>> future) {
    return FutureBuilder<List<Manga>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (snapshot.hasData) {
          return MangaGrid(mangas: snapshot.data!);
        }
        return _buildShimmerLoading();
      },
    );
  }

  Widget _buildShimmerLoading() {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + (value * 2), -1.0),
                    end: Alignment(1.0 + (value * 2), 1.0),
                    colors: [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.errorContainer.withOpacity(0.4),
                    colorScheme.errorContainer.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.error.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.error.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 72,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.contains('Connection') ? 'Check your internet connection' : 'Please try again later',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _refreshMangaLists();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get title based on selected index
    String appBarTitle;
    String appBarSubtitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Discover';
        appBarSubtitle = 'Explore thousands of manga';
        break;
      case 1:
        appBarTitle = 'My Library';
        appBarSubtitle = 'Your bookmarked manga';
        break;
      case 2:
        appBarTitle = 'Settings';
        appBarSubtitle = 'Customize your experience';
        break;
      default:
        appBarTitle = 'MangaReader';
        appBarSubtitle = '';
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.3),
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appBarTitle,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (appBarSubtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      appBarSubtitle,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_selectedIndex == 0)
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.search_rounded,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/search');
                                  },
                                  tooltip: 'Search manga',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _buildCurrentView(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.explore_outlined,
                  selectedIcon: Icons.explore_rounded,
                  label: 'Home',
                  index: 0,
                  color: colorScheme.primary,
                ),
                _buildNavItem(
                  icon: Icons.bookmark_border_rounded,
                  selectedIcon: Icons.bookmark_rounded,
                  label: 'Library',
                  index: 1,
                  color: colorScheme.secondary,
                ),
                _buildNavItem(
                  icon: Icons.tune_rounded,
                  selectedIcon: Icons.tune_rounded,
                  label: 'Settings',
                  index: 2,
                  color: colorScheme.tertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required Color color,
  }) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? color : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : colorScheme.onSurfaceVariant,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this widget to display manga in a grid
class MangaGrid extends StatelessWidget {
  final List<Manga> mangas;

  const MangaGrid({super.key, required this.mangas});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: mangas.length,
      itemBuilder: (context, index) {
        final manga = mangas[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 60)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: MangaCard(
                    manga: manga,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/manga',
                        arguments: manga,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}