import 'package:flutter/material.dart';
import '../../edite_announce.dart';
import '../../services/tenant_auth_service.dart';

class AnnounceDetailsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final String? imagePath;
  final String title;
  final String detail;
  final String date;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? announcementId;

  const AnnounceDetailsScreen({
    super.key,
    this.onBack,
    this.imagePath,
    this.title = '',
    this.detail = '',
    this.date = '',
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
    };
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditeAnnounceScreen(
          announcementId: announcementId,
          initialData: initialData,
          onBack: () => Navigator.pop(context),
          onSave: () {
            Navigator.pop(context);
            onEdit?.call();
          },
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    if (announcementId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ', style: TextStyle(fontFamily: 'Prompt')),
        content: const Text('ต้องการลบประกาศนี้ใช่หรือไม่?', style: TextStyle(fontFamily: 'Prompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก', style: TextStyle(fontFamily: 'Prompt')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(fontFamily: 'Prompt', color: Color(0xFFE05C5C))),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await TenantAuthService().deleteAnnouncement(announcementId!);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบประกาศสำเร็จ', style: TextStyle(fontFamily: 'Prompt')),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          onDelete?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบไม่สำเร็จ กรุณาลองใหม่', style: TextStyle(fontFamily: 'Prompt')),
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
                                  fontFamily: 'Prompt',
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
                                        fontFamily: 'Prompt',
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
                            fontFamily: 'Prompt',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.isNotEmpty ? detail : '-',
                          style: const TextStyle(
                            fontFamily: 'Prompt',
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

          // Admin-only: แก้ไข + ลบโพสต์
          if (isAdmin)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                              fontFamily: 'Prompt',
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
                            backgroundColor: const Color(0xFFE05C5C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ลบโพสต์',
                            style: TextStyle(
                              fontFamily: 'Prompt',
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
                size: 28, color: Color(0xFF1A1A2E)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                  'รายละเอียดประกาศ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
