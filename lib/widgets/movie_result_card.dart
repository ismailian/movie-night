import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/movie_details.dart';
import '../theme/app_theme.dart';

/// The result card: poster, IMDb rating, year/runtime/rating chips, genres,
/// plot, director, cast, and the two action buttons.
class MovieResultCard extends StatelessWidget {
  const MovieResultCard({super.key, required this.details});

  final MovieDetails details;

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  void _watchTrailer(BuildContext context) {
    // OMDb doesn't serve trailer links, so open a YouTube search for the exact
    // title + year. (Swap in a TMDB /movie/{id}/videos lookup for real embeds.)
    final query = [details.title, details.year, 'trailer']
        .where((s) => s.isNotEmpty)
        .join(' ');
    final uri = Uri.https(
        'www.youtube.com', '/results', {'search_query': query});
    _open(context, uri);
  }

  void _openImdb(BuildContext context) {
    final url = details.imdbUrl;
    final uri = url.isNotEmpty
        ? Uri.parse(url)
        : Uri.https('www.imdb.com', '/find/', {'q': details.title});
    _open(context, uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _posterHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title.isEmpty ? 'Untitled' : details.title,
                  style: AppTheme.display(38),
                ),
                const SizedBox(height: 10),
                _metaChips(),
                if (details.genres.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _genreChips(),
                ],
                if (details.plot.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(details.plot,
                      style: AppTheme.body(15, color: AppTheme.textPrimary)),
                ],
                if (details.director.isNotEmpty)
                  _creditRow('Director', details.director),
                if (details.actors.isNotEmpty)
                  _creditRow('Cast', details.actors),
                const SizedBox(height: 20),
                _actions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterHeader() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (details.hasPoster)
            Image.network(
              details.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _posterFallback(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _posterFallback(loading: true),
            )
          else
            _posterFallback(),
          // Bottom gradient so the title area below reads cleanly.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.surface],
                ),
              ),
            ),
          ),
          if (details.hasRating)
            Positioned(top: 14, left: 14, child: _ratingBadge()),
        ],
      ),
    );
  }

  Widget _posterFallback({bool loading = false}) {
    return Container(
      color: AppTheme.surfaceHigh,
      alignment: Alignment.center,
      child: loading
          ? const CircularProgressIndicator(strokeWidth: 2.5)
          : Icon(Icons.movie_creation_outlined,
              size: 64, color: AppTheme.textMuted.withOpacity(0.6)),
    );
  }

  Widget _ratingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.imdbYellow,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('IMDb',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Text('${details.imdbRating}',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          Text(' / 10',
              style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _metaChips() {
    final items = <String>[
      if (details.year.isNotEmpty) details.year,
      if (details.rated.isNotEmpty) details.rated,
      if (details.runtime.isNotEmpty) details.runtime,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Text(item,
                style: AppTheme.body(13,
                    color: AppTheme.textMuted, weight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _genreChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final genre in details.genres)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.accent.withOpacity(0.18),
                AppTheme.accentAlt.withOpacity(0.18),
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
            ),
            child: Text(genre,
                style: AppTheme.body(13,
                    color: AppTheme.accent, weight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _creditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: AppTheme.body(13,
                  color: AppTheme.textMuted, weight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: AppTheme.body(14, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _watchTrailer(context),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Watch Trailer'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentAlt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openImdb(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Open in IMDb'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.imdbYellow,
              side: BorderSide(color: AppTheme.imdbYellow.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
