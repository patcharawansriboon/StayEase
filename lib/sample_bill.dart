import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'services/mock_service.dart';

import 'widgets/app_sizes.dart';
/// หน้าตัวอย่างบิล — แสดงสรุปบิลก่อนส่งให้ผู้เช่า
class SampleBillScreen extends StatefulWidget {
  /// ข้อมูลบิลที่ส่งมาจากหน้า build_tenant_bill
  final Map<String, dynamic> billData;

  /// กดปุ่ม "แก้ไข" → กลับไปหน้าสร้างบิล
  final VoidCallback? onEdit;

  /// กดปุ่ม "ส่ง" สำเร็จ → แจ้งหน้าเรียกให้ refresh/นำทาง
  final void Function(Map<String, dynamic> billData)? onSend;

  const SampleBillScreen({
    super.key,
    required this.billData,
    this.onEdit,
    this.onSend,
  });

  @override
  State<SampleBillScreen> createState() => _SampleBillScreenState();
}

class _SampleBillScreenState extends State<SampleBillScreen> {
  bool _saving = false;

  Map<String, dynamic> get billData => widget.billData;

  // ---- helpers ----
  String get _tenantName => billData['tenantName']?.toString() ?? '-';
  String get _room => billData['room']?.toString() ?? '-';
  double get _roomFee => (billData['roomFee'] as num?)?.toDouble() ?? 0;
  double get _waterTotal => (billData['waterTotal'] as num?)?.toDouble() ?? 0;
  double get _electricTotal =>
      (billData['electricTotal'] as num?)?.toDouble() ?? 0;
  double get _grandTotal =>
      (billData['grandTotal'] as num?)?.toDouble() ??
      (_roomFee + _waterTotal + _electricTotal);
  Uint8List? get _qrBytes => billData['qrBytes'] as Uint8List?;

  // รอบบิล/ครบกำหนด — ใช้เดือนปัจจุบัน (ปี พ.ศ.)
  String get _billPeriod {
    final now = DateTime.now();
    return '${_thMonth(now.month)} ${now.year + 543}';
  }

  String get _dueDate {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return '$lastDay ${_thMonth(now.month)} ${now.year + 543}';
  }

  String _thMonth(int m) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return months[(m - 1) % 12];
  }

  // จัดรูปแบบเงิน เช่น 7150 -> 7,150
  String _fmt(double n) {
    final intPart = n.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _buildBillCard(),
            ),
          ),
          _buildBottomButtons(context),
        ],
      ),
    );
  }

  // ---- Header ----
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: const Center(
        child: Text(
          'ตัวอย่างบิล',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: kPageTitleFontSize,
              fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }

  // ---- การ์ดบิล ----
  Widget _buildBillCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // โลโก้
          Image.asset(
            'assets/images/logo.png',
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'StayEase',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F8FDB),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ข้อมูลผู้เช่า
          _infoRow('ผู้เช่า', _tenantName),
          const SizedBox(height: 10),
          _infoRow('ห้อง', _room),
          const SizedBox(height: 10),
          _infoRow('รอบบิล', _billPeriod),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 16),
          // รายการค่าใช้จ่าย
          _amountRow('ค่าเช่า', _roomFee),
          const SizedBox(height: 10),
          _amountRow('ค่าน้ำ', _waterTotal),
          const SizedBox(height: 10),
          _amountRow('ค่าไฟ', _electricTotal),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 16),
          // รวมทั้งสิ้น
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รวมทั้งสิ้น',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                '${_fmt(_grandTotal)} บาท',
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 16),
          // ครบกำหนด
          _infoRow('ครบกำหนด', _dueDate, valueAlign: TextAlign.right),
          const SizedBox(height: 20),
          // QR PromptPay
          _buildQr(),
          const SizedBox(height: 16),
          const Text(
            'ขอบคุณที่ใช้บริการ StayEase',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQr() {
    if (_qrBytes != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_qrBytes!, width: 120, height: 120,
                fit: BoxFit.cover),
          ),
          const SizedBox(height: 6),
          const Text(
            'QR PromptPay',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
        ],
      );
    }
    // ไม่มีรูป QR → placeholder
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2, size: 40, color: Color(0xFFBBBBBB)),
          SizedBox(height: 4),
          Text(
            'QR PromptPay',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 10,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  // แถวข้อมูล (label ซ้าย, value)
  Widget _infoRow(String label, String value,
      {TextAlign valueAlign = TextAlign.left}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              color: Color(0xFF555555),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: valueAlign,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  // แถวจำนวนเงิน (label ซ้าย, จำนวน ขวา)
  Widget _amountRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          '${_fmt(amount)} บาท',
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(height: 1, color: const Color(0xFFEEF1F5));

  // ---- บันทึกบิลลง Supabase ----
  Future<void> _sendBill() async {
    final tenantId = billData['userId']?.toString() ??
        billData['tenantId']?.toString() ??
        '';
    if (tenantId.isEmpty) {
      _showSnack('ไม่พบข้อมูลผู้เช่า ไม่สามารถบันทึกบิลได้', isError: true);
      return;
    }

    setState(() => _saving = true);

    // หา dormitory ของแอดมิน
    final dormitoryId = await mockService.getAdminDormitoryId();

    // รอบบิล + ครบกำหนด (ISO yyyy-MM-dd, ปี ค.ศ.)
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final dueIso =
        '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

    final ok = await mockService.createBill(
      tenantId: tenantId,
      tenantName: _tenantName,
      room: _room,
      dormitoryId: dormitoryId,
      month: _billPeriod,
      rent: _roomFee.round(),
      electricity: _electricTotal.round(),
      water: _waterTotal.round(),
      total: _grandTotal.round(),
      dueDate: dueIso,
      qrBytes: _qrBytes,
      qrFileName: billData['qrFileName']?.toString(),
      electricMeterPrev: billData['electricPrev']?.toString(),
      electricMeterCurr: billData['electricCurrent']?.toString(),
      waterMeterPrev: billData['waterPrev']?.toString(),
      waterMeterCurr: billData['waterCurrent']?.toString(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _showSnack('ส่งบิลเรียบร้อยแล้ว');
      widget.onSend?.call(billData);
    } else {
      _showSnack('บันทึกบิลไม่สำเร็จ กรุณาลองใหม่', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Noto Sans Thai'),
        ),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- ปุ่มล่าง: แก้ไข / ส่ง ----
  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : (widget.onEdit ?? () => Navigator.maybePop(context)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4F8FDB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'แก้ไข',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 16,
                    color: Color(0xFF4F8FDB),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _sendBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8FDB),
                  disabledBackgroundColor: const Color(0xFF9BBEE6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ส่ง',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
