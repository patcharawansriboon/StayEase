import 'package:flutter/material.dart';

class SelectDormitoryScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCreateDormitory;
  final VoidCallback? onJoinDormitory;

  const SelectDormitoryScreen({
    super.key,
    this.onBack,
    this.onCreateDormitory,
    this.onJoinDormitory,
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
                        fontFamily: 'Prompt',
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
                  const SizedBox(height: 12),
                  const Text(
                    'คุณต้องการใช้งานแบบไหน?',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      color: Color(0xFF666666),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // การ์ด สร้างหอพักใหม่
                  _buildOptionCard(
                    icon: Icons.add,
                    title: 'สร้างหอพักใหม่',
                    description: 'สำหรับเจ้าของหอพัก\nที่ต้องการเริ่มใช้งานระบบ',
                    onTap: onCreateDormitory,
                  ),
                  const SizedBox(height: 16),

                  // การ์ด เข้าร่วมหอพัก
                  _buildOptionCard(
                    icon: Icons.search,
                    title: 'เข้าร่วมหอพัก',
                    description: 'ใช้รหัสหอพักที่ได้รับ\nจากเจ้าของหอพัก',
                    onTap: onJoinDormitory,
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCFE0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF5B93D4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 12,
                      color: Color(0xFF999999),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 22, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
