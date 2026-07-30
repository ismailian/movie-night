import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/movie_details.dart';
import '../models/movie_entry.dart';

/// Raised when a lookup fails for a reason worth showing the user.
class OmdbException implements Exception {
  OmdbException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin client over the OMDb JSON API.
///
/// Prefers an exact lookup by IMDb id (`?i=tt...`) when the entry has one,
/// falling back to a title (+ optional year) search (`?t=...&y=...`).
class OmdbService {
  OmdbService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<MovieDetails> lookup(MovieEntry entry) async {
    if (!ApiConfig.hasKey) {
      throw OmdbException('No OMDb API key configured.');
    }

    final params = <String, String>{
      'apikey': ApiConfig.apiKey,
      'plot': 'full',
      'r': 'json',
    };
    if (entry.hasImdbId) {
      params['i'] = entry.imdbId!.trim();
    } else {
      params['t'] = entry.title;
      if (entry.year != null && entry.year!.trim().isNotEmpty) {
        params['y'] = entry.year!.trim();
      }
    }

    final uri = Uri.parse(ApiConfig.endpoint).replace(queryParameters: params);

    http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 12));
    } catch (_) {
      throw OmdbException('Network error — check your connection and try again.');
    }

    if (res.statusCode != 200) {
      throw OmdbException('OMDb returned HTTP ${res.statusCode}.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw OmdbException('Could not read OMDb response.');
    }

    if ((json['Response'] ?? '').toString().toLowerCase() == 'false') {
      final err = (json['Error'] ?? 'Movie not found.').toString();
      throw OmdbException(err);
    }

    return MovieDetails.fromJson(json);
  }

  void dispose() => _client.close();
}
