import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  String _authEmail(String phone) => '$phone@stayease.app';

  /// คืน user id ที่มี session ใช้งานได้จริง (RLS ต้องอาศัย auth.uid())
  /// ถ้ายังไม่มี session ให้ลอง signIn ด้วยรหัสผ่านเดิม
  /// คืน null เมื่อเข้าสู่ระบบไม่ได้
  Future<String?> _resolveUserId({
    required String phone,
    required String password,
    required String label,
  }) async {
    final current = _supabase.auth.currentUser;
    if (current != null) return current.id;

    try {
      await _supabase.auth.signInWithPassword(
        email: _authEmail(phone),
        password: password,
      );
      return _supabase.auth.currentUser?.id;
    } catch (e) {
      print('❌ $label: เข้าสู่ระบบหลังลงทะเบียนไม่สำเร็จ ($e)');
      return null;
    }
  }

  /// ลงทะเบียนใหม่ หรือเข้าสู่ระบบถ้าเบอร์นี้มีอยู่แล้ว
  /// คืน user id ที่มี session หรือ null เมื่อทำไม่ได้
  Future<String?> _signUpOrSignIn({
    required String phone,
    required String password,
    required String fullName,
    required String label,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: _authEmail(phone),
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      return _resolveUserId(phone: phone, password: password, label: label);
    } on AuthApiException catch (e) {
      final alreadyExists =
          e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already registered');
      if (!alreadyExists) rethrow;
      print(
        '⚠️ $label: เบอร์นี้มีบัญชีอยู่แล้ว → เข้าสู่ระบบแทนการลงทะเบียนใหม่',
      );
      return _resolveUserId(phone: phone, password: password, label: label);
    }
  }

  /// ห้องเต็มหรือยัง — นับสมาชิกที่ approved แล้วในห้อง เทียบกับ max_tenants
  /// [selfUid] = user ปัจจุบัน (ถ้าเขามีแถวอยู่แล้วในห้องนี้ จะไม่นับซ้ำ
  ///  เช่น re-apply หลังถูกปฏิเสธ)
  Future<bool> _isRoomFull(String roomId, String selfUid) async {
    try {
      final room = await _supabase
          .from('rooms')
          .select('max_tenants')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return false;
      final max = (room['max_tenants'] as num?)?.toInt() ?? 1;

      final rows = await _supabase
          .from('dormitory_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('status', 'approved');

      var count = (rows as List).length;
      // ไม่นับตัวเองถ้ามีแถว approved อยู่แล้ว
      final alreadyIn = (rows).any((r) => r['user_id']?.toString() == selfUid);
      if (alreadyIn) count -= 1;

      return count >= max;
    } catch (e) {
      print('❌ _isRoomFull error: $e');
      return false; // เช็คไม่ได้ → ไม่บล็อก (ให้แอดมินเป็น gate สุดท้าย)
    }
  }

  /// ส่งคำขอเข้าหอพักหลังจากยืนยันในหน้า add_profile
  Future<bool> submitMembershipAfterVerify({
    required String phone,
    required String fullName,
    String? dormCode,
    String? roomNumber,
    String? inviteCode,
    String? avatarUrl,
  }) async {
    const label = 'submitMembershipAfterVerify';
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return false;

      if (inviteCode != null && inviteCode.trim().isNotEmpty) {
        final code = inviteCode.trim().toUpperCase();
        final invite = await _supabase
            .from('invitation_codes')
            .select('code, dormitory_id, room_id, expires_at, created_by')
            .eq('code', code)
            .maybeSingle();
        if (invite == null) return false;
        final expiresAt = DateTime.tryParse(invite['expires_at']?.toString() ?? '');
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) return false;
        final dormitoryId = invite['dormitory_id']?.toString();
        if (dormitoryId == null) return false;
        final inviterUid = invite['created_by']?.toString();
        if (inviterUid != null && inviterUid == uid) return false;
        final roomIdInvite = invite['room_id']?.toString();
        if (roomIdInvite != null && roomIdInvite.isNotEmpty) {
          final full = await _isRoomFull(roomIdInvite, uid);
          if (full) return false;
        }

        await _supabase.from('roommate_invites').upsert({
          'id': uid,
          'full_name': fullName,
          'phone': phone,
          'invite_code': code,
          'is_verified': true,
          'status': 'pending',
          if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        });

        await _submitMembership(
          uid: uid,
          dormitoryId: dormitoryId,
          memberType: 'roommate',
          roomId: roomIdInvite,
        );
        return true;
      }

      if (dormCode != null && dormCode.trim().isNotEmpty) {
        final code = dormCode.trim().toUpperCase();
        final dorm = await _supabase
            .from('dormitories')
            .select('id')
            .eq('dorm_code', code)
            .maybeSingle();
        if (dorm == null) return false;

        String? roomId;
        final room = (roomNumber ?? '').trim().toUpperCase();
        if (room.isNotEmpty) {
          final resolved = await _supabase.rpc(
            'resolve_room_id',
            params: {
              'p_dormitory_id': dorm['id'].toString(),
              'p_room_number': room,
            },
          );
          final rows = resolved is List ? resolved : <dynamic>[];
          roomId = rows.isNotEmpty ? rows.first['room_id']?.toString() : null;
        }

        await _supabase.from('tenants').upsert({
          'id': uid,
          'full_name': fullName,
          'phone': phone,
          'dorm_code': code,
          'status': 'pending',
          if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        });

        await _submitMembership(
          uid: uid,
          dormitoryId: dorm['id'].toString(),
          roomId: roomId,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('❌ $label Error: $e');
      return false;
    }
  }

  /// สร้าง/อัปเดตแถวใน dormitory_members ให้อยู่สถานะ pending
  /// - memberType: 'tenant' (ผู้เช่าหลัก) หรือ 'roommate'
  /// - มีแถวอยู่แล้วและถูกปฏิเสธ → รีเซ็ตเป็น pending
  /// - มีแถวอยู่แล้วและ pending/approved → ไม่ต้องทำอะไร
  Future<void> _submitMembership({
    required String uid,
    required String dormitoryId,
    String memberType = 'tenant',
    String? roomId,
  }) async {
    final existing = await _supabase
        .from('dormitory_members')
        .select('id, status')
        .eq('user_id', uid)
        .eq('dormitory_id', dormitoryId)
        .maybeSingle();

    if (existing != null) {
      if (existing['status'] == 'rejected') {
        await _supabase
            .from('dormitory_members')
            .update({'status': 'pending', 'room_id': roomId})
            .eq('id', existing['id']);
      }
      return;
    }

    await _supabase.from('dormitory_members').insert({
      'user_id': uid,
      'dormitory_id': dormitoryId,
      'status': 'pending',
      'member_type': memberType,
      'room_id': roomId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> signUpAdmin({
    required String phone,
    required String password,
    required String fullName,
    String? avatarUrl,
  }) async {
    const label = 'signUpAdmin';
    try {
      final uid = await _signUpOrSignIn(
        phone: phone,
        password: password,
        fullName: fullName,
        label: label,
      );
      if (uid == null) {
        print('❌ $label: ไม่สามารถเข้าสู่ระบบหลังลงทะเบียนได้');
        return false;
      }

      await _supabase.from('admins').upsert({
        'id': uid,
        'full_name': fullName,
        'phone': phone,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
      });
      print('✅ Admin created: $uid');
      return true;
    } catch (e) {
      print('❌ $label Error: $e');
      return false;
    }
  }

  Future<bool> signUpTenant({
    required String phone,
    required String password,
    required String fullName,
    required String dormCode,
    String roomNumber = '',
    void Function(String message)? onError,
  }) async {
    const label = 'signUpTenant';
    try {
      final code = dormCode.trim().toUpperCase();
      final room = roomNumber.trim().toUpperCase();

      // ตรวจรหัสหอพักก่อน เพื่อไม่ให้สร้าง user ค้างเมื่อรหัสผิด
      final dorm = await _supabase
          .from('dormitories')
          .select('id')
          .eq('dorm_code', code)
          .maybeSingle();

      if (dorm == null) {
        print('❌ $label: ไม่พบหอพักรหัส $code');
        return false;
      }

      // ตรวจเลขห้อง (ถ้ากรอก) ก่อนสร้าง user เพื่อผูกห้องที่ถูกต้อง
      // anon อ่านตาราง rooms ไม่ได้ (RLS) จึงใช้ security definer function
      String? roomId;
      if (room.isNotEmpty) {
        final resolved = await _supabase.rpc(
          'resolve_room_id',
          params: {
            'p_dormitory_id': dorm['id'].toString(),
            'p_room_number': room,
          },
        );

        final rows = resolved is List ? resolved : <dynamic>[];
        roomId = rows.isNotEmpty ? rows.first['room_id']?.toString() : null;

        if (roomId == null || roomId.isEmpty) {
          print('❌ $label: ไม่พบห้องหมายเลข $room ในหอพัก $code');
          onError?.call('ไม่พบห้องหมายเลข $room ในหอพัก $code');
          return false;
        }
      }

      final uid = await _signUpOrSignIn(
        phone: phone,
        password: password,
        fullName: fullName,
        label: label,
      );
      if (uid == null) {
        print('❌ $label: ไม่สามารถเข้าสู่ระบบหลังลงทะเบียนได้');
        return false;
      }

      await _supabase.from('tenants').upsert({
        'id': uid,
        'full_name': fullName,
        'phone': phone,
        'dorm_code': code,
        'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // ไม่สร้าง dormitory_members ที่นี่ ให้สร้างใน add_profile.dart
      print('✅ Tenant created: $uid');
      return true;
    } on AuthApiException catch (e) {
      if (e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already registered')) {
        print('⚠️ $label: user already exists');
      }
      print('❌ $label Error: $e');
      return false;
    } catch (e) {
      print('❌ $label Error: $e');
      return false;
    }
  }

  /// ลงทะเบียน Roommate โดยตรวจรหัสเชิญก่อน
  /// - รหัสเชิญต้องมีอยู่จริง ไม่หมดอายุ และยังไม่ถูกใช้
  /// - ดึง dormitory_id จากรหัส เพื่อผูก Roommate เข้าห้องเดียวกับผู้ออกรหัส
  /// - สร้างแถวใน dormitory_members (status: pending) ให้แอดมินอนุมัติที่ request.dart
  Future<bool> signUpRoommate({
    required String phone,
    required String password,
    required String fullName,
    required String inviteCode,
    void Function(String message)? onError,
  }) async {
    const label = 'signUpRoommate';
    try {
      final code = inviteCode.trim().toUpperCase();
      if (code.isEmpty) {
        print('❌ $label: ไม่ได้กรอกรหัสคำเชิญ');
        onError?.call('กรุณากรอกรหัสคำเชิญ');
        return false;
      }

      // ตรวจรหัสเชิญในฐานข้อมูลก่อนสร้างผู้ใช้
      final invite = await _supabase
          .from('invitation_codes')
          .select('code, dormitory_id, room_id, expires_at, created_by')
          .eq('code', code)
          .maybeSingle();

      if (invite == null) {
        print('❌ $label: ไม่พบรหัสเชิญ $code');
        onError?.call(
          'ไม่พบรหัสคำเชิญ $code\nกรุณาตรวจสอบว่าถูกต้องและยังไม่หมดอายุ',
        );
        return false;
      }

      final expiresAt = DateTime.tryParse(
        invite['expires_at']?.toString() ?? '',
      );
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        print('❌ $label: รหัสเชิญ $code หมดอายุแล้ว');
        onError?.call('รหัสคำเชิญหมดอายุแล้ว\nกรุณาขอรหัสใหม่จากผู้เช่าหลัก');
        return false;
      }

      // กันผู้ออกรหัสใช้รหัสของตัวเองเข้าร่วมห้องตัวเอง
      final inviterUid = invite['created_by']?.toString();
      final dormitoryId = invite['dormitory_id']?.toString();
      if (dormitoryId == null) {
        print('❌ $label: รหัสเชิญ $code ไม่ผูกกับหอพัก');
        onError?.call('รหัสคำเชิญนี้ไม่สมบูรณ์\nกรุณาขอรหัสใหม่จากผู้เช่าหลัก');
        return false;
      }

      final uid = await _signUpOrSignIn(
        phone: phone,
        password: password,
        fullName: fullName,
        label: label,
      );
      if (uid == null) {
        print('❌ $label: ไม่สามารถเข้าสู่ระบบหลังลงทะเบียนได้');
        onError?.call('ลงทะเบียนไม่สำเร็จ กรุณาลองอีกครั้ง');
        return false;
      }

      if (inviterUid != null && inviterUid == uid) {
        print('❌ $label: ไม่สามารถใช้รหัสเชิญของตัวเองได้');
        onError?.call('ไม่สามารถใช้รหัสคำเชิญของตัวเองได้');
        return false;
      }

      // ตรวจว่าห้องเต็มหรือยัง (เทียบจำนวนสมาชิก approved กับ max_tenants)
      // รหัสเชิญ 1 รหัสใช้ได้หลายคน แต่เข้าได้ไม่เกิน max ของห้อง
      final roomId = invite['room_id']?.toString();
      if (roomId != null && roomId.isNotEmpty) {
        final full = await _isRoomFull(roomId, uid);
        if (full) {
          print('❌ $label: ห้อง $roomId เต็มแล้ว');
          onError?.call('ห้องนี้เต็มแล้ว ไม่สามารถเข้าร่วมได้');
          return false;
        }
      }

      await _supabase.from('roommate_invites').upsert({
        'id': uid,
        'full_name': fullName,
        'phone': phone,
        'invite_code': code,
        'is_verified': false,
        'status': 'pending',
      });

      // ไม่สร้าง dormitory_members ที่นี่ ให้สร้างใน add_profile.dart
      print('✅ Roommate created: $uid');
      return true;
    } on AuthApiException catch (e) {
      if (e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already registered')) {
        print('⚠️ $label: user already exists');
      }
      print('❌ $label Error: $e');
      return false;
    } catch (e) {
      print('❌ $label Error: $e');
      return false;
    }
  }

  Future<Map<String, String>> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      try {
        await _supabase.auth.signInWithPassword(
          email: _authEmail(phone),
          password: password,
        );
      } catch (e) {
        // ถ้าเข้าสู่ระบบไม่ได้ ลองสมัคร (กรณีมีข้อมูลในตารางแต่ยังไม่มี auth user)
        try {
          await _supabase.auth.signUp(
            email: _authEmail(phone),
            password: password,
          );
          await _supabase.auth.signInWithPassword(
            email: _authEmail(phone),
            password: password,
          );
        } catch (_) {
          rethrow;
        }
      }
      final uid = _supabase.auth.currentUser!.id;

      final admin = await _supabase
          .from('admins')
          .select('full_name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (admin != null) {
        return {
          'role': 'admin',
          'full_name': (admin['full_name'] as String?) ?? '',
          'phone': admin['phone']?.toString() ?? '',
        };
      }

      final tenant = await _supabase
          .from('tenants')
          .select('full_name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (tenant != null) {
        return {
          'role': 'tenant',
          'full_name': (tenant['full_name'] as String?) ?? '',
          'phone': tenant['phone']?.toString() ?? '',
        };
      }

      final roommate = await _supabase
          .from('roommate_invites')
          .select('full_name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (roommate != null) {
        return {
          'role': 'roommate',
          'full_name': (roommate['full_name'] as String?) ?? '',
          'phone': roommate['phone']?.toString() ?? '',
        };
      }

      return {'role': 'unknown', 'full_name': '', 'phone': ''};
    } catch (e) {
      print('❌ signIn Error: $e');
      return {'role': 'error', 'full_name': '', 'phone': ''};
    }
  }

  Future<Map<String, String>?> getUserData() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final tables = [
        {'table': 'admins', 'role': 'admin'},
        {'table': 'tenants', 'role': 'tenant'},
        {'table': 'roommate_invites', 'role': 'roommate'},
      ];
      for (final t in tables) {
        final result = await _supabase
            .from(t['table'] as String)
            .select('full_name, phone')
            .eq('id', uid)
            .maybeSingle();
        if (result != null) {
          return {
            'full_name': (result['full_name'] as String?) ?? '',
            'phone': result['phone']?.toString() ?? '',
            'role': t['role'] as String,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ getUserData Error: $e');
      return null;
    }
  }

  /// เปลี่ยนรหัสผ่าน (ผู้ใช้ login อยู่ รู้รหัสเดิม)
  /// [oldPassword] ใช้ยืนยันรหัสเดิมก่อนเปลี่ยน
  /// คืน true เมื่อสำเร็จ
  Future<String?> changePassword({
    required String phone,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // ใช้ email ของ session ปัจจุบันก่อน (แม่นยำกว่าการสร้างจากเบอร์
      // เพราะ _userPhoneNumber อาจเป็นค่า default หรือรูปแบบไม่ตรงตอนสมัคร)
      final sessionEmail = _supabase.auth.currentUser?.email;
      final email = (sessionEmail != null && sessionEmail.isNotEmpty)
          ? sessionEmail
          : _authEmail(phone);

      // ยืนยันรหัสเดิมก่อน (sign in ซ้ำด้วยรหัสเดิม)
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: oldPassword,
        );
      } on AuthApiException catch (e) {
        print('❌ changePassword verify old password: ${e.message}');
        return 'รหัสผ่านเดิมไม่ถูกต้อง';
      }

      // ตั้งรหัสใหม่
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null; // สำเร็จ
    } on AuthApiException catch (e) {
      print('❌ changePassword updateUser: ${e.message}');
      // เช่น "New password should be different from the old password."
      if (e.message.toLowerCase().contains('different')) {
        return 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม';
      }
      return e.message;
    } catch (e) {
      print('❌ changePassword error: $e');
      return 'เปลี่ยนรหัสผ่านไม่สำเร็จ: $e';
    }
  }

  /// ลืมรหัสผ่าน (ไม่ได้ login) — ยืนยันด้วย เบอร์ + ชื่อ-นามสกุล
  /// เรียก Edge Function 'reset-password' ที่ใช้ service_role ตั้งรหัสใหม่
  /// คืน {success, error}
  Future<Map<String, dynamic>> resetPasswordByIdentity({
    required String phone,
    required String fullName,
    required String newPassword,
  }) async {
    try {
      final res = await _supabase.functions.invoke(
        'reset-password',
        body: {
          'phone': phone.trim(),
          'fullName': fullName.trim(),
          'newPassword': newPassword,
        },
      );
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return {'success': true};
      }
      final err = (data is Map ? data['error'] : null)?.toString() ??
          'รีเซ็ตรหัสผ่านไม่สำเร็จ';
      return {'success': false, 'error': err};
    } catch (e) {
      print('❌ resetPasswordByIdentity error: $e');
      return {'success': false, 'error': 'เชื่อมต่อระบบไม่สำเร็จ'};
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  bool isLoggedIn() => _supabase.auth.currentUser != null;
  String? getUserId() => _supabase.auth.currentUser?.id;
}
