import 'dart:math' as math;
import 'package:flutter/material.dart';

class RecordPulse extends StatefulWidget {
  final double size; // diameter of the central button
  final Color color;
  final int rings;
  final Widget? center;
  final VoidCallback? onTapCenter;
  const RecordPulse({
    super.key,
    this.size = 88,
    this.color = const Color(0xFFE53935),
    this.rings = 3,
    this.center,
    this.onTapCenter,
  });

  @override
  State<RecordPulse> createState() => _RecordPulseState();
}

class _RecordPulseState extends State<RecordPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  final math.Random _rnd = math.Random();
  late final List<double> _ringSkews = List<double>.generate(5, (_) => _rnd.nextDouble() * 0.5);
  late final List<double> _edgeOffsets = List<double>.generate(3, (_) => _rnd.nextDouble());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final double base = widget.size;
        final double span = base * 1.4; // how far waves grow
        final List<Widget> waves = <Widget>[];
        final int rings = widget.rings.clamp(2, 6);
        for (int i = 0; i < rings; i++) {
          final double skew = _ringSkews[i % _ringSkews.length];
          final double phase = (_c.value + i / rings + skew) % 1.0;
          final double radius = base + phase * span;
          final double opacity = (1.0 - phase).clamp(0.0, 1.0);
          final double offset = (radius - base) / 2; // center waves around button
          waves.add(
            Positioned(
              right: -offset,
              bottom: -offset,
              child: IgnorePointer(
                child: Container(
                  width: radius,
                  height: radius,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.1 + skew * 0.1), // slight drift
                      colors: [
                        widget.color.withOpacity(0.22 * opacity),
                        widget.color.withOpacity(0.06 * opacity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Center static button (no scaling) with circular hit test only
        final Widget center = Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: widget.onTapCenter,
            containedInkWell: true,
            customBorder: const CircleBorder(),
            child: Container(
              width: base,
              height: base,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [widget.color, widget.color.withOpacity(0.75)],
                  radius: 0.9,
                ),
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.45), blurRadius: 24, spreadRadius: 2),
                ],
              ),
              child: Center(child: widget.center ?? const Icon(Icons.mic, color: Colors.white, size: 34)),
            ),
          ),
        );

        // Multiple uneven edge pulse rings (only borders)
        final List<Widget> edgeRings = <Widget>[];
        const int edgeCount = 3;
        for (int i = 0; i < edgeCount; i++) {
          final double offs = _edgeOffsets[i];
          final double scale = 1.0 + 0.06 * math.sin((_c.value + offs) * 2 * math.pi);
          final double w = base + 6 + i * 5;
          edgeRings.add(
            Positioned(
              right: -(w - base) / 2,
              bottom: -(w - base) / 2,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: w,
                  height: w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color.withOpacity(0.30 - i * 0.07), width: 2),
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: base + span,
          height: base + span,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              ...waves,
              ...edgeRings,
              Positioned(right: 0, bottom: 0, child: center),
            ],
          ),
        );
      },
    );
  }
} 