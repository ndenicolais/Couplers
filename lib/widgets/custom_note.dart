import 'dart:math';
import 'package:flutter/material.dart';

class CustomNote extends StatelessWidget {
  const CustomNote({
    super.key,
    required this.child,
    this.color,
    this.width,
    this.height,
  });

  final Widget child;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.01 * pi,
      child: CustomPaint(
        painter: StickyNotePainter(
            color: color ?? Colors.yellow.shade200,
            width: width,
            height: height),
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    );
  }
}

class StickyNotePainter extends CustomPainter {
  StickyNotePainter({required this.color, this.width, this.height});

  final Color color;
  final double? width;
  final double? height;

  @override
  void paint(Canvas canvas, Size size) {
    size = Size(width ?? size.width, height ?? size.height);
    _drawShadow(size, canvas);

    Paint gradientPaint = _createGradientPaint(size);

    _drawNote(size, canvas, gradientPaint);
  }

  void _drawNote(Size size, Canvas canvas, Paint gradientPaint) {
    Path path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    double foldAmount = 0.12;
    path.lineTo(size.width * 3 / 4, size.height);
    path.quadraticBezierTo(size.width * foldAmount * 2, size.height,
        size.width * foldAmount, size.height - (size.height * foldAmount));
    path.quadraticBezierTo(
        0, size.height - (size.height * foldAmount * 1.5), 0, size.height / 4);
    path.lineTo(0, 0);
    canvas.drawPath(path, gradientPaint);
  }

  Paint _createGradientPaint(Size size) {
    Paint paint = Paint();
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    RadialGradient gradient = RadialGradient(
        colors: [(color), color],
        radius: 1.0,
        stops: const [0.5, 1.0],
        center: Alignment.bottomLeft);
    paint.shader = gradient.createShader(rect);

    return paint;
  }

  void _drawShadow(Size size, Canvas canvas) {
    Rect rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    Path path = Path();
    path.addRect(rect);
    canvas.drawShadow(path, Colors.black.withAlpha(128), 12.0, true);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
