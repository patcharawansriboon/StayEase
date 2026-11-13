import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';

import '../widgets/app_sizes.dart';
import '../widgets/keyboard_safe_scroll.dart';

/// หน้า "ลืมรหัสผ่าน" (ตัวเลือก C — ยืนยันด้วยเบอร์ + ชื่อ-นามสกุล)
/// ผู้เช่าทำเองได้ ไม่ต้องใช้ OTP/อีเมล
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// เรียกเมื่อรีเซ็ตรหัสผ่านสำเร็จ → กลับไปหน้าเข้าสู่ระบบ
  final VoidCallback? onSuccess;

  const ForgotPasswordScreen({super.key, this.onBack, this.onSuccess});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final pw = _newPasswordController.text;
    final cf = _confirmPasswordController.text;
    return phone.length == 10 && name.isNotEmpty && pw.length >= 6 && pw == cf;
  }

  Future<void> _submit() async {
    if (!_canSubmit || _loading) return;
    setState(() => _loading = true);

    final result = await AuthService().resetPasswordByIdentity(
      phone: _phoneController.text.trim(),
      fullName: _nameController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ตั้งรหัสผ่านใหม่สำเร็จ กรุณาเข้าสู่ระบบอีกครั้ง',
            style: TextStyle(fontFamily: 'Noto Sans Thai'),
          ),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      widget.onSuccess?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ?? 'รีเซ็ตรหัสผ่านไม่สำเร็จ',
            style: const TextStyle(fontFamily: 'Noto Sans Thai'),
          ),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: KeyboardSafeScroll(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              content: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/reset_password.svg',
                    width: 110,
                    height: 110,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ลืมรหัสผ่าน',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ยืนยันตัวตนด้วยเบอร์โทรและชื่อ-นามสกุล\nที่ลงทะเบียนไว้ เพื่อตั้งรหัสผ่านใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.35),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildLabel('เบอร์โทรศัพท์'),
                  _buildField(
                    controller: _phoneController,
                    hint: 'กรอกเบอร์โทรที่ลงทะเบียน',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('ชื่อ-นามสกุล'),
                  _buildField(
                    controller: _nameController,
                    hint: 'กรอกชื่อ-นามสกุลที่ลงทะเบียน',
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('รหัสผ่านใหม่'),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('ยืนยันรหัสผ่านใหม่'),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  if (_confirmPasswordController.text.isNotEmpty &&
                      _newPasswordController.text !=
                          _confirmPasswordController.text) ...[
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'รหัสผ่านไม่ตรงกัน',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              bottom: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_canSubmit && !_loading) ? _submit : null,
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
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ตั้งรหัสผ่านใหม่',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                'ลืมรหัสผ่าน',
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

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 13,
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 14,
          color: Color(0xFF000000),
        ),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            color: Color(0xFFD9D9D9),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 14,
          color: Color(0xFF000000),
        ),
        decoration: InputDecoration(
          hintText: 'กรุณากรอกรหัสผ่าน',
          hintStyle: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            color: Color(0xFFD9D9D9),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFFAAAAAA),
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
