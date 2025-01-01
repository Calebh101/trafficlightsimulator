import 'package:flutter/material.dart';

class CirclePainter extends CustomPainter {
  final Color color;
  final bool filled;

  CirclePainter({
    required this.color,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double stroke = size.width / 10;
    double radius = (size.width / 2) - (stroke / 2);

    Paint paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false; // No need to repaint in this case
  }
}

Widget Circle({required double size, required Color color, required bool filled}) {
  return CustomPaint(
    size: Size(size, size),
    painter: CirclePainter(color: color, filled: filled),
  );
}