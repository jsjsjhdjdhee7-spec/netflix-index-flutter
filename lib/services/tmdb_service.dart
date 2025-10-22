import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';

class TMDBService {
  static const String _baseUrl = AppConstants.tmdbBaseUrl;
  static const String _accessToken = AppConstants.tmdbAccessToken;

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  // Movies
  static Future<List<Movie>> getPopularMovies({String language = 'ar', int page = 1}) async {
    return _getMovies('movie/popular', language: language, page: page);
  }

  static Future<List<Movie>> getTopRatedMovies({String language = 'ar', int page = 1}) async {
    return _getMovies('movie/top_rated', language: language, page: page);
  }

  static Future<List<Movie>> getNowPlayingMovies({String language = 'ar', int page = 1}) async {
    return _getMovies('movie/now_playing', language: language, page: page);
  }

  static Future<List<Movie>> getUpcomingMovies({String language = 'ar', int page = 1}) async {
    return _getMovies('movie/upcoming', language: language, page: page);
  }

  static Future<List<Movie>> searchMovies(String query, {String language = 'ar', int page = 1}) async {
    return _getMovies('search/movie', language: language, page: page, query: query);
  }

  static Future<Movie?> getMovieDetails(int movieId, {String language = 'ar'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId?language=$language'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromJson(data);
      }
    } catch (e) {
      print('Error getting movie details: $e');
    }
    return null;
  }

  // TV Shows
  static Future<List<TvShow>> getPopularTvShows({String language = 'ar', int page = 1}) async {
    return _getTvShows('tv/popular', language: language, page: page);
  }

  static Future<List<TvShow>> getTopRatedTvShows({String language = 'ar', int page = 1}) async {
    return _getTvShows('tv/top_rated', language: language, page: page);
  }

  static Future<List<TvShow>> getOnTheAirTvShows({String language = 'ar', int page = 1}) async {
    return _getTvShows('tv/on_the_air', language: language, page: page);
  }

  static Future<List<TvShow>> getAiringTodayTvShows({String language = 'ar', int page = 1}) async {
    return _getTvShows('tv/airing_today', language: language, page: page);
  }

  static Future<List<TvShow>> searchTvShows(String query, {String language = 'ar', int page = 1}) async {
    return _getTvShows('search/tv', language: language, page: page, query: query);
  }

  static Future<TvShow?> getTvShowDetails(int tvId, {String language = 'ar'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$tvId?language=$language'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TvShow.fromJson(data);
      }
    } catch (e) {
      print('Error getting TV show details: $e');
    }
    return null;
  }

  // Trending
  static Future<List<Movie>> getTrendingMovies({String language = 'ar', String timeWindow = 'day'}) async {
    return _getMovies('trending/movie/$timeWindow', language: language);
  }

  static Future<List<TvShow>> getTrendingTvShows({String language = 'ar', String timeWindow = 'day'}) async {
    return _getTvShows('trending/tv/$timeWindow', language: language);
  }

  // Private helper methods
  static Future<List<Movie>> _getMovies(String endpoint, {String language = 'ar', int page = 1, String? query}) async {
    try {
      String url = '$_baseUrl/$endpoint?language=$language&page=$page';
      if (query != null && query.isNotEmpty) {
        url += '&query=${Uri.encodeComponent(query)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting movies from $endpoint: $e');
    }
    return [];
  }

  static Future<List<TvShow>> _getTvShows(String endpoint, {String language = 'ar', int page = 1, String? query}) async {
    try {
      String url = '$_baseUrl/$endpoint?language=$language&page=$page';
      if (query != null && query.isNotEmpty) {
        url += '&query=${Uri.encodeComponent(query)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((json) => TvShow.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting TV shows from $endpoint: $e');
    }
    return [];
  }

  // Get fallback data in English if Arabic is not available
  static Future<List<Movie>> getMoviesWithFallback(String endpoint, {String primaryLanguage = 'ar', int page = 1}) async {
    List<Movie> movies = await _getMovies(endpoint, language: primaryLanguage, page: page);
    
    // If no results in primary language, try English
    if (movies.isEmpty && primaryLanguage != 'en') {
      movies = await _getMovies(endpoint, language: 'en', page: page);
    }
    
    return movies;
  }

  static Future<List<TvShow>> getTvShowsWithFallback(String endpoint, {String primaryLanguage = 'ar', int page = 1}) async {
    List<TvShow> tvShows = await _getTvShows(endpoint, language: primaryLanguage, page: page);
    
    // If no results in primary language, try English
    if (tvShows.isEmpty && primaryLanguage != 'en') {
      tvShows = await _getTvShows(endpoint, language: 'en', page: page);
    }
    
    return tvShows;
  }

  // Content Details (Generic for both movies and TV shows)
  static Future<Map<String, dynamic>> getContentDetails(int contentId, String contentType, {String language = 'ar'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$contentType/$contentId?language=$language'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error getting content details: $e');
    }
    return {};
  }

  // Get Cast and Crew
  static Future<List<Map<String, dynamic>>> getContentCredits(int contentId, String contentType) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$contentType/$contentId/credits'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['cast'] ?? []);
      }
    } catch (e) {
      print('Error getting content credits: $e');
    }
    return [];
  }

  // Get Similar Content
  static Future<List<Map<String, dynamic>>> getSimilarContent(int contentId, String contentType, {String language = 'ar'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$contentType/$contentId/similar?language=$language'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
    } catch (e) {
      print('Error getting similar content: $e');
    }
    return [];
  }

  // Get Videos (Trailers, etc.)
  static Future<List<Map<String, dynamic>>> getContentVideos(int contentId, String contentType) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$contentType/$contentId/videos'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
    } catch (e) {
      print('Error getting content videos: $e');
    }
    return [];
  }

  // Get Popular TV Shows with pagination
  static Future<List<TvShow>> getPopularTvShows({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/popular?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting popular TV shows: $e');
    }
    return [];
  }

  // Get Top Rated TV Shows with pagination
  static Future<List<TvShow>> getTopRatedTvShows({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/top_rated?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting top rated TV shows: $e');
    }
    return [];
  }

  // Get On The Air TV Shows with pagination
  static Future<List<TvShow>> getOnTheAirTvShows({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/on_the_air?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting on the air TV shows: $e');
    }
    return [];
  }

  // Get Airing Today TV Shows with pagination
  static Future<List<TvShow>> getAiringTodayTvShows({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/airing_today?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => TvShow.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting airing today TV shows: $e');
    }
    return [];
  }

  // Get Popular Movies with pagination
  static Future<List<Movie>> getPopularMovies({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/popular?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting popular movies: $e');
    }
    return [];
  }

  // Get Top Rated Movies with pagination
  static Future<List<Movie>> getTopRatedMovies({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/top_rated?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting top rated movies: $e');
    }
    return [];
  }

  // Get Now Playing Movies with pagination
  static Future<List<Movie>> getNowPlayingMovies({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/now_playing?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting now playing movies: $e');
    }
    return [];
  }

  // Get Upcoming Movies with pagination
  static Future<List<Movie>> getUpcomingMovies({String language = 'ar', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/upcoming?language=$language&page=$page'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting upcoming movies: $e');
    }
    return [];
  }

  // Get Recommendations
  static Future<List<Map<String, dynamic>>> getContentRecommendations(int contentId, String contentType, {String language = 'ar'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$contentType/$contentId/recommendations?language=$language'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
    } catch (e) {
      print('Error getting content recommendations: $e');
    }
    return [];
  }
}