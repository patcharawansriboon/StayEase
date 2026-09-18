import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConfirmChangePasswordScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  const ConfirmChangePasswordScreen({
    super.key,
    this.onBack,
    this.onSave,
  });

  @override
  State<ConfirmChangePasswordScreen> createState() =>
      _ConfirmChangePasswordScreenState();
}

class _ConfirmChangePasswordScreenState
    extends State<ConfirmChangePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password strength: 0-3
  int _getStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    return score;
  }

  bool get _isPasswordMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  bool get _canSave =>
      _newPasswordController.text.length >= 6 && _isPasswordMatch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
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
                      'ตั้งรหัสผ่านใหม่',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'รหัสผ่านควรมีความปลอดภัย',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // รหัสผ่านใหม่
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'รหัสผ่านใหม่',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 13,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _newPasswordController,
                      builder: (context, newVal, _) {
                        final strength = _getStrength(newVal.text);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                 controller: _newPasswordController,
                                 obscureText: _obscureNew,
                                style: const TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 14,
                                  color: Color(0xFF000000),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'กรุณากรอกรหัสผ่าน',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 15,
                                    color: Color(0xFFD9D9D9),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNew
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFFAAAAAA),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureNew = !_obscureNew),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Strength bar
                            Row(
                              children: List.generate(3, (i) {
                                Color barColor;
                                if (newVal.text.isEmpty) {
                                  barColor = const Color(0xFFD9D9D9);
                                } else if (i < strength) {
                                  barColor = strength == 1
                                      ? Colors.red
                                      : strength == 2
                                          ? Colors.orange
                                          : Colors.green;
                                } else {
                                  barColor = const Color(0xFFD9D9D9);
                                }
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            if (newVal.text.isNotEmpty)
                              Text(
                                strength == 1
                                    ? 'ความปลอดภัยต่ำ'
                                    : strength == 2
                                        ? 'ความปลอดภัย'
                                        : 'ความปลอดภัยสูง',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 11,
                                  color: strength == 1
                                      ? Colors.red
                                      : strength == 2
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ยืนยันรหัสผ่านใหม่
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ยืนยันรหัสผ่านใหม่',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 13,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _confirmPasswordController,
                      builder: (context, confirmVal, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                 controller: _confirmPasswordController,
                                 obscureText: _obscureConfirm,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 14,
                                  color: Color(0xFF000000),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'กรุณากรอกรหัสผ่าน',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 15,
                                    color: Color(0xFFD9D9D9),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFFAAAAAA),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (confirmVal.text.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    _isPasswordMatch
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: _isPasswordMatch
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isPasswordMatch
                                        ? 'รหัสผ่านปลอดภัย'
                                        : 'รหัสผ่านไม่ตรงกัน',
                                    style: TextStyle(
                                      fontFamily: 'Prompt',
                                      fontSize: 11,
                                      color: _isPasswordMatch
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // บันทึก button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSave ? widget.onSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8FDB),
                    disabledBackgroundColor:
                        const Color(0xFF4F8FDB).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'บันทึก',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      color: Colors.white,
                    ),
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
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'เปลี่ยนรหัสผ่าน',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
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
