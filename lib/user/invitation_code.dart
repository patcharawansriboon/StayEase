import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class InvitationCodeScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const InvitationCodeScreen({super.key, this.onBack});

  @override
  State<InvitationCodeScreen> createState() => _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends State<InvitationCodeScreen> {
  String _code = 'ABCD12';

  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    setState(() {
      _code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกรหัสแล้ว'),
        duration: Duration(seconds: 1),
      ),
    );
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
                      'assets/images/invitation_code.svg',
                      width: 280,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'สร้างรหัสเชิญเพื่อให้ผู้พักอาศัยเข้าร่วมห้องของคุณ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        children: const [
                          TextSpan(text: 'รหัสเชิญจะผูกกับ'),
                          TextSpan(
                            text: 'ห้อง 301',
                            style: TextStyle(color: Color(0xFF78A2D2)),
                          ),
                          TextSpan(text: ' โดยอัตโนมัติ'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Code box
                    Container(
                      width: double.infinity,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              _code,
                              style: const TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: _copyCode,
                              child: const Icon(
                                Icons.copy_outlined,
                                size: 20,
                                color: Color(0xFF78A2D2),
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

            // สร้างใหม่ button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _generateCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF78A2D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'สร้างใหม่',
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
                'สร้างรหัสเชิญ Roommate',
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
