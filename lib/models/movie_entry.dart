/// One row from the CSV dataset — the *input* to a lookup.
///
/// Only [title] is required. [year] and [imdbId] are optional but improve
/// accuracy: an [imdbId] like `tt1375666` makes the OMDb lookup exact.
class MovieEntry {
  const MovieEntry({
    required this.title,
    this.year,
    this.imdbId,
  });

  final String title;
  final String? year;
  final String? imdbId;

  bool get hasImdbId => imdbId != null && imdbId!.trim().isNotEmpty;

  /// Column-name synonyms accepted by the forgiving CSV parser (all matched
  /// case-insensitively).
  static const Map<String, List<String>> columnAliases = {
    'title': ['title', 'name', 'movie', 'primarytitle', 'originaltitle'],
    'year': ['year', 'release_year', 'startyear'],
    'imdb': ['imdb_id', 'imdbid', 'imdb', 'tconst', 'id'],
  };

  /// Builds an entry from a normalized (lower-cased keys) CSV row, or returns
  /// null when no usable title is present.
  static MovieEntry? fromRow(Map<String, String> row) {
    String? pick(String field) {
      for (final alias in columnAliases[field]!) {
        final value = row[alias];
        if (value != null && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    final title = pick('title');
    if (title == null) return null;

    return MovieEntry(
      title: title,
      year: pick('year'),
      imdbId: pick('imdb'),
    );
  }

  @override
  String toString() => 'MovieEntry($title, $year, $imdbId)';
}
