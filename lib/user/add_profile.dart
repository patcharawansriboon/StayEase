import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/sign_up_background.dart';

import '../widgets/app_sizes.dart';
class VerifyNumberScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onVerified;
  final String phoneNumber;
  final Map<String, dynamic>? userData;

  const VerifyNumberScreen({
    super.key,
    required this.onBack,
    required this.onVerified,
    required this.phoneNumber,
    this.userData,
  });

  @override
  State<VerifyNumberScreen> createState() => _VerifyNumberScreenState();
}

class _VerifyNumberScreenState extends State<VerifyNumberScreen> {
  Uint8List? _profileImageBytes;
  File? _profileImageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
        _profileImageFile = File(picked.path);
      });
    }
  }

  Future<void> _onConfirm() async {
    setState(() => _isUploading = true);
    String? avatarUrl;
    // แอดมินผ่านเสมอ / ผู้เช่าและ Roommate ต้องส่งคำขอสำเร็จจึงจะผ่าน
    var membershipOk = widget.userData?['isAdmin'] == true;
    try {
      if (_profileImageFile != null && _profileImageBytes != null) {
        // อัปโหลดรูปไม่สำเร็จต้องไม่ขวางการส่งคำขอเข้าหอพัก
        try {
          final db = Supabase.instance.client;
          final uid = db.auth.currentUser?.id;
          if (uid != null) {
            final ext = _profileImageFile!.path.split('.').last;
            final path =
                'avatars/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
            await db.storage
                .from('dormitory-images')
                .uploadBinary(
                  path,
                  _profileImageBytes!,
                  fileOptions: const FileOptions(upsert: true),
                );
            avatarUrl = db.storage.from('dormitory-images').getPublicUrl(path);
          }
        } catch (e) {
          print('❌ upload avatar error: $e');
        }
      }

      final db = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid != null && avatarUrl != null && avatarUrl.isNotEmpty) {
        final isRoommate = widget.userData?['isRoommate'] == true;
        final isAdmin = widget.userData?['isAdmin'] == true;
        try {
          if (isAdmin) {
            await db.from('admins').upsert({
              'id': uid,
              'full_name': widget.userData?['name'] ?? '',
              'phone': widget.phoneNumber,
              'avatar_url': avatarUrl,
            });
          } else if (isRoommate) {
            await db.from('roommate_invites').upsert({
              'id': uid,
              'full_name': widget.userData?['name'] ?? '',
              'phone': widget.phoneNumber,
              'avatar_url': avatarUrl,
            });
          } else {
            await db.from('tenants').upsert({
              'id': uid,
              'full_name': widget.userData?['name'] ?? '',
              'phone': widget.phoneNumber,
              'avatar_url': avatarUrl,
            });
          }
        } catch (e) {
          print('❌ update avatar error: $e');
        }
      }

      // แอดมินไม่ต้องส่งคำขอเข้าหอพัก ส่วนผู้เช่า/Roommate ต้องสร้างคำขอให้สำเร็จ
      final submitted = await AuthService().submitMembershipAfterVerify(
        phone: widget.phoneNumber,
        fullName: widget.userData?['name'] ?? '',
        dormCode: widget.userData?['dormCode'],
        roomNumber: widget.userData?['roomNumber'],
        inviteCode: widget.userData?['inviteCode'],
        avatarUrl: avatarUrl,
      );
      if (widget.userData?['isAdmin'] != true) membershipOk = submitted;
      if (widget.userData?['isAdmin'] == true) {
        try {
          final uid = db.auth.currentUser?.id;
          if (uid != null) {
            await db.from('admins').upsert({
              'id': uid,
              'full_name': widget.userData?['name'] ?? '',
              'phone': widget.phoneNumber,
              if (avatarUrl != null && avatarUrl.isNotEmpty)
                'avatar_url': avatarUrl,
            });
          }
        } catch (e) {
          print('❌ update admin avatar error: $e');
        }
      }
    } catch (e) {
      print('❌ verify confirm error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }

    // ส่งคำขอเข้าหอพักไม่สำเร็จ → อยู่หน้านี้และแจ้งผู้ใช้ ไม่ไปหน้ารอผลทั้งที่ไม่มีคำขอ
    if (!membershipOk) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ส่งคำขอเข้าหอพักไม่สำเร็จ กรุณาตรวจสอบรหัสหอพัก/รหัสคำเชิญแล้วลองอีกครั้ง',
            style: TextStyle(fontFamily: 'Noto Sans Thai'),
          ),
          backgroundColor: Color(0xFFFF0303),
        ),
      );
      return;
    }
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    return SignUpBackground(
      minimal: true,
      solidColor: Colors.white,
      child: Column(
        children: [
          // ---- ปุ่มย้อนกลับ + หัวข้อ ----
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 40.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chevron_left,
                        size: kBackIconSize,
                        color: Color(0xFF1A1A2E),
                      ),
                      onPressed: widget.onBack,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'เพิ่มรูปโปรไฟล์ของคุณ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'รูปโปรไฟล์จะช่วยให้เพื่อนร่วมแชทหอพัก\nและผู้ดูแลหอพักรู้จักคุณได้ง่ายขึ้น',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // วงกลมอัปโหลดรูปโปรไฟล์
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFB7D6F5)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB7D6F5),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _profileImageBytes != null
                      ? ClipOval(
                          child: Image.memory(
                            _profileImageBytes!,
                            width: 116,
                            height: 116,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            size: 56,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ปุ่มเลือกรูปจากคลัง
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: 140,
              child: OutlinedButton(
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFB7D6F5)),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image,
                        size: 20,
                        color: Color(0xFF4F8FDB),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'เลือกรูปจากคลัง',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4F8FDB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Spacer(flex: 3),
          // ปุ่มยืนยัน
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8FDB),
                  disabledBackgroundColor: const Color(0xFFD9D9D9),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isUploading ? 'กำลังอัปโหลด...' : 'ยืนยัน',
                  style: const TextStyle(
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
