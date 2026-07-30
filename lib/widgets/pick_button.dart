import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The glowing gradient call-to-action, with a slow idle pulse that stills
/// while a pick is in progress.
class PickButton extends StatefulWidget {
  const PickButton({
    super.key,
    required this.onPressed,
    required this.busy,
    this.label = 'SPIN THE REEL',
  });

  final VoidCallback? onPressed;
  final bool busy;
  final String label;

  @override
  State<PickButton> createState() => _PickButtonState();
}

class _PickButtonState extends State<PickButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        // Freeze the pulse (steady mild glow) while busy.
        final glow = widget.busy ? 0.5 : _pulse.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.35 + glow * 0.35),
                blurRadius: 24 + glow * 24,
                spreadRadius: 1 + glow * 3,
              ),
              BoxShadow(
                color: AppTheme.accentAlt.withOpacity(0.25 + glow * 0.25),
                blurRadius: 32 + glow * 20,
                spreadRadius: glow * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: enabled ? widget.onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: AppTheme.buttonGradient,
              color: enabled ? null : AppTheme.outline,
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.6,
              child: Container(
                height: 64,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.busy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      )
                    else
                      const Icon(Icons.local_movies_rounded,
                          color: Colors.black87, size: 26),
                    const SizedBox(width: 12),
                    Text(
                      widget.busy ? 'SPINNING…' : widget.label,
                      style: AppTheme.display(26, color: Colors.black87)
                          .copyWith(letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
