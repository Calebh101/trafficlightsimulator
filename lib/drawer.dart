import 'dart:math';
import 'package:flutter/material.dart';

class CirclePainter extends CustomPainter {
  final Color color;
  final bool filled;
  final Animation<double>? animation;

  CirclePainter({
    required this.color,
    required this.filled,
    this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (!filled && animation == null) {
      return;
    }

    double stroke = size.width / 10;
    double radius = (size.width / 2) - (stroke / 2);

    Paint paint = Paint()
      ..color = animation == null ? color : color.withValues(alpha: animation!.value.round().toDouble())
      ..style = PaintingStyle.fill
      ..strokeWidth = stroke;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;
  final bool filled;
  final IconData icon;
  final double rotation;
  final Animation<double>? animation;

  ArrowPainter({
    required this.color,
    required this.filled,
    required this.icon,
    required this.rotation,
    this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (!filled && animation == null) {
      return;
    }

    final double degrees = 90 + rotation;
    final double radians = degrees * (pi / 180);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: size.width,
          color: animation == null ? color : color.withValues(alpha: animation!.value.round().toDouble()),
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

Widget Circle({required double size, required Color color, required bool filled, Animation<double>? animation}) {
  return CustomPaint(
    size: Size(size, size),
    painter: CirclePainter(color: color, filled: filled, animation: animation),
  );
}

Widget Arrow({required double size, required Color color, required double direction, Animation<double>? animation, required bool filled}) {
  return CustomPaint(
    size: Size(size, size),
    painter: ArrowPainter(color: color, filled: filled, icon: Icons.arrow_back, rotation: direction, animation: animation),
  );
}

Widget Light({required Color color, required bool active, double size = 40, Animation<double>? animation}) {
  return Circle(size: size, color: color, filled: active, animation: animation);
}

Widget ArrowLight({required Color color, double direction = 90, double size = 40, Animation<double>? animation, bool active = true}) {
  return Arrow(size: size, color: color, direction: direction, animation: animation, filled: active);
}

Widget Stoplight({int direction = 0, int active = 1, int subactive = 0, double size = 30, Animation<double>? animation, bool rightRed = false, bool extended = false}) {
  print("drawer settings: $rightRed,$extended");
  if (direction <= 2 && direction >= -2) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
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
            children: getLights(direction, active, subactive, size, animation, rightRed, extended),
          ),
        ),
      ),
    );
  } else {
    return Text("Error: unknown direction. Please specify direction between -2 and 2.");
  }
}

List<Widget> getLights(int direction, int active, int subactive, double size, Animation<double>? animation, bool rightRed, bool extended) {
  List<Widget> dir0 = [
    Light(color: Colors.red, active: active == 1, size: size, animation: active == 4 ? animation : null),
    Light(color: Colors.yellow, active: active == 2, size: size, animation: active == 5 ? animation : null),
    Light(color: Colors.green, active: active == 3, size: size, animation: active == 6 ? animation : null),
  ];

  List<Widget> dir2 = [
    ArrowLight(color: Colors.yellow, active: subactive == 2, size: size, animation: subactive == 5 ? animation : null),
    ArrowLight(color: Colors.green, active: subactive == 3, size: size, animation: subactive == 6 ? animation : null),
  ];

  List<Widget> dirnB = [
    ArrowLight(color: Colors.yellow, active: subactive == 2, size: size, animation: subactive == 5 ? animation : null, direction: -90),
    ArrowLight(color: Colors.green, active: subactive == 3, size: size, animation: subactive == 6 ? animation : null, direction: -90),
  ];

  List<Widget> dirn2 = List<Widget>.from(dirnB);
  dirn2.insert(0, ArrowLight(color: Colors.red, active: subactive == 1, size: size, animation: subactive == 4 ? animation : null, direction: -90));

  List<Widget> dir1 = List<Widget>.from(dir0) + List<Widget>.from(dir2);
  List<Widget> dirn1 = List<Widget>.from(dir0) + List<Widget>.from(dirnB);

  if (rightRed) {
    dir2.insert(0, ArrowLight(color: Colors.red, active: subactive == 1, size: size, animation: subactive == 4 ? animation : null));
  }

  if (extended) {
    dir1.insert(3, ArrowLight(color: Colors.red, active: subactive == 1, size: size, animation: subactive == 4 ? animation : null, direction: -90));
    dirn1.insert(3, ArrowLight(color: Colors.red, active: subactive == 1, size: size, animation: subactive == 4 ? animation : null, direction: -90));
  }

  switch (direction) {
    case 0: return dir0;
    case 1: return dir1;
    case 2: return dir2;
    case -1: return dirn1;
    case -2: return dirn2;
    default: return dir0;
  }
}