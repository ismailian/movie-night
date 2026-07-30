import 'package:flutter_test/flutter_test.dart';
import 'package:reel_roulette/data/movie_repository.dart';

void main() {
  group('MovieRepository.parseCsv', () {
    test('parses a standard header + rows', () {
      const csv = 'title,year,imdb_id\n'
          'Inception,2010,tt1375666\n'
          'Parasite,2019,tt6751668\n';
      final entries = MovieRepository.parseCsv(csv);
      expect(entries.length, 2);
      expect(entries.first.title, 'Inception');
      expect(entries.first.year, '2010');
      expect(entries.first.imdbId, 'tt1375666');
    });

    test('is forgiving about alias headers and case', () {
      const csv = 'Name,startYear,tconst\n'
          'The Matrix,1999,tt0133093\n';
      final entries = MovieRepository.parseCsv(csv);
      expect(entries.single.title, 'The Matrix');
      expect(entries.single.year, '1999');
      expect(entries.single.imdbId, 'tt0133093');
    });

    test('handles a bare list of titles with no header', () {
      const csv = 'Inception\nParasite\nThe Matrix\n';
      final entries = MovieRepository.parseCsv(csv);
      expect(entries.map((e) => e.title),
          containsAll(['Inception', 'Parasite', 'The Matrix']));
    });

    test('honors quoted fields containing commas', () {
      const csv = 'title,year\n'
          '"Crouching Tiger, Hidden Dragon",2000\n';
      final entries = MovieRepository.parseCsv(csv);
      expect(entries.single.title, 'Crouching Tiger, Hidden Dragon');
      expect(entries.single.year, '2000');
    });

    test('skips blank lines and rows without a title', () {
      const csv = 'title,year\n\nInception,2010\n,1999\n';
      final entries = MovieRepository.parseCsv(csv);
      expect(entries.length, 1);
      expect(entries.single.title, 'Inception');
    });
  });
}
