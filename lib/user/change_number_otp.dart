import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class OtpScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onConfirm;

  const OtpScreen({super.key, this.onBack, this.onConfirm});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _timerText {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _isOtpComplete() {
    return _controllers.every((c) => c.text.isNotEmpty);
  }

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'กรอกรหัส OTP',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _buildOtpBox(i)),
                    ),
                    const SizedBox(height: 16),

                    // Timer
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                          children: [
                            const TextSpan(text: 'รหัสจะหมดอายุใน '),
                            TextSpan(
                              text: _timerText,
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: ' นาที'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Resend
                    Center(
                      child: GestureDetector(
                        onTap: _startTimer,
                        child: const Text(
                          'ส่งรหัส OTP อีกครั้ง',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ยืนยัน button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isOtpComplete() ? widget.onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8FDB),
                    disabledBackgroundColor: const Color(0xFF4F8FDB).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ยืนยัน',
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

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD9D9D9), width: 1),  // ← เพิ่ม D9D9D9
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD9D9D9), width: 1),  // ← เพิ่ม D9D9D9
        ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4F8FDB), width: 1.5),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto navigate when all 6 digits filled
          if (_isOtpComplete()) {
            widget.onConfirm?.call();
          }
        },
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
            child: const Icon(Icons.chevron_left, size: 24),
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
