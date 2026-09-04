import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A circular icon button filled with the app's hero gradient — used for
/// primary "do the fun thing" actions (play a preview, jump to music) so
/// they read as a highlight rather than a plain outlined icon button.
class GradientIconButton extends StatelessWidget {
  const GradientIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 22,
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient(scheme),
          shape: BoxShape.circle,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Icon(icon, color: scheme.onPrimary, size: iconSize),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
