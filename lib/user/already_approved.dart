import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    return Column(
      children: [
        // ---- Illustration ----
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SvgPicture.asset(
                isApproved ? 'assets/images/Celebrat.svg' : 'assets/images/time.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // ---- กรอบสีฟ้า ----
        // ใช้ minHeight แทนความสูงตายตัว เพราะข้อความกรณีปฏิเสธมี 3 บรรทัด
        // (กรณีอนุมัติมี 2 บรรทัด) ถ้ากำหนด height ตายตัวจะล้นกรอบ
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 322),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFBCDEFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isApproved ? 'อนุมัติเรียบร้อย' : 'ปฏิเสธคำขอ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFEFFAF),
                    ),
                  ),
                  const SizedBox(height: 60),
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
                          fontFamily: 'Prompt',
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
          ),
        ),
      ],
    );
  }
}
