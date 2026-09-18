import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VerifyNumberScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onVerified;
  final String phoneNumber;

  const VerifyNumberScreen({
    super.key,
    required this.onBack,
    required this.onVerified,
    required this.phoneNumber,
  });

  @override
  State<VerifyNumberScreen> createState() => _VerifyNumberScreenState();
}

class _VerifyNumberScreenState extends State<VerifyNumberScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  Timer? _timer;
  bool _isOtpComplete = false;

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _checkOtpComplete() {
    final isComplete = _otpControllers.every((c) => c.text.length == 1);
    if (isComplete != _isOtpComplete) {
      setState(() {
        _isOtpComplete = isComplete;
      });
      if (isComplete) {
        widget.onVerified();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
    for (final controller in _otpControllers) {
      controller.addListener(_checkOtpComplete);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.removeListener(_checkOtpComplete);
      controller.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- ปุ่มย้อนกลับ + หัวข้อ ----
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 24.0, right: 16.0),
          child: SizedBox(
            height: 28,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Color(0xFF1A1A2E),
                    ),
                    onPressed: widget.onBack,
                  ),
                ),
                const Center(
                  child: Text(
                    'ยืนยันเบอร์โทรศัพท์',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ---- Illustration ----
        SizedBox(
          width: 245,
          height: 245,
          child: SvgPicture.asset(
            'assets/images/otp.svg',
            fit: BoxFit.contain,
          ),
        ),

        const Spacer(),

        // ---- กรอบสีน้ำเงิน: Form ----
        SizedBox(
          height: 351,
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
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'กรุณากรอกรหัส OTP ที่ส่งไปยัง\n+66 ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),

                  // OTP fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 42,
                        height: 50,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFBCDEFB),
                                width: 1.5,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.length == 1 && index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // ส่งรหัสอีกครั้ง
                  Text(
                    'รหัสจะหมดอายุใน ${_countdown ~/ 60}:${(_countdown % 60).toString().padLeft(2, '0')} นาที',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'ส่งรหัส OTP อีกครั้ง',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ปุ่มยืนยัน
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: _isOtpComplete ? widget.onVerified : null,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF5B93D4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'ยืนยัน',
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
