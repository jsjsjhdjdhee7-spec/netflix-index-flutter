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
import '../content/see_all_screen.dart';

class TvShowsScreen extends StatefulWidget {
  const TvShowsScreen({super.key});

  @override
  State<TvShowsScreen> createState() => _TvShowsScreenState();
}

class _TvShowsScreenState extends State<TvShowsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTvShowsContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTvShowsContent() async {
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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Hero Video Player for TV Shows
                Consumer<ContentProvider>(
                  builder: (context, contentProvider, child) {
                    if (contentProvider.popularTvShows.isNotEmpty) {
                      return HeroVideoPlayer(
                        content: contentProvider.popularTvShows.first.toJson(),
                        contentType: 'tv',
                      );
                    }
                    return const FeaturedContent(contentType: 'tv');
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Continue Watching TV Shows
                Consumer<ContentProvider>(
                  builder: (context, contentProvider, child) {
                    final tvContinueWatching = contentProvider.continueWatching
                        .where((history) => history.contentType == 'tv')
                        .toList();
                    
                    if (tvContinueWatching.isNotEmpty) {
                      return ContentRow(
                        title: localizations.continueWatching,
                        items: tvContinueWatching
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
                
                // Popular TV Shows
                Consumer<ContentProvider>(
                  builder: (context, contentProvider, child) {
                    return ContentRowWithSeeAll(
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
                
                // Trending TV Shows
                Consumer<ContentProvider>(
                  builder: (context, contentProvider, child) {
                    return ContentRowWithSeeAll(
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
                
                // Top Rated TV Shows
                Consumer<ContentProvider>(
                  builder: (context, contentProvider, child) {
                    return ContentRowWithSeeAll(
                      title: 'Top Rated TV Shows',
                      items: contentProvider.topRatedTvShows
                          .map((show) => show.toJson()..['type'] = 'tv')
                          .toList(),
                      onSeeAllTap: () => _navigateToSeeAll(
                        'Top Rated TV Shows',
                        'tv',
                        'top_rated',
                      ),
                    );
                  },
                ),
                
                // On The Air TV Shows
                Consumer<ContentProvider>(
                  builder: (context, contentProvider, child) {
                    return ContentRowWithSeeAll(
                      title: 'On The Air',
                      items: contentProvider.onTheAirTvShows
                          .map((show) => show.toJson()..['type'] = 'tv')
                          .toList(),
                      onSeeAllTap: () => _navigateToSeeAll(
                        'On The Air',
                        'tv',
                        'on_the_air',
                      ),
                    );
                  },
                ),
                
                // Airing Today TV Shows
                Consumer<ContentProvider>(
                  builder: (context, contentProvider, child) {
                    return ContentRowWithSeeAll(
                      title: 'Airing Today',
                      items: contentProvider.airingTodayTvShows
                          .map((show) => show.toJson()..['type'] = 'tv')
                          .toList(),
                      onSeeAllTap: () => _navigateToSeeAll(
                        'Airing Today',
                        'tv',
                        'airing_today',
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
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
              const SizedBox(width: 16),
              Text(
                'TV Shows',
                style: const TextStyle(
                  color: AppColors.netflixWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Search functionality
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

// Enhanced ContentRow with See All button
class ContentRowWithSeeAll extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final VoidCallback? onSeeAllTap;

  const ContentRowWithSeeAll({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
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
              if (onSeeAllTap != null)
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
}