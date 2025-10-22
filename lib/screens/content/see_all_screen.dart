import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/content_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tmdb_service.dart';
import '../../widgets/content_grid.dart';

class SeeAllScreen extends StatefulWidget {
  final String title;
  final String contentType; // 'movie' or 'tv'
  final String category; // 'popular', 'trending', 'top_rated', etc.

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.contentType,
    required this.category,
  });

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _content = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreContent();
      }
    }
  }

  Future<void> _loadContent() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final language = authProvider.language;

      List<dynamic> results = [];

      if (widget.contentType == 'movie') {
        switch (widget.category) {
          case 'popular':
            final movies = await TMDBService.getPopularMovies(language: language, page: _currentPage);
            results = movies.map((m) => m.toJson()..['type'] = 'movie').toList();
            break;
          case 'trending':
            final movies = await TMDBService.getTrendingMovies(language: language);
            results = movies.map((m) => m.toJson()..['type'] = 'movie').toList();
            break;
          case 'top_rated':
            final movies = await TMDBService.getTopRatedMovies(language: language, page: _currentPage);
            results = movies.map((m) => m.toJson()..['type'] = 'movie').toList();
            break;
          case 'now_playing':
            final movies = await TMDBService.getNowPlayingMovies(language: language, page: _currentPage);
            results = movies.map((m) => m.toJson()..['type'] = 'movie').toList();
            break;
          case 'upcoming':
            final movies = await TMDBService.getUpcomingMovies(language: language, page: _currentPage);
            results = movies.map((m) => m.toJson()..['type'] = 'movie').toList();
            break;
        }
      } else if (widget.contentType == 'tv') {
        switch (widget.category) {
          case 'popular':
            final shows = await TMDBService.getPopularTvShows(language: language, page: _currentPage);
            results = shows.map((s) => s.toJson()..['type'] = 'tv').toList();
            break;
          case 'trending':
            final shows = await TMDBService.getTrendingTvShows(language: language);
            results = shows.map((s) => s.toJson()..['type'] = 'tv').toList();
            break;
          case 'top_rated':
            final shows = await TMDBService.getTopRatedTvShows(language: language, page: _currentPage);
            results = shows.map((s) => s.toJson()..['type'] = 'tv').toList();
            break;
          case 'on_the_air':
            final shows = await TMDBService.getOnTheAirTvShows(language: language, page: _currentPage);
            results = shows.map((s) => s.toJson()..['type'] = 'tv').toList();
            break;
          case 'airing_today':
            final shows = await TMDBService.getAiringTodayTvShows(language: language, page: _currentPage);
            results = shows.map((s) => s.toJson()..['type'] = 'tv').toList();
            break;
        }
      }

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _content = List<Map<String, dynamic>>.from(results);
          } else {
            _content.addAll(List<Map<String, dynamic>>.from(results));
          }
          _hasMore = results.length >= 20; // TMDB typically returns 20 items per page
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreContent() async {
    _currentPage++;
    await _loadContent();
  }

  Future<void> _refreshContent() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.netflixBlack,
      appBar: AppBar(
        backgroundColor: AppColors.netflixBlack,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.netflixWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.netflixWhite,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshContent,
        color: AppColors.netflixRed,
        backgroundColor: AppColors.netflixDarkGray,
        child: _content.isEmpty && _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.netflixRed,
                ),
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: ContentGrid(items: _content),
                  ),
                  if (_isLoading && _content.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.netflixRed,
                          ),
                        ),
                      ),
                    ),
                  if (!_hasMore && _content.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No more content to load',
                            style: TextStyle(
                              color: AppColors.netflixGray,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
      ),
    );
  }
}