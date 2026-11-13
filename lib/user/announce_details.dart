import 'package:flutter/material.dart';
import '../../services/tenant_auth_service.dart';

import '../widgets/app_sizes.dart';
class AnnounceDetailsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final String? imagePath;
  final String title;
  final String detail;
  final String date;
  final String endDate; // yyyy-mm-dd (ว่าง = ไม่กำหนด)
  final bool isAdmin;
  final void Function({String? announcementId, Map<String, String>? initialData})? onEdit;
  final VoidCallback? onDelete;
  final String? announcementId;

  const AnnounceDetailsScreen({
    super.key,
    this.onBack,
    this.imagePath,
    this.title = '',
    this.detail = '',
    this.date = '',
    this.endDate = '',
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
    this.announcementId,
  });

  bool get _hasImage => (imagePath ?? '').isNotEmpty;

  Future<void> _handleEdit(BuildContext context) async {
    if (announcementId == null) return;
    
    final initialData = {
      'title': title,
      'content': detail,
      'image': imagePath ?? '',
      'end_date': endDate,
    };
    
    onEdit?.call(
      announcementId: announcementId,
      initialData: initialData,
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    if (announcementId == null) return;
    
    final confirm = await showDialog<bool>(
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
                'ยืนยันการลบ',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ต้องการลบประกาศนี้ใช่หรือไม่?',
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
                        'ลบ',
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
    
    if (confirm == true) {
      final success = await TenantAuthService().deleteAnnouncement(announcementId!);
      if (context.mounted) {
        if (success) {
          // ลบ SnackBar หลังจากลบสำเร็จ (ไม่แสดงแถบแจ้งเตือน)
          onDelete?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบไม่สำเร็จ กรุณาลองใหม่', style: TextStyle(fontFamily: 'Noto Sans Thai')),
              backgroundColor: Color(0xFFF16C6C),
            ),
          );
        }
      }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปภาพ (ถ้ามี)
                  if (_hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImage(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // หัวข้อ - กรอบการ์ด
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE27F),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x334F8FDB),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isNotEmpty ? title : 'ประกาศ',
                                style: const TextStyle(
                                  fontFamily: 'Noto Sans Thai',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              if (date.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 15, color: Color(0xFF888888)),
                                    const SizedBox(width: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontFamily: 'Noto Sans Thai',
                                        fontSize: 13,
                                        color: Color(0xFF888888),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/images/proclaim.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.campaign,
                              size: 60, color: Color(0xFFE6A700)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // รายละเอียด - กรอบการ์ด
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x334F8FDB),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รายละเอียด',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.isNotEmpty ? detail : '-',
                          style: const TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Color(0xFF555555),
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Admin-only: แก้ไข + ลบประกาศ
          // ตำแหน่งเดียวกับปุ่ม "บันทึก" หน้าตั้งค่าหอพัก (ซ้ายขวา 16, ห่างขอบล่าง 32)
          // ไม่ใช้ SafeArea เพื่อให้ตรงกันทุกอุปกรณ์
          if (isAdmin)
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => _handleEdit(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF4F8FDB), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'แก้ไข',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4F8FDB),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _handleDelete(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0303),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ลบประกาศ',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
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

  // รูปรองรับทั้ง URL (Supabase) และ asset
  Widget _buildImage() {
    final path = imagePath ?? '';
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    return Image.asset(
      path,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageError(),
    );
  }

  Widget _imageError() => Container(
        height: 200,
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFCCCCCC)),
        ),
      );

  // ---- Header: ย้อนกลับ + ข้อความ "รายละเอีย์ประกาศ" ----
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.chevron_left,
                size: kBackIconSize, color: Color(0xFF1A1A2E)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                  'รายละเอียดประกาศ',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}
