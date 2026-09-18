import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(String name, String phone) onSignIn;
  final void Function(String name, String phone) onSignInAsAdmin;

  const SignInScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onSignInAsAdmin,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- ปุ่มย้อนกลับ ----
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.chevron_left,
                size: 24,
                color: Colors.black,
              ),
              onPressed: widget.onBack,
            ),
          ),
        ),

        // ---- Illustration ----
        SizedBox(
          width: 245,
          height: 245,
          child: SvgPicture.asset(
            'assets/images/login.svg',
            fit: BoxFit.contain,
          ),
        ),

        const Spacer(),

        // ---- กรอบสีฟ้าทึบ: Form ----
        SizedBox(
          height: 496,
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
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Back
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      color: const Color(0xFFFEFFAF),
                    ),
                  ),
                  const SizedBox(height: 34),

                  // เบอร์โทรศัพท์
                  _buildLabel('เบอร์โทรศัพท์'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'กรุณากรอกเบอร์โทรศัพท์',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 10),

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
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 70),

                  // ปุ่มเข้าสู่ระบบ
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () async {
                        final result = await AuthService().signIn(
                          phone: _phoneController.text,
                          password: _passwordController.text,
                        );
                        final role = result['role'] ?? '';
                        final name = result['full_name'] ?? '';
                        final phone = result['phone'] ?? '';
                        if (!mounted) return;
                        if (role == 'admin') {
                          widget.onSignInAsAdmin(name, phone);
                        } else if (role == 'tenant' || role == 'roommate') {
                          widget.onSignIn(name, phone);
                        } else if (role == 'error') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'เบอร์โทรศัพท์หรือรหัสผ่านไม่ถูกต้อง',
                                style: TextStyle(fontFamily: 'Prompt'),
                              ),
                              backgroundColor: const Color(0xFFFF0303),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ยังไม่พบบัญชีผู้ใช้นี้',
                                style: TextStyle(fontFamily: 'Prompt'),
                              ),
                              backgroundColor: const Color(0xFFFF0303),
                            ),
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
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ลืมรหัสผ่าน?
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'ลืมรหัสผ่าน?',
                        style: TextStyle(
                          fontSize: 13,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black,
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFBCDEFB), width: 1.5),
        ),
      ),
    );
  }
}
