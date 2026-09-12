import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const PrivacyPolicyScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.35, 0.6, 1.0],
            colors: [
              Color(0xFFEAF2FB),
              Color(0xFFBFD9F2),
              Color(0xFFCFE0F0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // Hero card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78A2D2).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/images/lock_shield.svg',
                            width: 67,
                            height: 73,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'เราใส่ใจ',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                const Text(
                                  'ความเป็นส่วนตัวของคุณ',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'StayEase ให้ความสำคัญกับทุกการคุ้มครองข้อมูลส่วนบุคคลเสมอ',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 14,
                                    color: Color(0xFF555555),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Policy items card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildPolicyItem(
                            icon: Icons.person_outline,
                            title: 'การใช้ข้อมูลของคุณ',
                            detail:
                                'เราใช้ข้อมูลของคุณเพื่อให้บริการ จัดการบัญชีการเช่า การชำระเงิน การแจ้งซ่อม และการสื่อสารที่เกี่ยวข้อง',
                          ),
                          const SizedBox(height: 20),
                          _buildPolicyItem(
                            icon: Icons.lock_outline,
                            title: 'การรักษาความปลอดภัย',
                            detail:
                                'เราจะดูแลข้อมูลของคุณอย่างเหมาะสมและจะไม่เปิดเผยข้อมูลโดยไม่ได้รับอนุญาต เว้นแต่จำเป็นต่อการให้บริการหรือเป็นไปตามกฎหมาย',
                          ),
                          const SizedBox(height: 20),
                          _buildPolicyItem(
                            icon: Icons.person_outline,
                            title: 'สิทธิของคุณ',
                            detail:
                                'คุณสามารถขอแก้ไขหรือลบข้อมูลส่วนบุคคลของคุณได้ตามกฎหมาย',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF78A2D2)),
        ),
        const SizedBox(width: 12),
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
                detail,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 14,
                  color: Color(0xFF555555),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'นโยบายความเป็นส่วนตัว',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
