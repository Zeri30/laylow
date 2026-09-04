import 'package:flutter/material.dart';

/// A row of filled/unfilled dots (out of [max]) showing a 1-5 intensity at
/// a glance — used anywhere a past entry's rating is displayed, so "how
/// intense" reads visually rather than only as the text "3/5".
class IntensityMeter extends StatelessWidget {
  const IntensityMeter({
    super.key,
    required this.value,
    required this.color,
    this.max = 5,
    this.dotSize = 7,
  });

  final int value;
  final Color color;
  final int max;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Intensity $value out of $max',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < max; i++)
              Container(
                margin: EdgeInsets.only(right: i == max - 1 ? 0 : 4),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < value ? color : color.withValues(alpha: 0.22),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
