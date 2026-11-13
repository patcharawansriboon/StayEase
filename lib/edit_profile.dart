import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/app_sizes.dart';
import 'widgets/keyboard_safe_scroll.dart';

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;
  final String avatarUrl;
  final VoidCallback? onBack;
  final ValueChanged<String>? onSave;
  final ValueChanged<String>? onAvatarChanged;

  const EditProfileScreen({
    super.key,
    this.userName = '',
    this.phoneNumber = '',
    this.avatarUrl = '',
    this.onBack,
    this.onSave,
    this.onAvatarChanged,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(
      text: widget.phoneNumber.replaceAll(RegExp(r'\D'), ''),
    );
  }

  @override
  void didUpdateWidget(EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName) {
      _nameController.text = widget.userName;
    }
    if (oldWidget.phoneNumber != widget.phoneNumber) {
      _phoneController.text = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
      try {
        final db = Supabase.instance.client;
        final uid = db.auth.currentUser?.id;
        if (uid != null) {
          final ext = picked.path.split('.').last;
          final path =
              'avatars/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await db.storage
              .from('dormitory-images')
              .uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
          final url = db.storage.from('dormitory-images').getPublicUrl(path);
          widget.onAvatarChanged?.call(url);
          // ตรวจสอบว่า user เป็น admin หรือ tenant แล้วบันทึกลงตารางที่ถูกต้อง
          final adminRow = await db
              .from('admins')
              .select('id')
              .eq('id', uid)
              .maybeSingle();
          final table = adminRow != null ? 'admins' : 'tenants';
          await db.from(table).update({'avatar_url': url}).eq('id', uid);
        }
      } catch (e) {
        debugPrint('avatar upload error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: KeyboardSafeScroll(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                content: Column(
                  children: [
                    // รูปโปรไฟล์ + ปุ่มกล้อง
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFB7D6F5),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImageBytes != null
                                ? Image.memory(
                                    _profileImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : (widget.avatarUrl.isNotEmpty
                                      ? Image.network(
                                          widget.avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: const Color(0xFFB7D6F5),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 40,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                        )
                                      : Container(
                                          color: const Color(0xFFB7D6F5),
                                          child: const Center(
                                            child: Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F8FDB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // กรอบข้อมูลส่วนตัว
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFB7D6F5),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ป้ายชื่อ-นามสกุล
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ชื่อ-นามสกุล',
                              style: const TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 13,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // ช่องชื่อ-นามสกุล
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 15,
                              color: Color(0xFF000000),
                            ),
                            decoration: InputDecoration(
                              hintText: 'กรอกชื่อ-นามสกุล',
                              hintStyle: const TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 15,
                                color: Color(0xFFD9D9D9),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFFD9D9D9),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF4F8FDB),
                                  width: 1.5,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ป้ายเบอร์โทรศัพท์
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'เบอร์โทรศัพท์',
                              style: const TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 13,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // ช่องเบอร์โทรศัพท์ (แก้ไขไม่ได้, พื้นหลังสีเทา)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEFEF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _phoneController,
                              enabled: false,
                              style: const TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 15,
                                color: Color(0xFF000000),
                              ),
                              decoration: InputDecoration(
                                hintText: widget.phoneNumber.isEmpty
                                    ? 'ไม่มีข้อมูลเบอร์โทรศัพท์'
                                    : null,
                                hintStyle: const TextStyle(
                                  fontFamily: 'Noto Sans Thai',
                                  fontSize: 15,
                                  color: Color(0xFF666666),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: const Icon(
                                  Icons.lock_outlined,
                                  size: 16,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                bottom: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () =>
                          widget.onSave?.call(_nameController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F8FDB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'บันทึก',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 16,
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
      ),
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
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'แก้ไขโปรไฟล์',
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
}
