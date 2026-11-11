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
      return _resolveUserId(
        phone: phone,
        password: password,
        label: label,
      );
    } on AuthApiException catch (e) {
      final alreadyExists =
          e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already registered');
      if (!alreadyExists) rethrow;
      print('⚠️ $label: เบอร์นี้มีบัญชีอยู่แล้ว → เข้าสู่ระบบแทนการลงทะเบียนใหม่');
      return _resolveUserId(
        phone: phone,
        password: password,
        label: label,
      );
    }
  }

  /// สร้าง/อัปเดตแถวใน dormitory_members ให้อยู่สถานะ pending
  /// - memberType: 'tenant' (ผู้เช่าหลัก) หรือ 'roommate'
  /// - มีแถวอยู่แล้วและถูกปฏิเสธ → รีเซ็ตเป็น pending
  /// - มีแถวอยู่แล้วและ pending/approved → ไม่ต้องทำอะไร
  /// หมายเหตุ: ตาราง dormitory_members ไม่มีคอลัมน์ role/room_id
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
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> signUpAdmin({
    required String phone,
    required String password,
    required String fullName,
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
        final resolved = await _supabase.rpc('resolve_room_id', params: {
          'p_dormitory_id': dorm['id'].toString(),
          'p_room_number': room,
        });

        final rows = resolved is List ? resolved : <dynamic>[];
        roomId =
            rows.isNotEmpty ? rows.first['room_id']?.toString() : null;

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
        'created_at': DateTime.now().toIso8601String(),
      });

      await _submitMembership(
        uid: uid,
        dormitoryId: dorm['id'].toString(),
        roomId: roomId,
      );

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
            'ไม่พบรหัสคำเชิญ $code\nกรุณาตรวจสอบว่าถูกต้องและยังไม่หมดอายุ');
        return false;
      }

      final expiresAt = DateTime.tryParse(invite['expires_at']?.toString() ?? '');
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

      await _supabase.from('roommate_invites').upsert({
        'id': uid,
        'full_name': fullName,
        'phone': phone,
        'invite_code': code,
        'is_verified': false,
        'status': 'pending',
      });

      // ผูก Roommate เข้าหอพักเดียวกับผู้เช่าหลักที่ออกรหัส
      // room_id มาจากรหัสเชิญ → Roommate ได้ห้องเดียวกับผู้ออกรหัส
      await _submitMembership(
        uid: uid,
        dormitoryId: dormitoryId,
        memberType: 'roommate',
        roomId: invite['room_id']?.toString(),
      );

      print('✅ Roommate created: $uid (dormitory $dormitoryId)');
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
      await _supabase.auth.signInWithPassword(
        email: _authEmail(phone),
        password: password,
      );
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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  bool isLoggedIn() => _supabase.auth.currentUser != null;
  String? getUserId() => _supabase.auth.currentUser?.id;
}
