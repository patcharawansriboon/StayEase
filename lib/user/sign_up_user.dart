import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/sign_up_background.dart';
import 'package:flutter/services.dart';

import '../widgets/app_sizes.dart';

class SignUpUserScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNavigateToSignIn;
  final void Function(Map<String, dynamic> data)? onNavigateToVerify;
  final ValueChanged<bool>? onInviteCodeChanged;
  final void Function(String name, String phone)? onUserDataChanged;
  final bool isAdmin;
  final void Function(String name, String phone)? onSignUpAdmin;

  const SignUpUserScreen({
    super.key,
    required this.onBack,
    required this.onNavigateToSignIn,
    this.onNavigateToVerify,
    this.onInviteCodeChanged,
    this.onUserDataChanged,
    this.isAdmin = false,
    this.onSignUpAdmin,
  });

  @override
  State<SignUpUserScreen> createState() => _SignUpUserScreenState();
}

class _SignUpUserScreenState extends State<SignUpUserScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dormCodeController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _inviteCodeController = TextEditingController();
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
    _dormCodeController.dispose();
    _roomNumberController.dispose();
    _inviteCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignUpBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // รูปหดตามพื้นที่ที่เหลือ (แป้นพิมพ์ขึ้นแล้วพื้นที่แคบ รูปจะเล็กลง/หายไป ฟอร์มได้พื้นที่ก่อน)
          final imageScale = ((constraints.maxHeight - 48 - 380) / 196)
              .clamp(0.0, 1.0)
              .toDouble();
          return Column(
            children: [
              // ---- ปุ่มย้อนกลับ ----
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chevron_left,
                        size: kBackIconSize,
                        color: Color(0xFF1A1A2E),
                      ),
                      onPressed: widget.onBack,
                    ),
                  ],
                ),
              ),

              // ---- Illustration ----
              if (imageScale > 0.02)
                Align(
                  alignment: Alignment.center, // ชิดขวา -> กลาง
                  // ครอปพื้นที่ขาวด้านล่างของรูปออก เพื่อให้การ์ดสีฟ้าอยู่ใกล้รูป
                  child: SizedBox(
                    width: 270 * imageScale,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 0.8,
                        child: Image.asset(
                          'assets/images/sign_up2.png',
                          height: 245 * imageScale,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

              // ---- กรอบสีน้ำเงิน: Form ----
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ), // เว้นระยะจากขอบจอ
                  clipBehavior:
                      Clip.antiAlias, // ตัดเนื้อหาที่เลื่อนให้อยู่ในรูปทรง card
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 28, 12, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // หัวข้อ
                        const Text(
                          'สมัครสมาชิก',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A3282),
                          ),
                        ),
                        const SizedBox(height: 16),

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

                        if (!widget.isAdmin) ...[
                          // รหัสหอพัก
                          _buildLabel('รหัสหอพัก'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _dormCodeController,
                            hint: 'กรุณากรอกรหัสหอพัก',
                          ),
                          const SizedBox(height: 16),

                          // เลขห้อง
                          Row(
                            children: [
                              _buildLabel('เลขห้อง'),
                              const SizedBox(width: 6),
                              Text(
                                '(ถ้าทราบ)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(
                                    0xFF000000,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _roomNumberController,
                            hint: 'กรุณากรอกเลขห้อง',
                          ),
                          const SizedBox(height: 16),

                          // รหัสคำเชิญ (สำหรับ Roommate)
                          Row(
                            children: [
                              _buildLabel('รหัสคำเชิญ'),
                              const SizedBox(width: 6),
                              Text(
                                '(สำหรับ Roommate)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(
                                    0xFF000000,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _inviteCodeController,
                            hint: 'กรุณากรอกรหัสคำเชิญ',
                          ),
                          const SizedBox(height: 16),
                        ],

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
                              () => _obscurePassword = !_obscurePassword,
                            ),
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
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ปุ่มสมัครใช้งาน
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton(
                            onPressed: () async {
                              // ตรวจรหัสผ่านตรงกัน
                              if (_passwordController.text !=
                                  _confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน',
                                      style: TextStyle(
                                        fontFamily: 'Noto Sans Thai',
                                      ),
                                    ),
                                    backgroundColor: Color(0xFFFF0303),
                                  ),
                                );
                                return;
                              }
                              if (widget.isAdmin) {
                                final success = await AuthService().signUpAdmin(
                                  phone: _phoneController.text,
                                  password: _passwordController.text,
                                  fullName: _nameController.text,
                                );
                                if (success) {
                                  widget.onInviteCodeChanged?.call(false);
                                  widget.onUserDataChanged?.call(
                                    _nameController.text,
                                    _phoneController.text,
                                  );
                                  widget.onNavigateToVerify?.call({
                                    'phone': _phoneController.text,
                                    'name': _nameController.text,
                                    'isAdmin': true,
                                  });
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'ลงทะเบียนไม่สำเร็จ กรุณาลองอีกครั้ง',
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans Thai',
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFFFF0303),
                                    ),
                                  );
                                }
                              } else {
                                widget.onInviteCodeChanged?.call(
                                  _inviteCodeController.text.isNotEmpty,
                                );
                                widget.onUserDataChanged?.call(
                                  _nameController.text,
                                  _phoneController.text,
                                );
                                bool success = false;
                                String errorMessage = '';
                                if (_inviteCodeController.text.isNotEmpty) {
                                  success = await AuthService().signUpRoommate(
                                    phone: _phoneController.text,
                                    password: _passwordController.text,
                                    fullName: _nameController.text,
                                    inviteCode: _inviteCodeController.text,
                                    onError: (msg) => errorMessage = msg,
                                  );
                                } else {
                                  success = await AuthService().signUpTenant(
                                    phone: _phoneController.text,
                                    password: _passwordController.text,
                                    fullName: _nameController.text,
                                    dormCode: _dormCodeController.text,
                                    roomNumber: _roomNumberController.text,
                                    onError: (msg) => errorMessage = msg,
                                  );
                                }
                                if (success) {
                                  widget.onNavigateToVerify?.call({
                                    'phone': _phoneController.text,
                                    'name': _nameController.text,
                                    'isRoommate':
                                        _inviteCodeController.text.isNotEmpty,
                                    'inviteCode': _inviteCodeController.text,
                                    'dormCode': _dormCodeController.text,
                                    'roomNumber': _roomNumberController.text,
                                  });
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        errorMessage.isNotEmpty
                                            ? errorMessage
                                            : 'ลงทะเบียนไม่สำเร็จ กรุณาลองอีกครั้ง',
                                        style: const TextStyle(
                                          fontFamily: 'Noto Sans Thai',
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFFFF0303),
                                    ),
                                  );
                                }
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
                                fontFamily: 'Noto Sans Thai',
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
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 14,
                                color: Color(0xFF000000),
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onNavigateToSignIn,
                              child: const Text(
                                'เข้าสู่ระบบ',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Thai',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4181CB),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF4181CB),
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
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Noto Sans Thai',
        fontSize: 14,
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
    Color borderColor;
    if (hasError == true) {
      borderColor = const Color(0xFFFF0303);
    } else {
      borderColor = const Color(0xFFD9D9D9);
    }

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
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
