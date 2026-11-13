import 'package:flutter/material.dart';

import '../widgets/app_sizes.dart';
class ContactUsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const ContactUsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                      height: 170,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8FDB).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'เราพร้อมช่วยเหลือคุณ!',
                                  style: TextStyle(
                                    fontFamily: 'Noto Sans Thai',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'หากคุณพบปัญหาหรือ\nมีข้อสงสัย สามารถติดต่อเรา\nได้ผ่านช่องทางด้านล่าง',
                                  style: TextStyle(
                                    fontFamily: 'Noto Sans Thai',
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Mascot
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: SizedBox(
                            width: 109,
                            height: 100,
                            child: OverflowBox(
                              maxHeight: 147,
                              child: Image.asset(
                                'assets/images/contact_us.png',
                                width: 109,
                                height: 147,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ช่องทางการติดต่อ label
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ช่องทางการติดต่อ',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // LINE
                    _buildContactCard(
                      iconColor: const Color(0xFF06C755),
                      iconData: Icons.chat_bubble,
                      label: 'LINE',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),

                    // Facebook
                    _buildContactCard(
                      iconColor: const Color(0xFF1877F2),
                      iconData: Icons.facebook,
                      label: 'Facebook',
                      onTap: () {},
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

  Widget _buildContactCard({
    required Color iconColor,
    required IconData iconData,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
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
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ติดต่อเรา',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
              fontWeight: FontWeight.w600,
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
