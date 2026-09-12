import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConfirmChangeNumberScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<String>? onSave;

  const ConfirmChangeNumberScreen({
    super.key,
    this.onBack,
    this.onSave,
  });

  @override
  State<ConfirmChangeNumberScreen> createState() =>
      _ConfirmChangeNumberScreenState();
}

class _ConfirmChangeNumberScreenState
    extends State<ConfirmChangeNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();

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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    // Icon
                    SvgPicture.asset(
                      'assets/images/phone-check.svg',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'กรอกเบอร์มือถือใหม่',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      'กรุณากรอกเบอร์มือถือที่ต้องการใช้',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // เบอร์มือถือใหม่ label
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'เบอร์มือถือใหม่',
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
                          hintText: '099-0000000',
                          hintStyle: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 14,
                            color: Color(0xFFAAAAAA),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78A2D2).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: const Color(0xFF78A2D2).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'เบอร์มือถือใหม่จะใช้สำหรับ\nเข้าสู่ระบบและรับการแจ้งเตือน',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 12,
                                color: Color(0xFF78A2D2),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _phoneController,
                  builder: (context, value, _) {
                    final isValid = value.text.length == 10;
                    return ElevatedButton(
                  onPressed: isValid
                      ? () => widget.onSave?.call(_phoneController.text)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF78A2D2),
                    disabledBackgroundColor: const Color(0xFF78A2D2).withValues(alpha: 0.4),
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
                );
                  },
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
                'เปลี่ยนเบอร์มือถือ',
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
