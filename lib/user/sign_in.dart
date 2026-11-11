import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/sign_up_background.dart';
import 'package:flutter/services.dart';

import '../widgets/app_sizes.dart';
class SignInScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(String name, String phone) onSignIn;
  final void Function(String name, String phone) onSignInAsAdmin;
  final VoidCallback? onForgotPassword;

  const SignInScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onSignInAsAdmin,
    this.onForgotPassword,
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
    return SignUpBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // การ์ดสูงสุด 496 แต่ไม่เกินพื้นที่ที่เหลือใต้ปุ่มย้อนกลับ
          // (ตอนแป้นพิมพ์ขึ้นพื้นที่จะน้อยลง → การ์ดหดและเลื่อนดูเนื้อหาได้ ไม่ overflow)
          final cardHeight = (constraints.maxHeight - kMinInteractiveDimension)
              .clamp(0.0, 496.0)
              .toDouble();
          return Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.chevron_left,
                      size: kBackIconSize,
                      color: Colors.black,
                    ),
                    onPressed: widget.onBack,
                  ),
                ),
              ),

              // รูปอยู่ในพื้นที่ว่างระหว่างปุ่มย้อนกลับกับ card
              // contain = เห็นทั้งรูป ไม่ถูกครอป และเว้นขอบรอบรูปให้ดูเล็กลง
              Expanded(
                // ซ้าย: ข้อความต้อนรับ (40%) / ขวา: รูปกว้าง 60% ชิดขวาและลงมาติดการ์ด
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Align(
                          // ซ้าย และลงมาต่ำกว่ากึ่งกลาง (-1,-1 = บนซ้าย / -1,1 = ล่างซ้าย)
                          alignment: const Alignment(-1.0, 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ยินดีต้อนรับ',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Thai',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0A3282),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 80,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE27F),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'เข้าสู่ระบบเพื่อเข้าใช้งาน\nStayEase กันเถอะ',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Thai',
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 16, 4),
                          child: Image.asset(
                            'assets/images/sign_in.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: cardHeight,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ), // เว้นระยะจากขอบจอ
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    // เลื่อนได้เมื่อพื้นที่ไม่พอ และเลื่อนช่องที่โฟกัสให้พ้นแป้นพิมพ์อัตโนมัติ
                    padding: const EdgeInsets.fromLTRB(12, 30, 12, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A3282),
                          ),
                        ),
                        const SizedBox(height: 34),

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
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: widget.onForgotPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 14,
                                color: Color(0xFF4F8FDB),
                              ),
                            ),
                          ),
),
                          const SizedBox(height: 16),

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
                              } else if (role == 'tenant' ||
                                  role == 'roommate') {
                                widget.onSignIn(name, phone);
                              } else if (role == 'error') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'เบอร์โทรศัพท์หรือรหัสผ่านไม่ถูกต้อง',
                                      style: TextStyle(
                                        fontFamily: 'Noto Sans Thai',
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFFFF0303),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ยังไม่พบบัญชีผู้ใช้นี้',
                                      style: TextStyle(
                                        fontFamily: 'Noto Sans Thai',
                                      ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.black),
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
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: Color(0xFF4F8FDB), width: 1.5),
        ),
      ),
    );
  }
}
