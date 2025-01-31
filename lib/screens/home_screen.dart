import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/mangadex_service.dart';
import '../screens/manga_details_screen.dart';
import '../widgets/manga_image.dart';
import '../screens/settings_screen.dart';
import 'search_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        // Home view with manga tabs
        return Column(
          children: [
            TabBar(
              controller: _tabController!,
              isScrollable: true,
              tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController!,
                children: [
                  // Top Manga Tab
                  _buildMangaList(MangaDexService.getTopManga()),
                  // Trending Manga Tab
                  _buildMangaList(MangaDexService.getTrendingManga()),
                  // Latest Updates Tab
                  _buildMangaList(MangaDexService.getLatestManga()),
                  // Popular Manga Tab
                  _buildMangaList(MangaDexService.getPopularManga()),
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
        if (snapshot.hasData) {
          return MangaGrid(mangas: snapshot.data!);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get title based on selected index
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'MangaReader';
        break;
      case 1:
        appBarTitle = 'Bookmarked Manga';
        break;
      case 2:
        appBarTitle = 'Settings';
        break;
      default:
        appBarTitle = 'MangaReader';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          // Only show search in home view
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.pushNamed(context, '/search');
              },
            ),
        ],
      ),
      body: _buildCurrentView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: mangas.length,
      itemBuilder: (context, index) {
        final manga = mangas[index];
        return MangaCard(
          manga: manga,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/manga',
              arguments: manga,
            );
          },
        );
      },
    );
  }
}
