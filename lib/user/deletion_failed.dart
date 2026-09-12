import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeletionFailedScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onContactAdmin;
  final VoidCallback? onBackToSettings;
  final String roomNumber;

  const DeletionFailedScreen({
    super.key,
    this.onBack,
    this.onContactAdmin,
    this.onBackToSettings,
    this.roomNumber = 'A301',
  });

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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SvgPicture.asset(
                      'assets/images/Deletion.svg',
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ยังไม่สามารถปิดบัญชีได้',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 13,
                          color: Color(0xFF888888),
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'คุณยังมีสถานะเป็นผู้เช่า\n'),
                          const TextSpan(text: 'ห้อง '),
                          TextSpan(
                            text: roomNumber,
                            style: const TextStyle(
                              color: Color(0xFF4181CB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                              text:
                                  '\nกรุณาติดต่อแอดมินเพื่อดำเนินการ\nย้ายออกก่อน'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onContactAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF78A2D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ติดต่อแอดมิน',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onBackToSettings ?? onBack,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF78A2D2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'กลับไปหน้าตั้งค่า',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      color: Color(0xFF78A2D2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
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
        ],
      ),
    );
  }
}
