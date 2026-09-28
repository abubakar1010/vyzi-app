import 'dart:math' as math;
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/features/bills/screen/bill_detail_screen.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class RequestSuccessScreen extends StatelessWidget {
  final String? billId;
  const RequestSuccessScreen({super.key, this.billId});

  static const _purple = AppColors.primaryColor;
  static const _textDark = AppColors.textDark;
  static const _textGrey = AppColors.textMid;
  static const _cardBg = AppColors.primary50;
  static const _infoBg = AppColors.primary100;
  static const _infoBorder = Color(0xFFF2F4F7);
  static const _bg = AppColors.background;
  static const _iconGrey = AppColors.textDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewButton(context),
              const SizedBox(height: 14),
              _backButton(context),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 52),

              _badgeIcon(),

              const SizedBox(height: 28),

              Text(
                'request.success.title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'request.success.subtitle'.tr,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              _whatHappensCard(),

              const SizedBox(height: 14),

              _infoBox(),

              // Extra space so content doesn't hide behind bottom buttons
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  // ── Badge Icon ──
  Widget _badgeIcon() {
    return SizedBox(
      width: 110,
      height: 110,
      child: CustomPaint(
        painter: _BadgePainter(color: _purple),
        child: const Center(
          child: Icon(Icons.check, color: Colors.white, size: 44),
        ),
      ),
    );
  }

  // ── What Happens Now Card ──
  Widget _whatHappensCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _infoBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'request.success.what_happens'.tr,
            style: TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _stepItem(
            icon: Icons.fact_check_outlined,
            title: 'request.success.step1'.tr,
            subtitle: 'request.success.step1_desc'.tr,
          ),
          _stepItem(
            icon: Icons.handshake_outlined,
            title: 'request.success.step2'.tr,
            subtitle: 'request.success.step2_desc'.tr,
          ),
          _stepItem(
            icon: Icons.description_outlined,
            title: 'request.success.step3'.tr,
            subtitle: 'request.success.step3_desc'.tr,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _stepItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 8 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _infoBorder, width: 1),
            ),
            child: Icon(icon, color: _iconGrey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Box ──
  Widget _infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _infoBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _infoBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _infoBorder),
            ),
            child: const Icon(Icons.info_outline, color: _purple, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'request.success.info_title'.tr,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'request.success.info_desc'.tr,
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Buttons ──
  Widget _viewButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          final id = billId ?? Get.arguments as String?;
          if (id != null) {
            // Inside the request tab, not on top of the shell: the detail
            // keeps the bottom bar, and what it leads on to — the signing
            // screen, the service details — lands on the same tab.
            NavHelper.openInTab(NavTabs.request, BillDetailScreen(billId: id));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          'request.success.view_request'.tr,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          // Switch to home tab and refresh dashboard to show updated savings
          if (Get.isRegistered<NavbarController>()) {
            Get.find<NavbarController>().changeIndex(0);
          }
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().fetchDashboard();
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: _textDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'request.success.back_home'.tr,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Badge / Seal Shape Painter
// ─────────────────────────────────────────────
class _BadgePainter extends CustomPainter {
  final Color color;
  const _BadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.78;
    const points = 16;
    final angleStep = (math.pi * 2) / points;

    final path = Path();
    for (int i = 0; i < points; i++) {
      final outerAngle = i * angleStep - math.pi / 2;
      final innerAngle = outerAngle + angleStep / 2;
      final ox = cx + outerR * _cos(outerAngle);
      final oy = cy + outerR * _sin(outerAngle);
      final ix = cx + innerR * _cos(innerAngle);
      final iy = cy + innerR * _sin(innerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_BadgePainter old) => old.color != color;
}
