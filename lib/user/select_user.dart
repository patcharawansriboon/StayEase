import 'package:flutter/material.dart';

class SelectUserScreen extends StatelessWidget {
  final VoidCallback onSelectTenant;
  final VoidCallback? onSelectAdmin;
  final VoidCallback? onSignIn;

  const SelectUserScreen({
    super.key,
    required this.onSelectTenant,
    this.onSelectAdmin,
    this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ลวดลายวงกลมสีเหลืองมุมล่าง
          Positioned(
            left: -40,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -50,
            bottom: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // โลโก้
                  Image.asset(
                    'assets/images/logo.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 24),

                  // หัวข้อต้อนรับ
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                      children: const [
                        TextSpan(text: 'ยินดีต้อนรับสู่ '),
                        TextSpan(
                          text: 'StayEase',
                          style: TextStyle(color: Color(0xFF4181CB)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'จัดการหอพักของคุณได้ง่ายขึ้น\nในที่เดียว',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ปุ่มสมัครสำหรับแอดมิน (ปุ่มทึบสีฟ้า)
                  _buildButton(
                    label: 'สมัครใช้งานสำหรับแอดมิน',
                    filled: true,
                    onTap: onSelectAdmin ?? () {},
                  ),
                  const SizedBox(height: 14),

                  // ปุ่มสมัครสำหรับผู้เช่า (ปุ่มขอบ)
                  _buildButton(
                    label: 'สมัครใช้งานสำหรับผู้เช่า',
                    filled: false,
                    onTap: onSelectTenant,
                  ),

                  const SizedBox(height: 24),

                  // มีบัญชีอยู่แล้ว?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'มีบัญชีอยู่แล้ว?  ',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      GestureDetector(
                        onTap: onSignIn,
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4181CB),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled ? const Color(0xFF5B93D4) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFCFE0F0)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 20,
              color: filled ? Colors.white : const Color(0xFF4181CB),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: filled ? Colors.white : const Color(0xFF4181CB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
