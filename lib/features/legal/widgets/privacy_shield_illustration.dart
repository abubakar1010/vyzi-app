import 'package:flutter/material.dart';

/// The padlock-and-shield artwork that heads the Privacy Policy screen.
///
/// Lifted out of `privacy_policy.dart` when that screen was folded into the
/// shared [LegalDocumentScreen], so the illustration survives the refactor
/// instead of being replaced by a missing PNG.
class PrivacyShieldIllustration extends StatelessWidget {
  const PrivacyShieldIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFEEECFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A1ABE), width: 1.22),
      ),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 160,
          child: CustomPaint(painter: PrivacyShieldPainter()),
        ),
      ),
    );
  }
}

class PrivacyShieldPainter extends CustomPainter {
  static const _purple = Color(0xFF6C5CE7);
  static const _purpleLight = Color(0xFFB8B0F5);
  static const _purpleFill = Color(0xFFD9D5F8);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    _drawShield(canvas, cx, cy, 70, _purple, _purpleFill);
    _drawShield(canvas, cx, cy - 2, 50, _purpleLight, Colors.white.withValues(alpha: 0.5));

    final lockPaint = Paint()
      ..color = _purple
      ..style = PaintingStyle.fill;
    final lockStroke = Paint()
      ..color = _purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final shacklePath = Path();
    shacklePath.addArc(
      Rect.fromCenter(center: Offset(cx, cy - 8), width: 20, height: 20),
      3.14159,
      3.14159,
    );
    canvas.drawPath(shacklePath, lockStroke);

    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 26, height: 20),
      const Radius.circular(5),
    );
    canvas.drawRRect(lockRect, lockPaint);

    canvas.drawCircle(Offset(cx, cy + 2), 4, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 7.5), width: 3, height: 5),
      Paint()..color = Colors.white,
    );

    _drawPlant(canvas, cx - 58, cy + 45);
    _drawDevice(canvas, cx + 55, cy + 40);
    _drawWifi(canvas, cx + 52, cy - 20);
  }

  void _drawShield(Canvas canvas, double cx, double cy, double r,
      Color strokeColor, Color fillColor) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final path = _shieldPath(cx, cy, r);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
  }

  Path _shieldPath(double cx, double cy, double r) {
    final path = Path();
    final top = cy - r * 0.9;
    final bottom = cy + r * 1.0;
    final left = cx - r * 0.75;
    final right = cx + r * 0.75;
    final midY = cy + r * 0.1;

    path.moveTo(cx, top);
    path.cubicTo(cx + r * 0.1, top, right, top + r * 0.15, right, midY);
    path.cubicTo(right, midY + r * 0.5, cx + r * 0.3, bottom - r * 0.15, cx, bottom);
    path.cubicTo(cx - r * 0.3, bottom - r * 0.15, left, midY + r * 0.5, left, midY);
    path.cubicTo(left, top + r * 0.15, cx - r * 0.1, top, cx, top);
    path.close();
    return path;
  }

  void _drawPlant(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x, y), Offset(x, y - 24), paint);
    final leftLeaf = Path()
      ..moveTo(x, y - 10)
      ..cubicTo(x - 18, y - 18, x - 20, y - 30, x - 8, y - 28)
      ..cubicTo(x - 4, y - 27, x, y - 18, x, y - 10);
    canvas.drawPath(leftLeaf, paint);
    final rightLeaf = Path()
      ..moveTo(x, y - 16)
      ..cubicTo(x + 14, y - 20, x + 16, y - 30, x + 6, y - 28)
      ..cubicTo(x + 2, y - 27, x, y - 22, x, y - 16);
    canvas.drawPath(rightLeaf, paint);

    final potPaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final pot = Path()
      ..moveTo(x - 10, y)
      ..lineTo(x - 7, y + 12)
      ..lineTo(x + 7, y + 12)
      ..lineTo(x + 10, y);
    canvas.drawPath(pot, potPaint);
    canvas.drawLine(Offset(x - 12, y), Offset(x + 12, y), potPaint);
  }

  void _drawDevice(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y - 8), width: 22, height: 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(box, paint);

    canvas.drawCircle(Offset(x, y - 10), 6, paint);
    canvas.drawCircle(Offset(x, y - 10), 2.5, paint);

    canvas.drawCircle(Offset(x, y + 4), 1.5, Paint()..color = const Color(0xFF6C5CE7));
  }

  void _drawWifi(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final r = 6.0 + i * 6.0;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, y + 4), width: r * 2, height: r * 2),
        -2.4,
        1.4,
        false,
        paint,
      );
    }
    canvas.drawCircle(Offset(x, y + 4), 1.8, Paint()..color = const Color(0xFF6C5CE7));
  }

  @override
  bool shouldRepaint(PrivacyShieldPainter old) => false;
}
