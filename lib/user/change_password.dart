import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/app_sizes.dart';
import '../widgets/keyboard_safe_scroll.dart';

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// ส่งรหัสผ่านเดิมที่กรอกออกไปให้ขั้นถัดไป
  final ValueChanged<String>? onContinue;
  final VoidCallback? onForgotPassword;

  const ChangePasswordScreen({
    super.key,
    this.onBack,
    this.onContinue,
    this.onForgotPassword,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: KeyboardSafeScroll(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                content: Column(
                  children: [
                    // Lock icon
                    SvgPicture.asset(
                      'assets/images/reset_password.svg',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'ยืนยันรหัสผ่านเดิม',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'เพื่อความปลอดภัย กรุณากรอกรหัสผ่าน\nปัจจุบันของคุณก่อน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.35),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // รหัสผ่านเดิม label
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'รหัสผ่านเดิม',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 13,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD9D9D9),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                        decoration: InputDecoration(
                          hintText: 'กรุณากรอกรหัสผ่าน',
                          hintStyle: const TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 15,
                            color: Color(0xFFD9D9D9),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFAAAAAA),
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ลืมรหัสผ่าน
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: widget.onForgotPassword,
                        child: const Text(
                          'ลืมรหัสผ่าน',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 13,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                bottom: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _passwordController,
                    builder: (context, value, _) {
                      final isValid = value.text.isNotEmpty;
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isValid
                              ? () => widget.onContinue?.call(
                                  _passwordController.text,
                                )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F8FDB),
                            disabledBackgroundColor: const Color(
                              0xFF4F8FDB,
                            ).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ดำเนินการต่อ',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
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
            onTap: widget.onBack,
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'เปลี่ยนรหัสผ่าน',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
                  fontWeight: FontWeight.w600,
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
