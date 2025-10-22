import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/content_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tmdb_service.dart';
import '../../widgets/content_row.dart';
import '../video/video_player_screen.dart';

class ContentDetailsScreen extends StatefulWidget {
  final int contentId;
  final String contentType;
  final String? title;
  final String? posterPath;

  const ContentDetailsScreen({
    super.key,
    required this.contentId,
    required this.contentType,
    this.title,
    this.posterPath,
  });

  @override
  State<ContentDetailsScreen> createState() => _ContentDetailsScreenState();
}

class _ContentDetailsScreenState extends State<ContentDetailsScreen> {
  Map<String, dynamic>? _contentDetails;
  List<Map<String, dynamic>> _cast = [];
  List<Map<String, dynamic>> _similarContent = [];
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadContentDetails();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContentDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final language = authProvider.language;

      // Load content details
      final details = await TMDBService.getContentDetails(
        widget.contentId,
        widget.contentType,
        language: language,
      );

      // Load cast
      final cast = await TMDBService.getContentCredits(
        widget.contentId,
        widget.contentType,
      );

      // Load similar content
      final similar = await TMDBService.getSimilarContent(
        widget.contentId,
        widget.contentType,
        language: language,
      );

      // Load videos (trailers)
      final videos = await TMDBService.getContentVideos(
        widget.contentId,
        widget.contentType,
      );

      if (mounted) {
        setState(() {
          _contentDetails = details;
          _cast = cast;
          _similarContent = similar;
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading content details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final isFavorite = widget.contentType == 'movie'
        ? contentProvider.favoriteMovies.contains(widget.contentId)
        : contentProvider.favoriteTvShows.contains(widget.contentId);
    
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user?.isGuest == true) {
      _showGuestDialog();
      return;
    }

    try {
      if (_isFavorite) {
        await contentProvider.removeFromFavorites(widget.contentId, widget.contentType);
      } else {
        await contentProvider.addToFavorites(widget.contentId, widget.contentType);
      }
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _showGuestDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.netflixDarkGray,
        title: Text(
          'Sign In Required',
          style: const TextStyle(color: AppColors.netflixWhite),
        ),
        content: Text(
          'Please sign in to add to favorites',
          style: const TextStyle(color: AppColors.netflixGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: const TextStyle(color: AppColors.netflixGray),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playTrailer() async {
    if (_videos.isEmpty) return;

    final trailer = _videos.firstWhere(
      (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
      orElse: () => _videos.first,
    );

    final youtubeUrl = 'https://www.youtube.com/watch?v=${trailer['key']}';
    
    try {
      if (await canLaunchUrl(Uri.parse(youtubeUrl))) {
        await launchUrl(Uri.parse(youtubeUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching trailer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.netflixBlack,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.netflixRed),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(localizations),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContentInfo(localizations),
                      _buildActionButtons(localizations),
                      _buildOverview(localizations),
                      _buildCast(localizations),
                      _buildSimilarContent(localizations),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(AppLocalizations localizations) {
    final backdropPath = _contentDetails?['backdrop_path'] as String?;
    final posterPath = _contentDetails?['poster_path'] as String? ?? widget.posterPath;
    
    String backdropUrl = '';
    if (backdropPath != null && backdropPath.isNotEmpty) {
      backdropUrl = '${AppConstants.tmdbImageBaseUrl}$backdropPath';
    }

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.netflixBlack,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.netflixWhite,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.netflixRed : AppColors.netflixWhite,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdropUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.netflixDarkGray,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.netflixDarkGray,
                  child: const Icon(
                    Icons.movie,
                    size: 80,
                    color: AppColors.netflixGray,
                  ),
                ),
              )
            else
              Container(color: AppColors.netflixDarkGray),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                    AppColors.netflixBlack,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentInfo(AppLocalizations localizations) {
    final title = _contentDetails?['title'] as String? ?? 
                  _contentDetails?['name'] as String? ?? 
                  widget.title ?? '';
    final releaseDate = _contentDetails?['release_date'] as String? ?? 
                       _contentDetails?['first_air_date'] as String? ?? '';
    final voteAverage = _contentDetails?['vote_average'] as double? ?? 0.0;
    final runtime = _contentDetails?['runtime'] as int?;
    final genres = _contentDetails?['genres'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              color: AppColors.netflixWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Info row
          Row(
            children: [
              if (releaseDate.isNotEmpty) ...[
                Text(
                  releaseDate.split('-')[0],
                  style: const TextStyle(
                    color: AppColors.netflixGray,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              if (runtime != null) ...[
                Text(
                  '${runtime}m',
                  style: const TextStyle(
                    color: AppColors.netflixGray,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              // Rating
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.netflixWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Genres
          if (genres.isNotEmpty)
            Wrap(
              spacing: 8,
              children: genres.take(3).map<Widget>((genre) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.netflixDarkGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    genre['name'] as String,
                    style: const TextStyle(
                      color: AppColors.netflixWhite,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Play button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      contentId: widget.contentId,
                      contentType: widget.contentType,
                      title: _contentDetails?['title'] as String? ?? 
                             _contentDetails?['name'] as String? ?? 
                             widget.title,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.netflixWhite,
                foregroundColor: AppColors.netflixBlack,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.play_arrow, size: 24),
              label: Text(
                'Play',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Trailer button
          if (_videos.isNotEmpty)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _playTrailer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.netflixWhite,
                  side: const BorderSide(color: AppColors.netflixGray),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline, size: 24),
                label: Text(
                  'Trailer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverview(AppLocalizations localizations) {
    final overview = _contentDetails?['overview'] as String? ?? '';
    
    if (overview.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: const TextStyle(
              color: AppColors.netflixWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overview,
            style: const TextStyle(
              color: AppColors.netflixGray,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCast(AppLocalizations localizations) {
    if (_cast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Cast',
            style: const TextStyle(
              color: AppColors.netflixWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _cast.take(10).length,
            itemBuilder: (context, index) {
              final actor = _cast[index];
              final profilePath = actor['profile_path'] as String?;
              final name = actor['name'] as String? ?? '';
              final character = actor['character'] as String? ?? '';

              String imageUrl = '';
              if (profilePath != null && profilePath.isNotEmpty) {
                imageUrl = '${AppConstants.tmdbImageBaseUrl}$profilePath';
              }

              return Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.netflixDarkGray,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.netflixDarkGray,
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.netflixGray,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.netflixDarkGray,
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.netflixGray,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.netflixDarkGray,
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.netflixGray,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.netflixWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (character.isNotEmpty)
                      Text(
                        character,
                        style: const TextStyle(
                          color: AppColors.netflixGray,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSimilarContent(AppLocalizations localizations) {
    if (_similarContent.isEmpty) return const SizedBox.shrink();

    return ContentRow(
      title: 'Similar Content',
      items: _similarContent
          .map((content) => content..['type'] = widget.contentType)
          .toList(),
    );
  }
}