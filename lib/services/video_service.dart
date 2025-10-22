import '../constants/app_constants.dart';

class VideoService {
  // Multiple streaming servers
  static const List<Map<String, String>> _servers = [
    {
      'name': 'SuperEmbed',
      'baseUrl': 'https://multiembed.mov/?video_id=',
      'movieSuffix': '&tmdb=1',
      'tvSuffix': '&tmdb=1&s={season}&e={episode}',
    },
    {
      'name': 'VidSrc',
      'baseUrl': 'https://vidsrc.to/embed/movie/',
      'movieSuffix': '',
      'tvSuffix': '/tv/{season}/{episode}',
    },
    {
      'name': 'EmbedSu',
      'baseUrl': 'https://embed.su/embed/movie/',
      'movieSuffix': '',
      'tvSuffix': '/tv/{season}/{episode}',
    },
    {
      'name': 'SmashyStream',
      'baseUrl': 'https://player.smashy.stream/movie/',
      'movieSuffix': '',
      'tvSuffix': '/tv/{season}/{episode}',
    },
    {
      'name': 'VidLink',
      'baseUrl': 'https://vidlink.pro/movie/',
      'movieSuffix': '',
      'tvSuffix': '/tv/{season}/{episode}',
    },
  ];

  static List<String> getMovieStreamUrls(int tmdbId) {
    return _servers.map((server) {
      return '${server['baseUrl']}$tmdbId${server['movieSuffix']}';
    }).toList();
  }

  static List<String> getTvEpisodeStreamUrls(int tmdbId, int season, int episode) {
    return _servers.map((server) {
      String suffix = server['tvSuffix']!
          .replaceAll('{season}', season.toString())
          .replaceAll('{episode}', episode.toString());
      return '${server['baseUrl']}$tmdbId$suffix';
    }).toList();
  }

  // Legacy methods for backward compatibility
  static String getMovieStreamUrl(int tmdbId) {
    return getMovieStreamUrls(tmdbId).first;
  }

  static String getTvShowStreamUrl(int tmdbId, int season, int episode) {
    return getTvEpisodeStreamUrls(tmdbId, season, episode).first;
  }

  static String getVipMovieStreamUrl(int tmdbId) {
    return '${AppConstants.superEmbedVipUrl}?video_id=$tmdbId&tmdb=1';
  }

  static String getVipTvShowStreamUrl(int tmdbId, int season, int episode) {
    return '${AppConstants.superEmbedVipUrl}?video_id=$tmdbId&tmdb=1&s=$season&e=$episode';
  }

  static Future<bool> checkVipAvailability(int tmdbId, {int? season, int? episode}) async {
    try {
      String url = '${AppConstants.superEmbedVipUrl}?video_id=$tmdbId&tmdb=1&check=1';
      if (season != null && episode != null) {
        url += '&s=$season&e=$episode';
      }
      
      // This would require an HTTP request to check availability
      // For now, we'll assume VIP is available for popular content
      return true;
    } catch (e) {
      print('Error checking VIP availability: $e');
      return false;
    }
  }

  static String addSubtitles(String baseUrl, String subtitleUrl, String subtitleLabel) {
    final encodedSubUrl = Uri.encodeComponent(subtitleUrl);
    final encodedSubLabel = Uri.encodeComponent(subtitleLabel);
    return '$baseUrl&sub_url=$encodedSubUrl&sub_label=$encodedSubLabel';
  }

  // Helper method to determine the best streaming option
  static Future<String> getBestStreamUrl(int tmdbId, {int? season, int? episode}) async {
    bool vipAvailable = await checkVipAvailability(tmdbId, season: season, episode: episode);
    
    if (vipAvailable) {
      if (season != null && episode != null) {
        return getVipTvShowStreamUrl(tmdbId, season, episode);
      } else {
        return getVipMovieStreamUrl(tmdbId);
      }
    } else {
      if (season != null && episode != null) {
        return getTvShowStreamUrl(tmdbId, season, episode);
      } else {
        return getMovieStreamUrl(tmdbId);
      }
    }
  }
}