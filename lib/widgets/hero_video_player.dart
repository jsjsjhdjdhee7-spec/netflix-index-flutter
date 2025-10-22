import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/tmdb_service.dart';
import '../screens/details/content_details_screen.dart';
import '../screens/video/enhanced_video_player_screen.dart';

class HeroVideoPlayer extends StatefulWidget {
  final Map<String, dynamic> content;
  final String contentType;

  const HeroVideoPlayer({
    super.key,
    required this.content,
    required this.contentType,
  });

  @override
  State<HeroVideoPlayer> createState() => _HeroVideoPlayerState();
}

class _HeroVideoPlayerState extends State<HeroVideoPlayer> {
  WebViewController? _webViewController;
  bool _isVideoPlaying = false;
  bool _isVideoLoaded = false;
  String? _trailerUrl;
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadTrailer();
  }

  Future<void> _loadTrailer() async {
    try {
      final videos = await TMDBService.getContentVideos(
        widget.content['id'],
        widget.contentType,
      );
      
      if (videos.isNotEmpty) {
        // Find trailer or teaser
        final trailer = videos.firstWhere(
          (video) => video['type'] == 'Trailer' || video['type'] == 'Teaser',
          orElse: () => videos.first,
        );
        
        if (trailer['site'] == 'YouTube') {
          setState(() {
            _videos = videos;
            _trailerUrl = 'https://www.youtube.com/embed/${trailer['key']}?autoplay=1&mute=1&controls=0&loop=1&playlist=${trailer['key']}&modestbranding=1&showinfo=0&rel=0';
          });
          _initializeWebView();
        }
      }
    } catch (e) {
      print('Error loading trailer: $e');
    }
  }

  void _initializeWebView() {
    if (_trailerUrl != null) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              setState(() {
                _isVideoLoaded = true;
              });
              // Auto-play after 2 seconds
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _isVideoPlaying = true;
                  });
                }
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(_trailerUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.content['title'] ?? widget.content['name'] ?? '';
    final overview = widget.content['overview'] ?? '';
    final posterPath = widget.content['poster_path'];
    final backdropPath = widget.content['backdrop_path'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Stack(
        children: [
          // Background Image/Video
          Positioned.fill(
            child: _buildBackgroundContent(backdropPath),
          ),
          
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // Content Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left side - Movie info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Title
                        if (posterPath != null)
                          Container(
                            height: 120,
                            width: 200,
                            child: CachedNetworkImage(
                              imageUrl: '${AppConstants.imageBaseUrl}$posterPath',
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                              errorWidget: (context, url, error) => _buildTitleText(title),
                            ),
                          )
                        else
                          _buildTitleText(title),
                        
                        const SizedBox(height: 16),
                        
                        // Overview
                        if (overview.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Text(
                              overview,
                              style: const TextStyle(
                                color: AppColors.netflixWhite,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Play Button
                            _buildActionButton(
                              icon: Icons.play_arrow,
                              label: 'Play',
                              isPrimary: true,
                              onPressed: () => _playContent(),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // More Info Button
                            _buildActionButton(
                              icon: Icons.info_outline,
                              label: 'More Info',
                              isPrimary: false,
                              onPressed: () => _showMoreInfo(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Right side - Video controls
                  if (_isVideoPlaying && _trailerUrl != null)
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isVideoPlaying = false;
                              });
                            },
                            icon: const Icon(
                              Icons.volume_off,
                              color: AppColors.netflixWhite,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Video Play/Pause Overlay
          if (_trailerUrl != null && _isVideoLoaded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isVideoPlaying = !_isVideoPlaying;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: _isVideoPlaying
                      ? null
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: AppColors.netflixWhite,
                              size: 48,
                            ),
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundContent(String? backdropPath) {
    if (_isVideoPlaying && _trailerUrl != null && _webViewController != null) {
      return ClipRRect(
        child: WebViewWidget(controller: _webViewController!),
      );
    }
    
    if (backdropPath != null) {
      return CachedNetworkImage(
        imageUrl: '${AppConstants.imageBaseUrl}$backdropPath',
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.netflixDarkGray,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.netflixRed,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.netflixDarkGray,
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: AppColors.netflixGray,
              size: 48,
            ),
          ),
        ),
      );
    }
    
    return Container(
      color: AppColors.netflixDarkGray,
    );
  }

  Widget _buildTitleText(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.netflixWhite,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(2, 2),
            blurRadius: 4,
            color: Colors.black,
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: isPrimary ? AppColors.netflixBlack : AppColors.netflixWhite,
        size: 20,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isPrimary ? AppColors.netflixBlack : AppColors.netflixWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.netflixWhite : Colors.grey.withOpacity(0.7),
        foregroundColor: isPrimary ? AppColors.netflixBlack : AppColors.netflixWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 0,
      ),
    );
  }

  void _playContent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedVideoPlayerScreen(
          contentId: widget.content['id'],
          contentType: widget.contentType,
          title: widget.content['title'] ?? widget.content['name'],
        ),
      ),
    );
  }

  void _showMoreInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailsScreen(
          contentId: widget.content['id'],
          contentType: widget.contentType,
        ),
      ),
    );
  }
}