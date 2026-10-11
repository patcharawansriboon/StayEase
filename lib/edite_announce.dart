import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/tenant_auth_service.dart';

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

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _uploadedImageUrl;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _contentController.text = widget.initialData!['content'] ?? '';
      _uploadedImageUrl = widget.initialData!['image'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // อ่านเป็น bytes เพื่อรองรับทั้ง web และ mobile
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'วว/ดด/ปปปป';
    final buddhistYear = d.year + 543;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/$buddhistYear';
  }

  Future<String?> _uploadImage(Uint8List bytes, String name) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return null;

      // เก็บนามสกุลไฟล์เดิม (เช่น .jpg .png)
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final fileName =
          'announcements/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('dormitory-images')
          .uploadBinary(fileName, bytes,
              fileOptions: const FileOptions(upsert: true));

      return Supabase.instance.client.storage
          .from('dormitory-images')
          .getPublicUrl(fileName);
    } catch (e) {
      print('❌ _uploadImage error: $e');
      return null;
    }
  }

  Future<void> _saveAnnouncement({required bool isDraft}) async {
    // ตรวจข้อมูลขั้นต่ำ
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกหัวข้อและรายละเอียด',
              style: TextStyle(fontFamily: 'Prompt')),
          backgroundColor: Color(0xFFF16C6C),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _uploadedImageUrl;
      if (_selectedImageBytes != null) {
        imageUrl = await _uploadImage(
            _selectedImageBytes!, _selectedImageName ?? 'image.jpg');
      }

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
        imageUrl: imageUrl,
        dormitoryId: dormitoryId,
        announcementId: widget.announcementId,
        isDraft: isDraft,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft ? 'บันทึกฉบับร่างสำเร็จ' : 'เผยแพร่ประกาศสำเร็จ',
                style: const TextStyle(fontFamily: 'Prompt')),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        widget.onSave?.call();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่',
                style: TextStyle(fontFamily: 'Prompt')),
            backgroundColor: Color(0xFFF16C6C),
          ),
        );
      }
    } catch (e) {
      print('❌ _saveAnnouncement error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่',
                style: TextStyle(fontFamily: 'Prompt')),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  // กล่องหัวข้อ + รายละเอียด + ไอคอนรูป
                  _buildContentBox(),
                  const SizedBox(height: 16),
                  // วันที่เริ่มประกาศ
                  _buildDateField(
                    label: 'วันที่เริ่มประกาศ',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                  const SizedBox(height: 12),
                  // วันที่สิ้นสุดประกาศ
                  _buildDateField(
                    label: 'วันที่สิ้นสุดประกาศ',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
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
            onTap: widget.onBack,
            child: const Icon(Icons.chevron_left,
                size: 28, color: Color(0xFF1A1A2E)),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.announcementId != null ? 'แก้ไขประกาศ' : 'เพิ่มประกาศ',
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
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
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
            ),
            decoration: const InputDecoration(
              hintText: 'หัวข้อ',
              hintStyle: TextStyle(
                fontFamily: 'Prompt',
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
              fontFamily: 'Prompt',
              fontSize: 14,
              color: Color(0xFF000000),
            ),
            decoration: const InputDecoration(
              hintText: 'รายละเอียด',
              hintStyle: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 14,
                color: Color(0xFFBBBBBB),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          // ไอคอนรูป / รูปที่เลือก
          _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _selectedImageBytes != null || _uploadedImageUrl != null;

    if (hasImage) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _selectedImageBytes != null
                ? Image.memory(_selectedImageBytes!,
                    width: 80, height: 80, fit: BoxFit.cover)
                : Image.network(_uploadedImageUrl!,
                    width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder()),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedImageBytes = null;
                _selectedImageName = null;
                _uploadedImageUrl = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE05C5C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: const Icon(Icons.image_outlined,
            size: 24, color: Color(0xFF9DB7D6)),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 80,
        height: 80,
        color: const Color(0xFFF5F5F5),
        child: const Icon(Icons.broken_image,
            size: 32, color: Color(0xFFCCCCCC)),
      );

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
          border: Border.all(color: const Color(0xFFD9D9D9)),
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
                      fontFamily: 'Prompt',
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 13,
                      color: date == null
                          ? const Color(0xFFBBBBBB)
                          : const Color(0xFF4F8FDB),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: Color(0xFF4F8FDB)),
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
          onPressed:
              _isLoading ? null : () => _saveAnnouncement(isDraft: false),
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
                      strokeWidth: 2, color: Colors.white))
              : const Text(
                  'เผยแพร่',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
