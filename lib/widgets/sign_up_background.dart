import 'dart:math' as math;

import 'package:flutter/material.dart';

/// พื้นหลังสำหรับหน้า sign up
/// พื้นสีฟ้าอ่อนมาก ไล่เฉดเล็กน้อย พร้อมวงกลมขอบคลื่นสีเหลือง (FFE27F) และฟ้าตกแต่ง
class SignUpBackground extends StatelessWidget {
  final Widget child;

  /// แสดงวงกลมสีฟ้าที่อยู่ด้านซ้าย (ปิดได้สำหรับบางหน้า)
  final bool showLeftBlueCircle;

  /// แสดงวงกลมสีฟ้าเล็กด้านบน (ใกล้หัวข้อ) ปิดได้สำหรับบางหน้า
  final bool showTopBlueCircle;

  /// โหมดเรียบ: เหลือวงกลมแค่ 2 วง (เหลืองมุมซ้ายบน + ฟ้ามุมขวาล่าง)
  final bool minimal;

  /// สีพื้นแบบเรียบ (ไม่ไล่เฉด) เช่น Colors.white — null = ใช้ไล่เฉดฟ้าอ่อนมาก
  final Color? solidColor;

  const SignUpBackground({
    super.key,
    required this.child,
    this.showLeftBlueCircle = true,
    this.showTopBlueCircle = true,
    this.minimal = false,
    this.solidColor,
  });

  static const Color yellow = Color(0xFFFFE27F);
  static const Color blue = Color(0xFFBCDEFB);
  static const Color blueMid = Color(0xFF8CBFEF); // ฟ้าเข้มขึ้น (ใช้กับวงกลม)
  static const Color blueTop = Color(0xFFF9FCFF); // ฟ้าอ่อนมาก (บน)
  static const Color blueBottom = Color(0xFFFEFEFF); // ฟ้าอ่อนมาก (ล่าง)

  @override
  Widget build(BuildContext context) {
    // Scaffold ย่อพื้นที่หน้าตามแป้นพิมพ์ ถ้าพื้นหลังสูงตามพื้นที่นั้น วงกลมที่ยึดขอบล่างจะลอยขึ้นมา
    // จึงให้ตัวพื้นหลังสูงเท่าความสูงจอเสมอ (ส่วนที่เกินจะถูกแป้นพิมพ์บัง)
    // ส่วน child (ฟอร์ม) ยังย่อตามแป้นพิมพ์ตามเดิม
    final screenHeight = MediaQuery.sizeOf(context).height;
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: screenHeight,
              maxHeight: screenHeight,
              child: _buildBackdrop(),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// ฉากหลัง: สีพื้น/ไล่เฉด + วงกลมตกแต่ง (ไม่รวม child)
  Widget _buildBackdrop() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // ถ้ากำหนด solidColor ใช้สีเดียว มิฉะนั้นใช้ไล่เฉดฟ้าอ่อนมาก
        color: solidColor,
        gradient: solidColor != null
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [blueTop, blueBottom],
              ),
      ),
      child: Stack(
        children: [
          // วงกลมตกแต่ง (ไม่รับการแตะ)
          Positioned(
            top: -50,
            left: -40,
            child: _circle(170, yellow.withValues(alpha: 0.85)),
          ),
          if (!minimal)
            Positioned(
              top: 150,
              right: -60,
              child: _circle(130, yellow.withValues(alpha: 0.55)),
            ),
          if (!minimal)
            Positioned(
              bottom: 90,
              left: -45,
              child: _circle(110, yellow.withValues(alpha: 0.5)),
            ),
          if (showTopBlueCircle && !minimal)
            Positioned(
              top: 40,
              right: 70,
              child: _circle(70, blue.withValues(alpha: 0.8)),
            ),
          if (showLeftBlueCircle && !minimal)
            Positioned(
              top: 330,
              left: -70,
              child: _circle(150, blue.withValues(alpha: 0.6)),
            ),
          Positioned(
            bottom: -70,
            right: -50,
            child: _circle(200, blueMid.withValues(alpha: 0.5)),
          ),
          if (!minimal)
            Positioned(
              bottom: 160,
              right: -30,
              child: _circle(80, blue.withValues(alpha: 0.7)),
            ),
        ],
      ),
    );
  }

  /// วงกลมขอบเป็นคลื่น: [waves] = จำนวนลอน, [amplitude] = ความลึกของลอน
  Widget _circle(
    double size,
    Color color, {
    int waves = 4,
    double amplitude = 0.15,
  }) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(size, size),
        painter: _WavyCirclePainter(
          color: color,
          waves: waves,
          amplitude: amplitude,
        ),
      ),
    );
  }
}

/// วาดวงกลมที่ขอบเป็นคลื่นด้วย r = R * (1 + amplitude * sin(waves * θ))
class _WavyCirclePainter extends CustomPainter {
  final Color color;
  final int waves;
  final double amplitude;

  const _WavyCirclePainter({
    required this.color,
    required this.waves,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // เผื่อที่ให้ลอนไม่ล้นกรอบ
    final baseRadius = size.width / 2 / (1 + amplitude);
    const steps = 360; // จุดมากพอให้คลื่นถี่ยังโค้งเนียน

    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final theta = 2 * math.pi * i / steps;
      final r = baseRadius * (1 + amplitude * math.sin(waves * theta));
      final point = Offset(
        center.dx + r * math.cos(theta),
        center.dy + r * math.sin(theta),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavyCirclePainter old) =>
      old.color != color || old.waves != waves || old.amplitude != amplitude;
}
