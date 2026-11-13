import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_sizes.dart';
import '../widgets/keyboard_safe_scroll.dart';

class JoinTheRoomScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// เรียกเมื่อส่งคำขอเข้าร่วมห้องสำเร็จ (ให้ไปหน้ารออนุมัติ)
  final VoidCallback? onJoined;

  final String userName;
  final String userPhone;

  const JoinTheRoomScreen({
    super.key,
    this.onBack,
    this.onJoined,
    this.userName = '',
    this.userPhone = '',
  });

  @override
  State<JoinTheRoomScreen> createState() => _JoinTheRoomScreenState();
}

class _JoinTheRoomScreenState extends State<JoinTheRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;
  String _error = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isSubmitting = false;
    });
  }

  /// ดึงชื่อ-เบอร์ของผู้ใช้ (จากที่ส่งเข้ามา ถ้าไม่มีดึงจากฐานข้อมูล)
  Future<(String, String)> _resolveProfile(String uid) async {
    var name = widget.userName.trim();
    var phone = widget.userPhone.trim();
    if (name.isNotEmpty && phone.isNotEmpty) return (name, phone);

    for (final table in ['roommate_invites', 'tenants', 'profiles']) {
      try {
        final row = await Supabase.instance.client
            .from(table)
            .select('full_name, phone')
            .eq('id', uid)
            .maybeSingle();
        if (name.isEmpty) name = row?['full_name']?.toString() ?? '';
        if (phone.isEmpty) phone = row?['phone']?.toString() ?? '';
      } catch (_) {}
      if (name.isNotEmpty && phone.isNotEmpty) break;
    }
    return (name, phone);
  }

  /// ตรวจว่าผู้ออกรหัสเชิญเป็น "ผู้เช่าหลัก" ของห้องนั้นหรือไม่
  ///
  /// อ่าน `dormitory_members` ของคนอื่นไม่ได้ (RLS: "Tenant reads own member record"
  /// ให้ผู้ใช้อ่านได้แค่แถวของตัวเอง) → ใช้ RPC `get_room_members`
  /// (security definer) ที่หน้า room_members ใช้อยู่แล้วแทน
  Future<bool> _isMainTenant(String inviterId, String dormitoryId) async {
    try {
      final members = await Supabase.instance.client.rpc(
        'get_room_members',
        params: {'p_user_id': inviterId},
      );
      for (final m in (members as List)) {
        if (m['user_id']?.toString() == inviterId &&
            m['member_type']?.toString() == 'tenant') {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('⚠️ get_room_members error: $e');
      // fallback: อ่านตรงจาก dormitory_members (ได้ก็ต่อเมื่อ policy อนุญาต)
      try {
        final inviter = await Supabase.instance.client
            .from('dormitory_members')
            .select('id, member_type, status, dormitory_id')
            .eq('user_id', inviterId)
            .eq('dormitory_id', dormitoryId)
            .eq('member_type', 'tenant')
            .eq('status', 'approved')
            .limit(1)
            .maybeSingle();
        return inviter != null;
      } catch (_) {
        return false;
      }
    }
  }

  /// ห้องเต็มไหม
  ///
  /// ผู้ใช้ทั่วไปอ่านตาราง `rooms` ไม่ได้ (RLS) → ถ้าอ่าน `max_tenants` ไม่ได้
  /// ให้ถือว่ายังไม่เต็ม แล้วให้แอดมินเป็นคนตรวจตอนกดอนุมัติ (dormitory_request.dart)
  Future<bool> _isRoomFull(String roomId, String inviterId) async {
    try {
      final room = await Supabase.instance.client
          .from('rooms')
          .select('max_tenants')
          .eq('id', roomId)
          .maybeSingle();
      final max = (room?['max_tenants'] as num?)?.toInt();
      if (max == null) return false;

      final members = await Supabase.instance.client.rpc(
        'get_room_members',
        params: {'p_user_id': inviterId},
      );
      return (members as List).length >= max;
    } catch (e) {
      print('⚠️ _isRoomFull error: $e');
      return false;
    }
  }

  /// ส่งคำขอเข้าร่วมห้องด้วยรหัสเชิญ
  /// - รหัสต้องมีอยู่จริง ไม่หมดอายุ และต้องออกจาก "ผู้เช่าหลัก" ที่อนุมัติแล้ว
  /// - สร้างคำขอเป็น Roommate (status = pending) ให้แอดมินอนุมัติ
  Future<void> _submit() async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) {
      _setError('กรุณาเข้าสู่ระบบก่อนเข้าร่วมห้อง');
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _setError('กรุณากรอกรหัสเชิญ');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = '';
    });

    try {
      // 1) หารหัสเชิญ
      final invite = await db
          .from('invitation_codes')
          .select('code, dormitory_id, room_id, created_by, expires_at')
          .eq('code', code)
          .maybeSingle();

      if (invite == null) {
        _setError('ไม่พบรหัสเชิญนี้ กรุณาตรวจสอบอีกครั้ง');
        return;
      }

      // 2) เช็คอายุรหัส
      final expiresAt = DateTime.tryParse(
        invite['expires_at']?.toString() ?? '',
      );
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        _setError('รหัสเชิญนี้หมดอายุแล้ว กรุณาขอรหัสใหม่จากผู้เช่าหลัก');
        return;
      }

      final dormitoryId = invite['dormitory_id']?.toString() ?? '';
      final inviterId = invite['created_by']?.toString() ?? '';
      if (dormitoryId.isEmpty || inviterId.isEmpty) {
        _setError('รหัสเชิญนี้ไม่สมบูรณ์ กรุณาขอรหัสใหม่จากผู้เช่าหลัก');
        return;
      }

      // 3) ผู้ออกรหัสต้องเป็นผู้เช่าหลักที่อนุมัติแล้วในหอนั้น
      // หมายเหตุ: อ่านแถวของ "คนอื่น" ใน dormitory_members ไม่ได้ (RLS ให้อ่านแค่แถวของตัวเอง)
      // → ต้องใช้ RPC get_room_members (security definer) แทน
      final isMainTenant = await _isMainTenant(inviterId, dormitoryId);
      if (!isMainTenant) {
        _setError('รหัสเชิญนี้ไม่ได้ออกจากผู้เช่าหลัก กรุณาตรวจสอบอีกครั้ง');
        return;
      }

      // 4) ห้องปลายทาง (รหัสเชิญผูกห้องไว้แล้ว)
      final roomId = invite['room_id']?.toString() ?? '';
      if (roomId.isEmpty) {
        _setError('ไม่พบห้องปลายทางของรหัสเชิญนี้ กรุณาขอรหัสใหม่');
        return;
      }

      // 5) ห้องเต็มไหม (ถ้าอ่านข้อมูลห้องไม่ได้จะข้าม เพราะแอดมินเป็นคนตรวจตอนอนุมัติ)
      if (await _isRoomFull(roomId, inviterId)) {
        _setError('ห้องนี้เต็มแล้ว ไม่สามารถเข้าร่วมได้');
        return;
      }

      // 6) อัปเดตข้อมูลใน roommate_invites (ให้แอดมินเห็นชื่อ-เบอร์)
      final (name, phone) = await _resolveProfile(uid);
      final existingInvite = await db
          .from('roommate_invites')
          .select('id')
          .eq('id', uid)
          .maybeSingle();

      if (existingInvite != null) {
        await db
            .from('roommate_invites')
            .update({
              'full_name': name,
              'phone': phone,
              'invite_code': code,
              'status': 'pending',
            })
            .eq('id', uid);
      } else {
        await db.from('roommate_invites').insert({
          'id': uid,
          'full_name': name,
          'phone': phone,
          'invite_code': code,
          'is_verified': false,
          'status': 'pending',
        });
      }

      // 7) สร้าง/รีเซ็ตคำขอใน dormitory_members เป็น Roommate (รอแอดมินอนุมัติ)
      final existingMember = await db
          .from('dormitory_members')
          .select('id, status')
          .eq('user_id', uid)
          .eq('dormitory_id', dormitoryId)
          .maybeSingle();

      if (existingMember == null) {
        await db.from('dormitory_members').insert({
          'user_id': uid,
          'dormitory_id': dormitoryId,
          'room_id': roomId,
          'member_type': 'roommate',
          'status': 'pending',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await db
            .from('dormitory_members')
            .update({
              'room_id': roomId,
              'member_type': 'roommate',
              'status': 'pending',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', existingMember['id']);
      }

      print('✅ Join room request sent: code=$code room=$roomId');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      widget.onJoined?.call();
    } catch (e) {
      print('❌ join room error: $e');
      _setError('ส่งคำขอไม่สำเร็จ กรุณาลองอีกครั้ง');
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                content: Column(
                  children: [
                    // Illustration
                    SvgPicture.asset(
                      'assets/images/join_the_room.svg',
                      width: 280,
                      height: 300,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => const Icon(
                        Icons.mail_outline,
                        size: 100,
                        color: Color(0xFF4F8FDB),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'กรอกรหัสเชิญที่ได้รับจากผู้เช่าหลัก',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Code input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9D9D9)),
                      ),
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'กรุณากรอกรหัสเชิญ',
                          hintStyle: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 15,
                            color: Color(0xFFD9D9D9),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 13,
                          color: Color(0xFFFF0303),
                        ),
                      ),
                    ],
                  ],
                ),
                bottom: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _codeController,
                    builder: (context, value, _) {
                      final isValid = value.text.trim().isNotEmpty;
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (isValid && !_isSubmitting)
                              ? _submit
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F8FDB),
                            disabledBackgroundColor: const Color(
                              0xFF4F8FDB,
                            ).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'เข้าร่วม',
                                  style: TextStyle(
                                    fontFamily: 'Noto Sans Thai',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    },
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
                'เข้าร่วมด้วยรหัสเชิญ',
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
