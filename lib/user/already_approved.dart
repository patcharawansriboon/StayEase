import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AlreadyApprovedScreen extends StatelessWidget {
  final VoidCallback onPressed;

  const AlreadyApprovedScreen({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- Illustration ----
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SvgPicture.asset(
                  'assets/images/Celebrat.svg',
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
              color: Color(0xFFBCDEFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 48),
              child: Column(
                children: [
                  const Text(
                    'ได้รับการอนุมัติแล้ว',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFEFFAF),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'คำขอเข้าหอพักของคุณได้รับการอนุมัติ\nคุณสามารถเริ่มต้นใช้งานแอปได้แล้ว',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                      child: const Text(
                        'เข้าสู่แอป',
                        style: TextStyle(
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
