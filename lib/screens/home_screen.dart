import 'dart:math';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/api_config.dart';
import '../data/movie_repository.dart';
import '../models/movie_details.dart';
import '../models/movie_entry.dart';
import '../services/omdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_result_card.dart';
import '../widgets/pick_button.dart';
import '../widgets/reel_spinner.dart';
import '../widgets/status_card.dart';

/// What's currently shown below the reel.
enum _View { intro, empty, loadError, spinning, missingKey, result, lookupError }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieRepository _repository = MovieRepository();
  final OmdbService _omdb = OmdbService();
  final GlobalKey<ReelSpinnerState> _reelKey = GlobalKey<ReelSpinnerState>();
  final Random _rng = Random();

  List<MovieEntry> _entries = const [];
  List<String> _pool = const [];

  _View _view = _View.intro;
  bool _busy = false;
  String? _errorMessage;
  MovieDetails? _result;
  String _appVersion = '';

  // The in-flight lookup, started the instant a pick is made so it resolves in
  // parallel with the reel animation.
  Future<MovieDetails>? _pendingLookup;
  MovieEntry? _pendingEntry;
  bool _reelSettled = false;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version} (${info.buildNumber})');
  }

  @override
  void dispose() {
    _omdb.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    try {
      final entries = await _repository.loadMovies();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _pool = entries.map((e) => e.title).toList();
        _view = entries.isEmpty ? _View.empty : _View.intro;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _view = _View.loadError;
        _errorMessage = 'Could not read assets/movies.csv — $e';
      });
    }
  }

  void _spin() {
    if (_entries.isEmpty || _busy) return;

    // The pick is decided *before* the animation; the reel just decelerates
    // onto it.
    final entry = _entries[_rng.nextInt(_entries.length)];

    // Kick the metadata lookup off in parallel (only when a key is configured).
    final Future<MovieDetails>? lookup =
        ApiConfig.hasKey ? _omdb.lookup(entry) : null;
    // Attach a silent listener now so an early failure isn't reported as an
    // unhandled async error before we await the same future at settle time.
    lookup?.then((_) {}, onError: (_) {});

    setState(() {
      _busy = true;
      _view = _View.spinning;
      _result = null;
      _errorMessage = null;
      _pendingEntry = entry;
      _pendingLookup = lookup;
      _reelSettled = false;
    });

    _reelKey.currentState?.spinTo(entry.title);
  }

  Future<void> _onReelSettled() async {
    _reelSettled = true;
    final entry = _pendingEntry;
    if (entry == null) return;

    if (!ApiConfig.hasKey) {
      setState(() {
        _busy = false;
        _view = _View.missingKey;
      });
      return;
    }

    try {
      final details = await _pendingLookup!;
      if (!mounted || !_reelSettled) return;
      setState(() {
        _busy = false;
        _result = details;
        _view = _View.result;
      });
    } catch (e) {
      if (!mounted || !_reelSettled) return;
      setState(() {
        _busy = false;
        _view = _View.lookupError;
        _errorMessage = '“${entry.title}” — $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backdropGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 24),
                ReelSpinner(
                  key: _reelKey,
                  pool: _pool.isEmpty ? const ['Reel Roulette'] : _pool,
                  onSettled: _onReelSettled,
                ),
                const SizedBox(height: 28),
                Center(
                  child: PickButton(
                    busy: _busy,
                    onPressed: _entries.isEmpty ? null : _spin,
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey(_view.name + (_result?.imdbId ?? '')),
                    child: _content(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter_rounded,
                color: AppTheme.accent, size: 34),
            const SizedBox(width: 10),
            Text('REEL ROULETTE', style: AppTheme.display(46)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Spin the reel • let fate pick tonight’s film',
          style: AppTheme.body(13, color: AppTheme.textMuted),
          textAlign: TextAlign.center,
        ),
        if (_entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_entries.length} movies loaded',
              style: AppTheme.body(11,
                  color: AppTheme.textMuted, weight: FontWeight.w600),
            ),
          ),
        if (_appVersion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _appVersion,
              style: AppTheme.body(10, color: AppTheme.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _content() {
    switch (_view) {
      case _View.intro:
      case _View.spinning:
        return const SizedBox.shrink();
      case _View.empty:
        return const StatusCard(kind: StatusKind.empty);
      case _View.loadError:
        return StatusCard(kind: StatusKind.error, message: _errorMessage);
      case _View.missingKey:
        return const StatusCard(kind: StatusKind.missingKey);
      case _View.lookupError:
        return StatusCard(kind: StatusKind.error, message: _errorMessage);
      case _View.result:
        return _result == null
            ? const SizedBox.shrink()
            : MovieResultCard(details: _result!);
    }
  }
}
