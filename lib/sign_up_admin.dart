import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

class SignUpAdminScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNavigateToSignIn;
  final void Function(String name, String phone)? onSignUp;

  const SignUpAdminScreen({
    super.key,
    required this.onBack,
    required this.onNavigateToSignIn,
    this.onSignUp,
  });

  @override
  State<SignUpAdminScreen> createState() => _SignUpAdminScreenState();
}

class _SignUpAdminScreenState extends State<SignUpAdminScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _phoneError = false;
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        setState(() {
          _phoneError = _phoneController.text.length != 10;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---- ปุ่มย้อนกลับ ----
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left,
                        size: 28, color: Color(0xFF1A1A2E)),
                    onPressed: widget.onBack,
                  ),
                ],
              ),
            ),

            // ---- Illustration ----
            SizedBox(
              width: 200,
              height: 160,
              child: SvgPicture.asset(
                'assets/images/Add-User.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),

            // ---- กรอบสีฟ้าอ่อน: Form ----
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFBCDCF5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อ-นามสกุล
                      _buildLabel('ชื่อ-นามสกุล'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'กรุณากรอกชื่อ-นามสกุล',
                      ),
                      const SizedBox(height: 16),

                      // เบอร์โทรศัพท์
                      Row(
                        children: [
                          _buildLabel('เบอร์โทรศัพท์'),
                          if (_phoneError)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                'กรุณากรอกเบอร์ให้ครบ',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 11,
                                  color: Color(0xFFFF0303),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'กรุณากรอกเบอร์โทรศัพท์',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        hasError: _phoneError,
                        focusNode: _phoneFocusNode,
                      ),
                      const SizedBox(height: 16),

                      // รหัสผ่าน
                      _buildLabel('รหัสผ่าน'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'กรุณากรอกรหัสผ่าน',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ยืนยันรหัสผ่าน
                      _buildLabel('ยืนยันรหัสผ่าน'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'กรุณากรอกรหัสผ่าน',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ปุ่มสมัครใช้งาน
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton(
                          onPressed: () async {
                            final success = await AuthService().signUpAdmin(
                              phone: _phoneController.text,
                              password: _passwordController.text,
                              fullName: _nameController.text,
                            );
                            if (success) {
                              widget.onSignUp?.call(
                                _nameController.text,
                                _phoneController.text,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF5B93D4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'สมัครใช้งาน',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // มีบัญชีอยู่แล้ว?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'มีบัญชีอยู่แล้ว?  ',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 14,
                              color: Color(0xFF444444),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToSignIn,
                            child: const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4181CB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Prompt',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF000000),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool? hasError,
    FocusNode? focusNode,
  }) {
    final borderColor = hasError == true
        ? const Color(0xFFFF0303)
        : const Color(0xFFE0E0E0);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      style: const TextStyle(
          fontFamily: 'Prompt', fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Prompt', fontSize: 14, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: hasError == true
                ? const Color(0xFFFF0303)
                : const Color(0xFF4F8FDB),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
