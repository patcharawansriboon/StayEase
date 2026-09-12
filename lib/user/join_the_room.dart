import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JoinTheRoomScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onJoin;

  const JoinTheRoomScreen({
    super.key,
    this.onBack,
    this.onJoin,
  });

  @override
  State<JoinTheRoomScreen> createState() => _JoinTheRoomScreenState();
}

class _JoinTheRoomScreenState extends State<JoinTheRoomScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    // Illustration
                    SvgPicture.asset(
                      'assets/images/join_the_room.svg',
                      width: 280,
                      height: 300,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => const Icon(
                        Icons.mail_outline,
                        size: 100,
                        color: Color(0xFF78A2D2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'กรอกรหัสเชิญที่ได้รับจากผู้เช่าหลัก',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ตัวอย่าง: ABC-DEF',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Code input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'กรุณากรอกรหัสเชิญ',
                          hintStyle: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 15,
                            color: Color(0xFFD9D9D9),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // เข้าร่วม button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _codeController,
                builder: (context, value, _) {
                  final isValid = value.text.trim().isNotEmpty;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isValid ? widget.onJoin : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF78A2D2),
                        disabledBackgroundColor:
                            const Color(0xFF78A2D2).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'เข้าร่วม',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
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
                'เข้าร่วมด้วยด้วยรหัสเชิญ',
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
