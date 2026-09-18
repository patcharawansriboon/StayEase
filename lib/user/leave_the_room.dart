import 'package:flutter/material.dart';

class LeaveTheRoomScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onConfirmLeave;

  const LeaveTheRoomScreen({
    super.key,
    this.onBack,
    this.onConfirmLeave,
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
            const Spacer(),
            // Message
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'คุณต้องการออกจากห้อง A301 ใช่หรือไม่?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'หลังออกจากห้องคุณจะไม่สามารถเข้าถึงข้อมูล\nของห้องนี้ได้อีก',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // ยืนยันออกจากห้อง
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onConfirmLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF16C6C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ยืนยันออกจากห้อง',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ยกเลิก
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F8FDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิก',
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
                'ออกจากห้อง',
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
