import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SendRequestScreen extends StatelessWidget {
  final VoidCallback onTap;

  const SendRequestScreen({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // ---- Illustration ----
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SvgPicture.asset(
                  'assets/images/time.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ---- กรอบสีน้ำเงิน ----
          SizedBox(
            height: 322,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF78A2D2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(32, 40, 32, 48),
                child: Column(
                  children: [
                    Text(
                      'ส่งคำขอเรียบร้อยแล้ว',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFEFFAF),
                      ),
                    ),
                    SizedBox(height: 60),
                    Text(
                      'หลังจากกรอกข้อมูลเพื่อส่งคำขอเข้าหอพัก\nระบบส่งคำขอกรุณารอแอดมินตรวจสอบและอนุมัติ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF000000),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
