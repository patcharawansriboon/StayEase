import 'package:flutter/material.dart';

class BillDetailsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final Map<String, dynamic> bill;
  final String tenantName;
  final String room;

  const BillDetailsScreen({
    super.key,
    this.onBack,
    this.onEdit,
    this.bill = const {},
    this.tenantName = 'พัชราวรรณ  ศรีบุญ',
    this.room = 'A101',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildInfoRow('ผู้เช่า', tenantName),
                          const SizedBox(height: 8),
                          _buildInfoRow('ห้อง', room),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                              'รอบบิล', bill['month'] ?? 'กรกฎาคม 2569'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildAmountRow(
                              'ค่าเช่า', '${bill['rent'] ?? 4500} บาท'),
                          const SizedBox(height: 10),
                          _buildAmountRow(
                              'ค่าน้ำ', '${bill['water'] ?? 180} บาท'),
                          const SizedBox(height: 10),
                          _buildAmountRow(
                              'ค่าไฟ', '${bill['electricity'] ?? 320} บาท'),
                          if ((bill['penalty'] ?? 0) > 0) ...[
                            const SizedBox(height: 10),
                            _buildAmountRow(
                                'ค่าปรับ', '${bill['penalty']} บาท'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildAmountRow(
                          'รวมทั้งสิ้น', '${bill['total'] ?? 5000} บาท',
                          bold: true),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildAmountRow(
                          'ครบกำหนด', bill['due_date'] ?? '5 สิงหาคม 2569'),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/qr_code_payment-48e4cd.png',
                              width: 64,
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'QR PromptPay',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ขอบคุณที่ใช้บริการ StayEase',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8FDB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          if (onEdit != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B93D4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'แก้ไข',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              color: Color(0xFF888888),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 14,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, String amount, {bool bold = false}) {
    final style = TextStyle(
      fontFamily: 'Prompt',
      fontSize: 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: const Color(0xFF1A1A2E),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount, style: style),
      ],
    );
  }
}
