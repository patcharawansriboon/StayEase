import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/mock_service.dart';

import '../widgets/app_sizes.dart';
class PaymentScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSubmit;
  final VoidCallback? onSaveQr;
  final VoidCallback? onAttachProof;
  final String tenantName;
  final String roomNumber;
  final Map<String, dynamic> currentBill;

  const PaymentScreen({
    super.key,
    this.onBack,
    this.onSubmit,
    this.onSaveQr,
    this.onAttachProof,
    this.tenantName = 'คุณพัชราวรรณ ศรีบุญ',
    this.roomNumber = 'A101',
    this.currentBill = const {},
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  XFile? _proofImage;
  Uint8List? _proofBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Uint8List? get proofBytes => _proofBytes;
  XFile? get proofImage => _proofImage;

  String get _amount {
    final total = widget.currentBill['total'];
    if (total == null) return '4,500.00';
    final value = total is num ? total.toDouble() : double.tryParse('$total');
    if (value == null) return '$total';
    final whole = value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1)},',
        );
    final decimals = ((value - value.truncateToDouble()) * 100)
        .round()
        .toString()
        .padLeft(2, '0');
    return '$whole.$decimals';
  }

  Future<void> _attachProof() async {
    widget.onAttachProof?.call();
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _proofImage = picked;
      _proofBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (_proofBytes == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final bid = widget.currentBill['id']?.toString();
    print('🔍 PAYMENT DEBUG: bid=$bid, hasBytes=${_proofBytes != null}');
    String? proofUrl;
    if (bid != null && bid.isNotEmpty) {
      proofUrl = await mockService.uploadPaymentProof(
        billId: bid,
        bytes: _proofBytes!,
        fileName: _proofImage?.name,
      );
      print('🔍 PAYMENT DEBUG: proofUrl=$proofUrl');
      final ok = await mockService.updateBillStatus(bid, 'review',
          paymentProofUrl: proofUrl);
      print('🔍 PAYMENT DEBUG: updateStatus ok=$ok');
    } else {
      print('⚠️ PAYMENT DEBUG: Missing bill id, skipping upload!');
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    widget.onSubmit?.call();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaymentInfoCard(),
                  const SizedBox(height: 14),
                  _buildQrCard(),
                  const SizedBox(height: 14),
                  _buildSecurityBanner(),
                  const SizedBox(height: 12),
                  _buildAttachProof(),
                ],
              ),
            ),
          ),
          _buildSubmitButton(),
        ],
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
            onTap: widget.onBack,
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ชำระเงินด้วย QR Code',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
                  fontWeight: FontWeight.w600,
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

  // ---- Payment info card ----
  Widget _buildPaymentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // Title row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.description_outlined,
                    size: 20, color: Color(0xFF4F8FDB)),
                SizedBox(width: 8),
                Text(
                  'ข้อมูลการชำระเงิน',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F8FDB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tenant + amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผู้เช่า',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tenantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ห้อง ${widget.roomNumber}',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 46,
                color: const Color(0xFFD4E0EF),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดที่ต้องชำระ',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _amount,
                          style: const TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            'บาท',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- QR card ----
  Widget _buildQrCard() {
    final qrUrl = (widget.currentBill['qrImageUrl'] ??
            widget.currentBill['qr_image_url'])
        ?.toString() ??
        '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAF0F7), width: 1),
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
          // Chip header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'สแกน QR Code เพื่อชำระเงิน',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4F8FDB),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // QR image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: qrUrl.isNotEmpty
                ? Image.network(
                    qrUrl,
                    width: 210,
                    height: 210,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 210,
                        height: 210,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.qr_code_2,
                      size: 160,
                      color: Color(0xFF4F8FDB),
                    ),
                  )
                : Image.asset(
                    'assets/images/qr_code_payment-48e4cd.png',
                    width: 210,
                    height: 210,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.qr_code_2,
                      size: 160,
                      color: Color(0xFF4F8FDB),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Save QR button
          GestureDetector(
            onTap: widget.onSaveQr,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F8FDB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.download, size: 18, color: Color(0xFF4F8FDB)),
                  SizedBox(width: 6),
                  Text(
                    'บันทึก QR Code',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 13,
                      color: Color(0xFF4F8FDB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Security banner ----
  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user,
              size: 22, color: Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ปลอดภัย มั่นใจได้',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F8FDB),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'รองรับการชำระผ่านธนาคาร โดยใช้ระบบพร้อมเพย์',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Attach proof row ----
  Widget _buildAttachProof() {
    return GestureDetector(
      onTap: _attachProof,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FD),
          borderRadius: BorderRadius.circular(14),
        ),
        child: _proofImage == null
            ? Row(
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      size: 22, color: Color(0xFF4F8FDB)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'แนบหลักฐานการโอน',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: const Color(0xFF4F8FDB).withValues(alpha: 0.7),
                  ),
                ],
              )
            : GestureDetector(
                onTap: () {
                  if (_proofBytes == null) return;
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.memory(_proofBytes!),
                      ),
                    ),
                  );
                },
                child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _proofBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _proofImage = null;
                        _proofBytes = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              ),
      ),
    );
  }

  // ---- Submit button ----
  Widget _buildSubmitButton() {
    final status = widget.currentBill['status']?.toString() ?? '';
    final statusLabel = widget.currentBill['status_label']?.toString() ?? '';
    final isReviewing = status == 'review' ||
        statusLabel == 'รอตรวจสอบ' ||
        status == 'pending' && statusLabel.contains('ตรวจสอบ');
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isReviewing || _isSubmitting
              ? null
              : (_proofBytes != null ? _submit : null),
          style: ElevatedButton.styleFrom(
            backgroundColor: isReviewing
                ? const Color(0xFFD9D9D9)
                : (_proofBytes != null
                    ? const Color(0xFF4F8FDB)
                    : const Color(0xFFD9D9D9)),
            disabledBackgroundColor: const Color(0xFFD9D9D9),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            isReviewing ? 'รอตรวจสอบ' : (_isSubmitting ? 'กำลังส่ง...' : 'ส่ง'),
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
