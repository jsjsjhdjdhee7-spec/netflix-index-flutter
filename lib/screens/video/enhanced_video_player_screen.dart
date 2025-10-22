import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/video_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/content_provider.dart';
import '../../models/watch_history.dart';
import '../../services/firestore_service.dart';

class EnhancedVideoPlayerScreen extends StatefulWidget {
  final int contentId;
  final String contentType;
  final String? title;
  final int? seasonNumber;
  final int? episodeNumber;

  const EnhancedVideoPlayerScreen({
    super.key,
    required this.contentId,
    required this.contentType,
    this.title,
    this.seasonNumber,
    this.episodeNumber,
  });

  @override
  State<EnhancedVideoPlayerScreen> createState() => _EnhancedVideoPlayerScreenState();
}

class _EnhancedVideoPlayerScreenState extends State<EnhancedVideoPlayerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFullscreen = false;
  String _streamUrl = '';
  DateTime? _startTime;
  List<String> _availableServers = [];
  int _currentServerIndex = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _startTime = DateTime.now();
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      List<String> servers = [];
      
      if (widget.contentType == 'tv' && 
          widget.seasonNumber != null && 
          widget.episodeNumber != null) {
        servers = await VideoService.getTvEpisodeStreamUrls(
          widget.contentId,
          widget.seasonNumber!,
          widget.episodeNumber!,
        );
      } else {
        servers = await VideoService.getMovieStreamUrls(widget.contentId);
      }

      if (servers.isNotEmpty) {
        setState(() {
          _availableServers = servers;
          _streamUrl = servers[0];
          _isLoading = false;
        });
        _initializeWebView();
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing player: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _injectFullscreenScript();
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_streamUrl));
  }

  void _injectFullscreenScript() {
    _webViewController.runJavaScript('''
      // Enable fullscreen support
      document.addEventListener('fullscreenchange', function() {
        if (document.fullscreenElement) {
          window.flutter_inappwebview.callHandler('onFullscreenEnter');
        } else {
          window.flutter_inappwebview.callHandler('onFullscreenExit');
        }
      });
      
      // Add fullscreen button if not exists
      var video = document.querySelector('video');
      if (video) {
        video.setAttribute('controls', 'true');
        video.setAttribute('controlsList', 'nodownload');
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'contain';
      }
    ''');
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _switchServer(int index) {
    if (index < _availableServers.length) {
      setState(() {
        _currentServerIndex = index;
        _streamUrl = _availableServers[index];
        _isLoading = true;
      });
      _webViewController.loadRequest(Uri.parse(_streamUrl));
    }
  }

  void _showServerSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.netflixDarkGray,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Server',
                style: TextStyle(
                  color: AppColors.netflixWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_availableServers.length, (index) {
                return ListTile(
                  title: Text(
                    'Server ${index + 1}',
                    style: const TextStyle(color: AppColors.netflixWhite),
                  ),
                  leading: Radio<int>(
                    value: index,
                    groupValue: _currentServerIndex,
                    onChanged: (value) {
                      Navigator.pop(context);
                      if (value != null) {
                        _switchServer(value);
                      }
                    },
                    activeColor: AppColors.netflixRed,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _switchServer(index);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _saveWatchHistory();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _saveWatchHistory() async {
    if (_startTime != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        final watchHistory = WatchHistory(
          id: '',
          userId: authProvider.user!.id,
          contentId: widget.contentId,
          contentType: widget.contentType,
          title: widget.title ?? 'Unknown',
          posterPath: '',
          watchedAt: DateTime.now(),
          progress: 0.5, // Default progress
          seasonNumber: widget.seasonNumber,
          episodeNumber: widget.episodeNumber,
        );

        await FirestoreService.addWatchHistory(watchHistory);
        await contentProvider.loadUserData(authProvider.user!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls) {
            _hideControlsAfterDelay();
          }
        },
        child: Stack(
          children: [
            // Video Player
            Positioned.fill(
              child: _buildVideoPlayer(),
            ),
            
            // Controls Overlay
            if (_showControls)
              Positioned.fill(
                child: _buildControlsOverlay(),
              ),
            
            // Loading Indicator
            if (_isLoading)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.netflixRed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.netflixRed,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(
                color: AppColors.netflixWhite,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _initializePlayer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.netflixRed,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_streamUrl.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.netflixRed,
        ),
      );
    }

    return WebViewWidget(controller: _webViewController);
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.netflixWhite,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Video Player',
                      style: const TextStyle(
                        color: AppColors.netflixWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_availableServers.length > 1)
                    IconButton(
                      onPressed: _showServerSelection,
                      icon: const Icon(
                        Icons.settings,
                        color: AppColors.netflixWhite,
                        size: 28,
                      ),
                    ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _toggleFullscreen,
                    icon: Icon(
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: AppColors.netflixWhite,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}