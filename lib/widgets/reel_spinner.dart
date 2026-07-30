import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The signature film-reel "slot machine".
///
/// A vertical strip of movie titles flanked by film perforations. Call
/// [ReelSpinnerState.spinTo] with the already-chosen title; the reel builds a
/// run of random filler titles ending on that pick, then scrolls and
/// decelerates onto it with [Curves.easeOutQuart]. The pick is decided *before*
/// the animation — the spin is pure flourish.
class ReelSpinner extends StatefulWidget {
  const ReelSpinner({
    super.key,
    required this.pool,
    this.height = 168,
    this.itemExtent = 52,
    this.onSettled,
  });

  /// Titles used as filler frames while the reel spins.
  final List<String> pool;

  /// Height of the visible window.
  final double height;

  /// Height of a single title row.
  final double itemExtent;

  /// Called when the reel finishes decelerating onto its pick.
  final VoidCallback? onSettled;

  @override
  State<ReelSpinner> createState() => ReelSpinnerState();
}

class ReelSpinnerState extends State<ReelSpinner>
    with SingleTickerProviderStateMixin {
  static const int _fillerCount = 26;

  final Random _rng = Random();
  late final AnimationController _controller;
  late final Animation<double> _curve;

  List<String> _reel = const ['REEL ROULETTE'];
  int _startIndex = 0;
  int _endIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addListener(_onTick);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onSettled?.call();
    });
  }

  void _onTick() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Spins the reel and lands on [finalTitle].
  void spinTo(String finalTitle) {
    final landed = _reel.isEmpty ? 'REEL ROULETTE' : _reel[_currentIndex()];

    final filler = <String>[];
    final source = widget.pool.isEmpty ? [finalTitle] : widget.pool;
    for (var i = 0; i < _fillerCount; i++) {
      filler.add(source[_rng.nextInt(source.length)]);
    }

    _reel = [landed, ...filler, finalTitle];
    _startIndex = 0;
    _endIndex = _reel.length - 1;

    _controller
      ..reset()
      ..forward();
  }

  bool get isSpinning => _controller.isAnimating;

  int _currentIndex() {
    // Best-effort index of whatever is centered right now (used as the seed of
    // the next spin so it starts from where it stopped).
    return _reel.isEmpty ? 0 : _reel.length - 1;
  }

  /// Vertical offset (in px) that places item [index] in the center of the window.
  double _centerOffset(double index) =>
      index * widget.itemExtent + widget.itemExtent / 2 - widget.height / 2;

  @override
  Widget build(BuildContext context) {
    final t = _curve.value;
    final currentIndex = _startIndex + (_endIndex - _startIndex) * t;
    final offset = _centerOffset(currentIndex);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _perforations(),
          Expanded(
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.28, 0.72, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: _strip(offset),
            ),
          ),
          _perforations(),
        ],
      ),
    );
  }

  Widget _strip(double offset) {
    return Stack(
      children: [
        // The moving column of titles. An OverflowBox relaxes the height
        // constraint so the (much taller than the window) strip can lay out
        // without a RenderFlex overflow; Transform then paints it shifted.
        Positioned.fill(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Transform.translate(
                offset: Offset(0, -offset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _reel.length; i++)
                      _titleRow(_reel[i], _distanceFromCenter(i, offset)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // The stationary highlight bar marking the selection line.
        Center(
          child: IgnorePointer(
            child: Container(
              height: widget.itemExtent,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accent.withOpacity(0.55),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent.withOpacity(0.10),
                    AppTheme.accentAlt.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// How far item [i] is from the center line (0 = centered), in item units.
  double _distanceFromCenter(int i, double offset) {
    final itemCenter = i * widget.itemExtent + widget.itemExtent / 2;
    final windowCenter = offset + widget.height / 2;
    return (itemCenter - windowCenter) / widget.itemExtent;
  }

  Widget _titleRow(String title, double distance) {
    final d = distance.abs().clamp(0.0, 2.0);
    final opacity = (1.0 - d * 0.5).clamp(0.15, 1.0);
    final isCentered = d < 0.5;
    final color = Color.lerp(AppTheme.textMuted, AppTheme.textPrimary, 1 - d / 2)!;

    return SizedBox(
      height: widget.itemExtent,
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Opacity(
            opacity: opacity,
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.display(
                isCentered ? 30 : 26,
                color: isCentered ? AppTheme.accent : color,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A vertical strip of film sprocket holes.
  Widget _perforations() {
    return Container(
      width: 22,
      color: AppTheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          (widget.height / 24).floor(),
          (_) => Container(
            width: 10,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppTheme.outline, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
