import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChangeNumberScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final VoidCallback? onNavigateToOtp;

  const ChangeNumberScreen({
    super.key,
    this.onBack,
    this.onCancel,
    this.onNavigateToOtp,
  });

  @override
  State<ChangeNumberScreen> createState() => _ChangeNumberScreenState();
}

class _ChangeNumberScreenState extends State<ChangeNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    // Phone verify icon
                    SvgPicture.asset(
                      'assets/images/phone-check.svg',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),

                    // ยืนยันตัวตน title
                    const Text(
                      'ยืนยันตัวตน',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'เพื่อความปลอดภัยของบัญชี\nกรุณายืนยันตัวตนก่อนเปลี่ยนเบอร์มือถือ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // เบอร์มือถือ label
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'เบอร์มือถือ',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 13,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Phone input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'กรุณากรอกเบอร์',
                          hintStyle: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 15,
                            color: Color(0xFFD9D9D9),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // รับรหัส OTP button
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _phoneController,
                    builder: (context, value, _) {
                      final isValid = value.text.length == 10;
                      return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isValid ? widget.onNavigateToOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF78A2D2),
                        disabledBackgroundColor: const Color(0xFF78A2D2).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'รับรหัส OTP',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                    },
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
            onTap: () {
              _phoneController.clear();
              widget.onBack?.call();
            },
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'เปลี่ยนเบอร์มือถือ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
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
