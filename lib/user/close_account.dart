import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CloseAccountScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCloseAccount;

  const CloseAccountScreen({
    super.key,
    this.onBack,
    this.onCloseAccount,
  });

  @override
  State<CloseAccountScreen> createState() => _CloseAccountScreenState();
}

class _CloseAccountScreenState extends State<CloseAccountScreen> {
  bool _confirmed = false;

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
              Color(0xFFEAF2FB), // ฟ้าขาวนวลด้านบนซ้าย
              Color(0xFFBFD9F2), // ฟ้าพาสเทลกลาง
              Color(0xFFCFE0F0), // ฟ้าอมเทา
              Color(0xFFFFFFFF), // ขาวด้านล่างขวา
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    // Warning illustration
                    SvgPicture.asset(
                      'assets/images/warning.svg',
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'การปิดบัญชีเป็นการดำเนินการถาวร',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF16C6C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เมื่อปิดบัญชี คุณจะไม่สามารถ\nเข้าสู่ระบบ StayEase ได้อีก',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // สิ่งที่จะเกิดขึ้น card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78A2D2).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'สิ่งที่จะเกิดขึ้น',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBulletItem(
                            Icons.lock_outline,
                            'ไม่สามารถเข้าใช้งานบัญชีได้',
                          ),
                          const SizedBox(height: 10),
                          _buildBulletItem(
                            Icons.person_outline,
                            'ข้อมูลส่วนตัวจะถูกลบ',
                          ),
                          const SizedBox(height: 10),
                          _buildBulletItem(
                            Icons.article_outlined,
                            'ประวัติบางอย่างอาจไม่สามารถกู้คืนได้',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Checkbox (ขยับลงมาอยู่ใกล้กับปุ่มปิดบัญชี)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _confirmed = !_confirmed),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _confirmed
                            ? const Color(0xFFF16C6C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _confirmed
                              ? const Color(0xFFF16C6C)
                              : const Color(0xFFAAAAAA),
                        ),
                      ),
                      child: _confirmed
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ฉันเข้าใจและต้องการปิดบัญชี',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 13,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),

            // ปิดบัญชี button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmed ? widget.onCloseAccount : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF16C6C),
                    disabledBackgroundColor:
                        const Color(0xFFF16C6C).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ปิดบัญชี',
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

  Widget _buildBulletItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF78A2D2)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 12,
            color: Color(0xFF555555),
          ),
        ),
      ],
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
                'ปิดบัญชีการใช้งาน',
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
