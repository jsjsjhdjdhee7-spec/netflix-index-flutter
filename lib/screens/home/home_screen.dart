import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/content_provider.dart';
import '../../widgets/netflix_logo.dart';

import '../../widgets/content_row.dart';
import '../../widgets/featured_content.dart';
import '../../widgets/hero_video_player.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../tv_shows/tv_shows_screen.dart';
import '../content/see_all_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadContent();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    
    final language = authProvider.language;
    await contentProvider.loadAllContent(language: language);
    
    if (authProvider.user != null) {
      await contentProvider.loadUserData(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.netflixBlack,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomePage(),
          const TvShowsScreen(),
          const SearchScreen(),
          _buildMyListPage(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(localizations),
    );
  }

  Widget _buildHomePage() {
    final localizations = AppLocalizations.of(context)!;
    
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Hero Video Player
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  if (contentProvider.featuredMovies.isNotEmpty) {
                    return HeroVideoPlayer(
                      content: contentProvider.featuredMovies.first.toJson(),
                      contentType: 'movie',
                    );
                  }
                  return const FeaturedContent();
                },
              ),
              
              const SizedBox(height: 20),
              
              // Continue Watching
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  if (contentProvider.continueWatching.isNotEmpty) {
                    return ContentRow(
                      title: localizations.continueWatching,
                      items: contentProvider.continueWatching
                          .map((history) => {
                                'id': history.contentId,
                                'title': history.title,
                                'poster_path': history.posterPath,
                                'type': history.contentType,
                              })
                          .toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Popular Movies
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  return _buildContentRowWithSeeAll(
                    title: localizations.popularMovies,
                    items: contentProvider.popularMovies
                        .map((movie) => movie.toJson()..['type'] = 'movie')
                        .toList(),
                    onSeeAllTap: () => _navigateToSeeAll(
                      localizations.popularMovies,
                      'movie',
                      'popular',
                    ),
                  );
                },
              ),
              
              // Trending Movies
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  return _buildContentRowWithSeeAll(
                    title: localizations.trendingMovies,
                    items: contentProvider.trendingMovies
                        .map((movie) => movie.toJson()..['type'] = 'movie')
                        .toList(),
                    onSeeAllTap: () => _navigateToSeeAll(
                      localizations.trendingMovies,
                      'movie',
                      'trending',
                    ),
                  );
                },
              ),
              
              // Popular TV Shows
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  return _buildContentRowWithSeeAll(
                    title: localizations.popularTvShows,
                    items: contentProvider.popularTvShows
                        .map((show) => show.toJson()..['type'] = 'tv')
                        .toList(),
                    onSeeAllTap: () => _navigateToSeeAll(
                      localizations.popularTvShows,
                      'tv',
                      'popular',
                    ),
                  );
                },
              ),
              
              // Top Rated Movies
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  return _buildContentRowWithSeeAll(
                    title: localizations.topRatedMovies,
                    items: contentProvider.topRatedMovies
                        .map((movie) => movie.toJson()..['type'] = 'movie')
                        .toList(),
                    onSeeAllTap: () => _navigateToSeeAll(
                      localizations.topRatedMovies,
                      'movie',
                      'top_rated',
                    ),
                  );
                },
              ),
              
              // Trending TV Shows
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  return _buildContentRowWithSeeAll(
                    title: localizations.trendingTvShows,
                    items: contentProvider.trendingTvShows
                        .map((show) => show.toJson()..['type'] = 'tv')
                        .toList(),
                    onSeeAllTap: () => _navigateToSeeAll(
                      localizations.trendingTvShows,
                      'tv',
                      'trending',
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyListPage() {
    final localizations = AppLocalizations.of(context)!;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.netflixBlack,
          title: Text(
            localizations.myList,
            style: const TextStyle(
              color: AppColors.netflixWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          floating: true,
          snap: true,
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Favorites
              Consumer<ContentProvider>(
                builder: (context, contentProvider, child) {
                  if (contentProvider.favoriteMovies.isEmpty && 
                      contentProvider.favoriteTvShows.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: AppColors.netflixGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.noResults,
                              style: const TextStyle(
                                color: AppColors.netflixGray,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: [
                      if (contentProvider.favoriteMovies.isNotEmpty)
                        ContentRow(
                          title: '${localizations.favorites} - ${localizations.popularMovies}',
                          items: contentProvider.favoriteMovies
                              .map((id) => {
                                    'id': id,
                                    'type': 'movie',
                                  })
                              .toList(),
                        ),
                      if (contentProvider.favoriteTvShows.isNotEmpty)
                        ContentRow(
                          title: '${localizations.favorites} - ${localizations.popularTvShows}',
                          items: contentProvider.favoriteTvShows
                              .map((id) => {
                                    'id': id,
                                    'type': 'tv',
                                  })
                              .toList(),
                        ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.netflixBlack,
      expandedHeight: 80,
      floating: true,
      snap: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const NetflixLogo(size: 40),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Search functionality
                  setState(() {
                    _selectedIndex = 1;
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                icon: const Icon(
                  Icons.search,
                  color: AppColors.netflixWhite,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(AppLocalizations localizations) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.netflixDarkGray,
      selectedItemColor: AppColors.netflixRed,
      unselectedItemColor: AppColors.netflixGray,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: localizations.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.tv),
          label: 'TV Shows',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          label: localizations.search,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite),
          label: localizations.myList,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: localizations.profile,
        ),
      ],
    );
  }

  Widget _buildContentRowWithSeeAll({
    required String title,
    required List<Map<String, dynamic>> items,
    required VoidCallback onSeeAllTap,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.netflixWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: const TextStyle(
                        color: AppColors.netflixRed,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.netflixRed,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ContentRow(title: '', items: items),
      ],
    );
  }

  void _navigateToSeeAll(String title, String contentType, String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SeeAllScreen(
          title: title,
          contentType: contentType,
          category: category,
        ),
      ),
    );
  }
}