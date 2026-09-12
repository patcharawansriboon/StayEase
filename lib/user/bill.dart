import 'package:flutter/material.dart';

class BillScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToPayment;

  const BillScreen({super.key, this.onBack, this.onNavigateToPayment});

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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _buildBillCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Header ----
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Bill Card ----
  Widget _buildBillCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF78A2D2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title section
          Column(
            children: const [
              Text(
                'บิลประจำเดือน',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFEFFAF),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'กรกฎาคม 2569',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // White inner card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // รายการค่าใช้จ่าย
                _buildBillRow('ค่าเช่าห้อง', '4,500.00', isBold: false),
                const SizedBox(height: 12),
                _buildBillRow('ค่าไฟ', '320.00', isBold: false),
                const SizedBox(height: 12),
                _buildBillRow('ค่าน้ำ', '270.00', isBold: false),
                const SizedBox(height: 12),
                _buildBillRow('ค่าปรับ / อื่นๆ', '00.00', isBold: false),
                const SizedBox(height: 12),

                // Divider
                const Divider(height: 1, color: Color(0xFFD9D9D9)),
                const SizedBox(height: 12),

                // รวมทั้งหมด
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'รวทั้งหมด',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '5,090.00',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'บาท',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Divider (0.5px)
                Container(height: 0.5, color: const Color(0xFFD9D9D9)),
                const SizedBox(height: 12),

                // ครบกำหนด
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'ครบกำหนด',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 10,
                        color: Color(0xFF000000),
                      ),
                    ),
                    Text(
                      '5 สิงหาคม 2569',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 10,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ช่องทางการชำระ
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ช่องทางการชำระ',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 10,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // QR PromptPay box
                Center(
                  child: GestureDetector(
                    onTap: onNavigateToPayment,
                    child: Container(
                    width: 75,
                    height: 75,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFFD9D9D9), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.qr_code_2,
                          size: 34,
                          color: Color(0xFF000000),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'QR PromptPay',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 8,
                            color: Color(0xFF000000),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String amount, {bool isBold = false}) {
    final style = TextStyle(
      fontFamily: 'Prompt',
      fontSize: 12,
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      color: const Color(0xFF000000),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Row(
          children: [
            Text(amount, style: style),
            const SizedBox(width: 8),
            Text('บาท', style: style),
          ],
        ),
      ],
    );
  }
}
