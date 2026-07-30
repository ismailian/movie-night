import 'package:flutter/services.dart' show rootBundle;

import '../models/movie_entry.dart';

/// Loads and parses the bundled `assets/movies.csv` into [MovieEntry]s.
///
/// The parser is deliberately forgiving: it accepts quoted fields (with commas
/// and escaped `""` quotes inside), skips blank lines, and matches headers
/// case-insensitively against the aliases in [MovieEntry.columnAliases].
class MovieRepository {
  MovieRepository({this.assetPath = 'assets/movies.csv'});

  final String assetPath;

  List<MovieEntry>? _cache;

  Future<List<MovieEntry>> loadMovies({bool forceReload = false}) async {
    if (_cache != null && !forceReload) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    _cache = parseCsv(raw);
    return _cache!;
  }

  /// Parses raw CSV text into entries. Exposed for testing.
  static List<MovieEntry> parseCsv(String raw) {
    final rows = _splitRows(raw);
    if (rows.isEmpty) return const [];

    // The header may or may not be present. If the first row contains any known
    // column name we treat it as a header; otherwise we assume a single "title"
    // column so a bare list of titles still works.
    final firstRow = rows.first.map((c) => c.toLowerCase().trim()).toList();
    final looksLikeHeader = firstRow.any((cell) =>
        MovieEntry.columnAliases.values.any((aliases) => aliases.contains(cell)));

    final List<String> header;
    final Iterable<List<String>> dataRows;
    if (looksLikeHeader) {
      header = firstRow;
      dataRows = rows.skip(1);
    } else {
      header = const ['title'];
      dataRows = rows;
    }

    final entries = <MovieEntry>[];
    for (final cells in dataRows) {
      if (cells.every((c) => c.trim().isEmpty)) continue;
      final row = <String, String>{};
      for (var i = 0; i < header.length && i < cells.length; i++) {
        row[header[i]] = cells[i];
      }
      final entry = MovieEntry.fromRow(row);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  /// Splits CSV text into rows of cells, honoring quoted fields.
  static List<List<String>> _splitRows(String raw) {
    final rows = <List<String>>[];
    var cells = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    void endField() {
      cells.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      rows.add(cells);
      cells = <String>[];
    }

    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++; // skip escaped quote
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        switch (ch) {
          case '"':
            inQuotes = true;
            break;
          case ',':
            endField();
            break;
          case '\n':
            endRow();
            break;
          default:
            field.write(ch);
        }
      }
    }
    // Flush any trailing field/row that wasn't newline-terminated.
    if (field.isNotEmpty || cells.isNotEmpty) endRow();
    return rows;
  }
}
