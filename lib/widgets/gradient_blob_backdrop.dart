import 'dart:ui';

import 'package:flutter/material.dart';

/// Two soft, blurred color blobs behind [child] — the "aurora" decoration
/// used on Today and the auth screens to give otherwise-flat hero areas some
/// personality without adding noise to the content itself. Purely visual:
/// wrapped in [IgnorePointer] so it never intercepts taps meant for [child].
class GradientBlobBackdrop extends StatelessWidget {
  const GradientBlobBackdrop({super.key, required this.child, this.height});

  final Widget child;

  /// Clips the blob layer to this height (matching the hero area behind it)
  /// so blobs don't bleed into unrelated content further down the screen.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    Positioned(
                      top: -60,
                      left: -50,
                      child: _blob(220, scheme.primaryContainer),
                    ),
                    Positioned(
                      top: -30,
                      right: -70,
                      child: _blob(190, scheme.tertiaryContainer),
                    ),
                    Positioned(
                      top: 80,
                      left: -40,
                      child: _blob(160, scheme.secondaryContainer),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _blob(double diameter, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
