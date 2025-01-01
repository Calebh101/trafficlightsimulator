import 'dart:math';

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

    if (filled) {
      paint.style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;
  final bool filled;
  final IconData icon;
  final double rotation;

  ArrowPainter({
    required this.color,
    required this.filled,
    required this.icon,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double degrees = 90 + rotation;
    final double radians = degrees * (pi / 180);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: size.width,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    Offset offset = Offset(
      size.width / 2 - textPainter.width / 2,
      size.height / 2 - textPainter.height / 2,
    );

    canvas.save();

    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(radians);
    canvas.translate(-size.width / 2, -size.height / 2);

    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

Widget Circle({required double size, required Color color, required bool filled}) {
  return CustomPaint(
    size: Size(size, size),
    painter: CirclePainter(color: color, filled: filled),
  );
}

Widget Arrow({required double size, required Color color, required double direction}) {
  return CustomPaint(
    size: Size(size, size),
    painter: ArrowPainter(color: color, filled: true, icon: Icons.arrow_back, rotation: direction),
  );
}

Widget Light({required Color color, required bool active, double size = 40}) {
  return Circle(size: size, color: color, filled: active);
}

Widget ArrowLight({required Color color, double direction = 90, double size = 40}) {
  return Arrow(size: size, color: color, direction: direction);
}

Widget Stoplight({int direction = 0, int active = 1, double size = 60}) {
  if (direction == 0) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: size / 10,
        ),
        borderRadius: BorderRadius.circular(size / 5),
      ),
      child: Padding(
        padding: EdgeInsets.all(size / 10),
        child: Column(
          children: [
            Light(color: Colors.red, active: active == 1, size: size),
            Light(color: Colors.yellow, active: active == 2, size: size),
            Light(color: Colors.green, active: active == 3, size: size),
          ],
        ),
      ),
    );
  } else {
    return Text("Error: unknown direction. Please specify direction as either -1, 0, or 1.");
  }
}