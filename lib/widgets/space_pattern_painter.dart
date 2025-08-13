import 'package:flutter/material.dart';

class SpacePatternPainter extends CustomPainter {
  final double tile; // base tile size before scale
  final double opacity;
  final Color color;
  final double scale;
  const SpacePatternPainter({this.tile = 160, this.opacity = 0.22, this.color = const Color(0xFF0088CC), this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 1.6 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillDot = Paint()..color = color.withOpacity(opacity);

    final ts = tile * scale; // tile spacing

    for (double y = 0; y < size.height + ts; y += ts) {
      for (double x = 0; x < size.width + ts; x += ts) {
        final o = Offset(x, y);
        _drawTile(canvas, o, stroke, fillDot);
      }
    }
  }

  void _drawTile(Canvas c, Offset o, Paint pl, Paint pd) {
    double s(double v) => v * scale;

    // small star helper
    void star(Offset p, double r) {
      final path = Path()
        ..moveTo(p.dx, p.dy - r)
        ..lineTo(p.dx, p.dy + r)
        ..moveTo(p.dx - r, p.dy)
        ..lineTo(p.dx + r, p.dy);
      c.drawPath(path, pl);
    }

    star(o + Offset(s(18), s(18)), s(6));
    star(o + Offset(s(120), s(26)), s(4));
    star(o + Offset(s(60), s(10)), s(5));

    // planet with ring
    c.drawCircle(o + Offset(s(42), s(82)), s(14), pl);
    c.drawOval(Rect.fromCenter(center: o + Offset(s(42), s(88)), width: s(44), height: s(12)), pl);

    // ufo
    c.drawOval(Rect.fromCenter(center: o + Offset(s(110), s(70)), width: s(40), height: s(12)), pl);
    c.drawOval(Rect.fromCenter(center: o + Offset(s(110), s(60)), width: s(18), height: s(10)), pl);
    c.drawCircle(o + Offset(s(96), s(70)), s(2), pd);
    c.drawCircle(o + Offset(s(110), s(70)), s(2), pd);
    c.drawCircle(o + Offset(s(124), s(70)), s(2), pd);

    // comet
    final comet = Path()
      ..moveTo(o.dx + s(16), o.dy + s(128))
      ..quadraticBezierTo(o.dx + s(48), o.dy + s(112), o.dx + s(76), o.dy + s(120))
      ..quadraticBezierTo(o.dx + s(56), o.dy + s(132), o.dx + s(16), o.dy + s(128));
    c.drawPath(comet, pl);
    c.drawCircle(o + Offset(s(82), s(122)), s(4), pd);

    // dots
    c.drawCircle(o + Offset(s(20), s(46)), s(1.2), pd);
    c.drawCircle(o + Offset(s(84), s(28)), s(1.2), pd);
    c.drawCircle(o + Offset(s(132), s(96)), s(1.2), pd);
  }

  @override
  bool shouldRepaint(covariant SpacePatternPainter old) =>
      old.tile != tile || old.opacity != opacity || old.color != color || old.scale != scale;
} 