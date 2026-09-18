import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ApplyTenantScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onApply;

  const ApplyTenantScreen({
    super.key,
    this.onBack,
    this.onApply,
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    // Illustration
                    SvgPicture.asset(
                      'assets/images/apply.svg',
                      width: 280,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'สมัครเป็นผู้เช่าหลัก',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'กรอกข้อมูลและส่งคำขอให้ผู้ดูแลหอพัก\nตรวจสอบเพื่อเปิดห้องให้คุณ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.45),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ปุ่มสมัครผู้เช่าหลัก
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8FDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'สมัครผู้เช่าหลัก',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      color: Colors.white,
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
          const Expanded(
            child: Center(
              child: Text(
                'สมัครเป็นผู้เช่าหลัก',
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
