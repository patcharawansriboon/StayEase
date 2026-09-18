import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ParticipateScreen extends StatelessWidget {
  final VoidCallback? onJoinWithCode;
  final VoidCallback? onRegisterAsTenant;

  const ParticipateScreen({
    super.key,
    this.onJoinWithCode,
    this.onRegisterAsTenant,
  });

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
            const SizedBox(height: 60),
            const Spacer(),
            // Illustration
            SvgPicture.asset(
              'assets/images/participate.svg',
              width: 260,
              height: 260,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'คุณยังไม่ได้เข้าร่วมกับห้องพักได',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'หากได้รับรหัสเชิญจากผู้เช่าหลัก\nสามารถกรอกรหัสเพื่อเข้าร่วมได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 15,
                color: Colors.black.withValues(alpha: 0.45),
                height: 1.5,
              ),
            ),
            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // เข้าร่วมด้วยรหัสเชิญ
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onJoinWithCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F8FDB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'เข้าร่วมด้วยด้วยรหัสเชิญ',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // สมัครเป็นผู้เช่าหลัก
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: onRegisterAsTenant,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F8FDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'สมัครเป็นผู้เช่าหลัก',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          color: Color(0xFF4F8FDB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
