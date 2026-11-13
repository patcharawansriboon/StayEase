import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/sign_up_background.dart';

enum ApprovalResult { approved, rejected }

class AlreadyApprovedScreen extends StatelessWidget {
  final VoidCallback onPressed;
  final ApprovalResult result;

  const AlreadyApprovedScreen({
    super.key,
    required this.onPressed,
    this.result = ApprovalResult.approved,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = result == ApprovalResult.approved;

    return SignUpBackground(
      minimal: true,
      solidColor: Colors.white,
      child: Column(
        children: [
          // ---- Illustration ----
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SvgPicture.asset(
                  isApproved
                      ? 'assets/images/smile.svg'
                      : 'assets/images/time.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ---- ข้อความสถานะ (ไม่มีกรอบสีฟ้าแล้ว) ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isApproved ? 'อนุมัติเรียบร้อย' : 'ปฏิเสธคำขอ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    // เดิมเป็นเหลืองอ่อนบนกรอบฟ้า → เปลี่ยนเป็นน้ำเงินให้อ่านได้บนพื้นขาว
                    color: Color(0xFF4F8FDB),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isApproved
                      ? 'คำขอเข้าหอพักของคุณได้รับการอนุมัติ\nคุณสามารถเข้าใช้งานแอปได้แล้ว'
                      : 'คำขอเข้าหอพักของคุณได้รับการปฏิเสธ\nคุณไม่สามารถเข้าใช้งานแอปได้\nกรุณาติดต่อแอดมิน',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: onPressed,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5B93D4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isApproved ? 'เข้าสู่แอป' : 'กลับหน้าสมัคร',
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
