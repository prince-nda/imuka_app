import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Stylised street map (light roads between grey blocks), as drawn in the
/// Figma file. Used as a lightweight stand-in for a real map SDK.
class CityBlocksPainter extends CustomPainter {
  const CityBlocksPainter({required this.road, required this.block});

  final Color road;
  final Color block;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = road);
    final paint = Paint()..color = block;
    const gap = 14.0;
    const cellW = 112.0;
    const cellH = 86.0;
    var row = 0;
    for (var y = -cellH / 2; y < size.height; y += cellH + gap, row++) {
      // Offset every other row so the grid doesn't look mechanical.
      final shift = row.isOdd ? -cellW / 3 : 0.0;
      for (var x = shift; x < size.width; x += cellW + gap) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cellW, cellH),
            const Radius.circular(10),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CityBlocksPainter old) =>
      old.road != road || old.block != block;
}

/// Route from pickup to destination with the truck at [progress].
///
/// The travelled part is a solid green line, the remainder is dotted grey.
class RoutePainter extends CustomPainter {
  RoutePainter({
    required this.progress,
    required this.travelled,
    required this.remaining,
  });

  final double progress;
  final Color travelled;
  final Color remaining;

  /// Start and end as fractions of the canvas, matching the Figma layout.
  static const start = Offset(0.13, 0.80);
  static const end = Offset(0.82, 0.10);

  static Path pathFor(Size size) {
    Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
    final s = at(start);
    final e = at(end);
    return Path()
      ..moveTo(s.dx, s.dy)
      ..cubicTo(
        s.dx + size.width * 0.28,
        s.dy - size.height * 0.02,
        s.dx + size.width * 0.25,
        s.dy - size.height * 0.38,
        e.dx,
        e.dy,
      );
  }

  /// Position along the route for a progress value between 0 and 1.
  static Offset pointAt(Size size, double progress) {
    final metric = pathFor(size).computeMetrics().first;
    final tangent = metric.getTangentForOffset(
      metric.length * progress.clamp(0.0, 1.0),
    );
    return tangent?.position ?? Offset.zero;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final metric = pathFor(size).computeMetrics().first;
    final split = metric.length * progress.clamp(0.0, 1.0);

    canvas.drawPath(
      metric.extractPath(0, split),
      Paint()
        ..color = travelled
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    final dots = Paint()..color = remaining;
    for (var d = split + 12; d < metric.length; d += 12) {
      final pos = metric.getTangentForOffset(d)?.position;
      if (pos != null) canvas.drawCircle(pos, 2.6, dots);
    }
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.progress != progress ||
      old.travelled != travelled ||
      old.remaining != remaining;
}

/// Map background filling its parent.
class CityBlocksMap extends StatelessWidget {
  const CityBlocksMap({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: CityBlocksPainter(road: p.mapRoad, block: p.mapBlock),
      child: child ?? const SizedBox.expand(),
    );
  }
}
