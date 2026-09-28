import 'package:flutter/material.dart';
import 'package:vyzi/core/utils/app_colors.dart';

class FaqQuestion extends StatelessWidget {
  const FaqQuestion({super.key});

  static const _purpleBg = AppColors.primary100;
  static const _textDark = AppColors.textDark;
  static const _textMid = AppColors.textMid;
  static const _bg = AppColors.background;

  static const _policyPoints = [
    'Lorem ipsum dolor sit amet consectetur. Lacus at venenatis gravida vivamus mauris. Quisque mi est vel dis. Donec rhoncus laoreet odio orci sed risus elit accumsan. Mattis ut est tristique amet vitae at aliquet. Ac vel porttitor egestas scelerisque enim quisque senectus. Euismod ultricies vulputate id cras bibendum sollicitudin proin odio bibendum. Velit velit in scelerisque erat etiam rutrum phasellus nunc. Sed lectus sed a at et eget. Nunc purus sed quis at risus. Consectetur nibh justo proin placerat condimentum id at adipiscing.',
    'Vel blandit mi nulla sodales consectetur. Egestas tristique ultrices gravida duis nisl odio. Posuere curabitur eu platea pellentesque ut. Facilisi elementum neque mauris facilisis in. Cursus condimentum ipsum pretium consequat turpis at porttitor nisi.',
    'Scelerisque tellus praesent condimentum euismod a faucibus. Auctor at ultricies at urna aliquam massa pellentesque. Vitae vulputate nullam diam placerat at magna egestas. Lectus lectus consequat porta lectus purus. Nulla duis sem sit at imperdiet lobortis dui. Nunc tellus cursus maecenas phasellus sollicitudin donec dictum. Sodales in faucibus libero augue vestibulum urna mattis curabitur. Sed nullam consectetur euismod a laoreet dui. Nulla porttitor urna id blandit.',
    'Pretium pulvinar morbi suspendisse mattis.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── Illustration Card ──
            _illustrationCard(),
            const SizedBox(height: 28),
            // ── Title ──
            const Text(
              'Domande Frequenti',
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            // ── Bullet Points ──
            ..._policyPoints.map((point) => _bulletItem(point)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: _textDark, size: 28),
        ),
      ),
      title: const Text(
        'Domande Frequenti',
        style: TextStyle(
          color: _textDark,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ── Illustration Card ──
  Widget _illustrationCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: _purpleBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A1ABE), width: 1.22),
      ),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 160,
          child: CustomPaint(
            painter: _PrivacyIllustrationPainter(),
          ),
        ),
      ),
    );
  }

  // ── Bullet Item ──
  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: _textMid,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _textMid,
                fontSize: 13,
                height: 1.65,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Illustration Painter
// ─────────────────────────────────────────────
class _PrivacyIllustrationPainter extends CustomPainter {
  static const _purple = AppColors.primaryColor;
  static const _purpleLight = AppColors.primary300;
  static const _purpleFill = AppColors.primary200;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    // ── Main Shield ──
    _drawShield(canvas, cx, cy, 70, _purple, _purpleFill);

    // ── Inner Shield ──
    _drawShield(canvas, cx, cy - 2, 50, _purpleLight, Colors.white.withOpacity(0.5));

    // ── Lock body ──
    final lockPaint = Paint()
      ..color = _purple
      ..style = PaintingStyle.fill;
    final lockStroke = Paint()
      ..color = _purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Lock shackle (arc)
    final shacklePath = Path();
    shacklePath.addArc(
      Rect.fromCenter(
          center: Offset(cx, cy - 8), width: 20, height: 20),
      3.14159,
      3.14159,
    );
    canvas.drawPath(shacklePath, lockStroke);

    // Lock body rect
    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 26, height: 20),
      const Radius.circular(5),
    );
    canvas.drawRRect(lockRect, lockPaint);

    // Keyhole circle
    canvas.drawCircle(Offset(cx, cy + 2), 4, Paint()..color = Colors.white);
    // Keyhole stem
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 7.5), width: 3, height: 5),
      Paint()..color = Colors.white,
    );

    // ── Left plant ──
    _drawPlant(canvas, cx - 58, cy + 45);

    // ── Right speaker/device ──
    _drawDevice(canvas, cx + 55, cy + 40);

    // ── Wifi arcs (top right of shield) ──
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
      ..color = const Color(0xFF5A1ABE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Stem
    canvas.drawLine(Offset(x, y), Offset(x, y - 24), paint);
    // Left leaf
    final leftLeaf = Path()
      ..moveTo(x, y - 10)
      ..cubicTo(x - 18, y - 18, x - 20, y - 30, x - 8, y - 28)
      ..cubicTo(x - 4, y - 27, x, y - 18, x, y - 10);
    canvas.drawPath(leftLeaf, paint);
    // Right leaf
    final rightLeaf = Path()
      ..moveTo(x, y - 16)
      ..cubicTo(x + 14, y - 20, x + 16, y - 30, x + 6, y - 28)
      ..cubicTo(x + 2, y - 27, x, y - 22, x, y - 16);
    canvas.drawPath(rightLeaf, paint);

    // Pot
    final potPaint = Paint()
      ..color = const Color(0xFF5A1ABE)
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
      ..color = const Color(0xFF5A1ABE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Speaker box
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y - 8), width: 22, height: 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(box, paint);

    // Speaker circles
    canvas.drawCircle(Offset(x, y - 10), 6, paint);
    canvas.drawCircle(Offset(x, y - 10), 2.5, paint);

    // Dots at bottom
    canvas.drawCircle(Offset(x, y + 4), 1.5, Paint()..color = const Color(0xFF5A1ABE));
  }

  void _drawWifi(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = const Color(0xFF5A1ABE)
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
    canvas.drawCircle(Offset(x, y + 4), 1.8, Paint()..color = const Color(0xFF5A1ABE));
  }

  @override
  bool shouldRepaint(_PrivacyIllustrationPainter old) => false;
}
