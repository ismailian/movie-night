import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatusKind { missingKey, error, empty, loading }

/// A soft card used for the non-result states: missing API key, load/lookup
/// errors, an empty dataset, or a loading placeholder.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.kind,
    this.message,
  });

  final StatusKind kind;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color, String title, String body}) c =
        switch (kind) {
      StatusKind.missingKey => (
          icon: Icons.vpn_key_rounded,
          color: AppTheme.accent,
          title: 'Add your OMDb key',
          body: message ??
              'Get a free key at omdbapi.com/apikey.aspx, then paste it into '
                  'lib/config/api_config.dart — or run with '
                  '--dart-define=OMDB_API_KEY=yourkey. The reel still spins '
                  'without a key; you just won\'t see live metadata.',
        ),
      StatusKind.error => (
          icon: Icons.error_outline_rounded,
          color: AppTheme.accentAlt,
          title: 'Couldn\'t load that one',
          body: message ?? 'Something went wrong. Give the reel another spin.',
        ),
      StatusKind.empty => (
          icon: Icons.movie_filter_outlined,
          color: AppTheme.accent,
          title: 'No movies yet',
          body: message ??
              'Add titles to assets/movies.csv, then hot-restart so the asset '
                  'reloads.',
        ),
      StatusKind.loading => (
          icon: Icons.hourglass_top_rounded,
          color: AppTheme.textMuted,
          title: 'Loading…',
          body: message ?? 'Warming up the projector.',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.icon, color: c.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  c.title,
                  style: AppTheme.display(24, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            c.body,
            style: AppTheme.body(14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
