import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const PaymentScreen({super.key, this.onBack});

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
                child: Column(
                  children: [
                    // Subtitle
                    Text(
                      'สแกน QR Code ผ่านแอปธนาคาร',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      'เพื่อชำระเงิน',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR Code glass card
                    Container(
                      width: 226,
                      height: 275,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/qr_code_payment-48e4cd.png',
                            width: 200,
                            height: 196,
                            fit: BoxFit.fill,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.qr_code_2,
                              size: 120,
                              color: Color(0xFF4F8FDB),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Save button
                    Container(
                      width: 79,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8FDB).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.download,
                            size: 20,
                            color: Color(0xFF4F8FDB),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'บันทึก',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Color(0xFF4F8FDB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Attach receipt button
                    Container(
                      width: 275,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.image_outlined,
                            size: 22,
                            color: Color(0xFF4F8FDB),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'แนบหลักฐานการโอน',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Color(0xFF4F8FDB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Send button
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 130,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F8FDB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'ส่ง',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        color: Colors.white,
                      ),
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
          const Expanded(
            child: Center(
              child: Text(
                'ชำระเงินด้วย QR Code',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
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
