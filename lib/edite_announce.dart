import 'package:flutter/material.dart';
import 'services/tenant_auth_service.dart';

import 'widgets/app_sizes.dart';
import 'widgets/keyboard_safe_scroll.dart';

class EditeAnnounceScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final String? announcementId; // null = create new
  final Map<String, String>? initialData; // for editing existing

  const EditeAnnounceScreen({
    super.key,
    this.onBack,
    this.onSave,
    this.announcementId,
    this.initialData,
  });

  @override
  State<EditeAnnounceScreen> createState() => _EditeAnnounceScreenState();
}

class _EditeAnnounceScreenState extends State<EditeAnnounceScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _contentController.text = widget.initialData!['content'] ?? '';
      // วันที่สิ้นสุดเดิมของประกาศ (yyyy-mm-dd)
      final end = widget.initialData!['end_date'] ?? '';
      if (end.isNotEmpty) {
        _endDate = DateTime.tryParse(end);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// กดย้อนกลับ — แสดง popup ยืนยันก่อนไปหน้า announce_details
  Future<void> _confirmBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ยืนยันการย้อนกลับ',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ข้อมูลที่แก้ไขจะหายทั้งหมด\nต้องการย้อนกลับหรือไม่?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F8FDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFF4F8FDB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0303),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ย้อนกลับ',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      widget.onBack?.call();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F8FDB),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'วว/ดด/ปปปป';
    final buddhistYear = d.year + 543;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/$buddhistYear';
  }

  Future<void> _saveAnnouncement({required bool isDraft}) async {
    // ตรวจข้อมูลขั้นต่ำ
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกหัวข้อและรายละเอียด',
            style: TextStyle(fontFamily: 'Noto Sans Thai'),
          ),
          backgroundColor: Color(0xFFF16C6C),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dormitoryId = await TenantAuthService().getAdminDormitoryId();
      if (dormitoryId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลหอพักของแอดมิน')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      final success = await TenantAuthService().saveAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        // แก้ไขประกาศ: คงรูปเดิมไว้ (หน้านี้ยังไม่มีช่องแก้รูป) ไม่ให้ถูกล้างเป็นค่าว่าง
        imageUrl: (widget.initialData?['image'] ?? '').isEmpty
            ? null
            : widget.initialData!['image'],
        dormitoryId: dormitoryId,
        announcementId: widget.announcementId,
        isDraft: isDraft,
        endDate: _endDate,
      );

      if (success && mounted) {
        widget.onSave?.call();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'เกิดข้อผิดพลาด กรุณาลองใหม่',
              style: TextStyle(fontFamily: 'Noto Sans Thai'),
            ),
            backgroundColor: Color(0xFFF16C6C),
          ),
        );
      }
    } catch (e) {
      print('❌ _saveAnnouncement error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'เกิดข้อผิดพลาด กรุณาลองใหม่',
              style: TextStyle(fontFamily: 'Noto Sans Thai'),
            ),
            backgroundColor: Color(0xFFF16C6C),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: KeyboardSafeScroll(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              content: Column(
                children: [
                  // กล่องหัวข้อ + รายละเอียด
                  _buildContentBox(),
                  const SizedBox(height: 16),
                  // วันที่สิ้นสุดประกาศ
                  _buildDateField(
                    label: 'วันที่สิ้นสุดประกาศ',
                    date: _endDate,
                    onTap: _pickDate,
                  ),
                ],
              ),
              bottom: _buildBottomButtons(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _confirmBack,
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.announcementId != null ? 'แก้ไขประกาศ' : 'เพิ่มประกาศ',
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  // ---- กล่องเนื้อหา: หัวข้อ + รายละเอียด + ไอคอนรูปมุมล่างซ้าย ----
  Widget _buildContentBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7D6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
            ),
            decoration: const InputDecoration(
              hintText: 'หัวข้อ',
              hintStyle: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBBBBBB),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          // รายละเอียด
          TextField(
            controller: _contentController,
            maxLines: 8,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              color: Color(0xFF000000),
            ),
            decoration: const InputDecoration(
              hintText: 'รายละเอียด',
              hintStyle: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Color(0xFFBBBBBB),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---- ช่องเลือกวันที่ ----
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB7D6F5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 13,
                      color: date == null
                          ? const Color(0xFFBBBBBB)
                          : const Color(0xFF4F8FDB),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Color(0xFF4F8FDB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : () => _saveAnnouncement(isDraft: false),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F8FDB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.announcementId != null ? 'บันทึก' : 'เผยแพร่',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
