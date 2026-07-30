/// The *output* of an OMDb lookup — full metadata for a picked movie.
class MovieDetails {
  const MovieDetails({
    required this.title,
    required this.year,
    required this.rated,
    required this.runtime,
    required this.genre,
    required this.director,
    required this.actors,
    required this.plot,
    required this.posterUrl,
    required this.imdbRating,
    required this.imdbId,
  });

  final String title;
  final String year;
  final String rated;
  final String runtime;
  final String genre;
  final String director;
  final String actors;
  final String plot;
  final String posterUrl;
  final String imdbRating;
  final String imdbId;

  /// OMDb uses the literal string "N/A" for missing values; treat those as empty.
  static String _clean(dynamic value) {
    final s = (value ?? '').toString().trim();
    return (s.isEmpty || s == 'N/A') ? '' : s;
  }

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      title: _clean(json['Title']),
      year: _clean(json['Year']),
      rated: _clean(json['Rated']),
      runtime: _clean(json['Runtime']),
      genre: _clean(json['Genre']),
      director: _clean(json['Director']),
      actors: _clean(json['Actors']),
      plot: _clean(json['Plot']),
      posterUrl: _clean(json['Poster']),
      imdbRating: _clean(json['imdbRating']),
      imdbId: _clean(json['imdbID']),
    );
  }

  bool get hasPoster => posterUrl.isNotEmpty;
  bool get hasRating => imdbRating.isNotEmpty;

  /// Genre string split into individual tags.
  List<String> get genres => genre.isEmpty
      ? const []
      : genre.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList();

  String get imdbUrl =>
      imdbId.isEmpty ? '' : 'https://www.imdb.com/title/$imdbId/';
}
