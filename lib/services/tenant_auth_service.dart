import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TenantAuthService
//  ดูแล Google Sign-In flow ของผู้เช่า:
//    1. signInWithGoogle()          — OAuth ผ่าน Supabase + Google
//    2. validateDormCode()          — ตรวจสอบรหัสหอพัก
//    3. submitTenantRequest()       — สร้าง profile + dormitory_members (pending)
//    4. checkTenantMemberStatus()   — ดึงสถานะล่าสุดของผู้เช่า
//    5. getTenantDormInfo()         — ดึงชื่อ/รหัสหอพักของผู้เช่า
// ─────────────────────────────────────────────────────────────────────────────
class TenantAuthService {
  final _db = Supabase.instance.client;

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── 1. Google Sign-In ─────────────────────────────────────────────────────
  /// คืน null เมื่อ user ยกเลิก หรือ error
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) return null;

      final res = await _db.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return res.user;
    } catch (e) {
      print('❌ signInWithGoogle error: $e');
      return null;
    }
  }

  // ── 2. ตรวจสอบรหัสหอพัก ──────────────────────────────────────────────────
  /// คืน Map ของ dormitory row หรือ null ถ้าไม่พบ
  Future<Map<String, dynamic>?> validateDormCode(String dormCode) async {
    try {
      final row = await _db
          .from('dormitories')
          .select('id, dorm_code, dorm_name, address')
          .eq('dorm_code', dormCode.trim().toUpperCase())
          .maybeSingle();
      return row;
    } catch (e) {
      print('❌ validateDormCode error: $e');
      return null;
    }
  }

  // ── 3. สร้าง Tenant Request ───────────────────────────────────────────────
  /// - upsert ลง profiles
  /// - insert ลง dormitory_members (role=tenant, status=pending)
  /// คืน true เมื่อสำเร็จ
  Future<bool> submitTenantRequest({
    required String fullName,
    required String phone,
    required String dormitoryId,
    String? avatarUrl,
  }) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;

      // upsert profiles
      await _db.from('profiles').upsert({
        'id': uid,
        'full_name': fullName,
        'phone': phone,
        'role': 'tenant',
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // ตรวจสอบว่าเคยส่งคำขอสำหรับหอพักนี้แล้วหรือยัง
      final existing = await _db
          .from('dormitory_members')
          .select('id, status')
          .eq('user_id', uid)
          .eq('dormitory_id', dormitoryId)
          .maybeSingle();

      if (existing != null) {
        // ถ้าเคยถูกปฏิเสธ → reset เป็น pending ใหม่
        if (existing['status'] == 'rejected') {
          await _db
              .from('dormitory_members')
              .update({'status': 'pending'})
              .eq('id', existing['id']);
        }
        // ถ้า pending หรือ approved อยู่แล้ว → ไม่ต้องทำอะไร
        return true;
      }

      // insert ใหม่
      await _db.from('dormitory_members').insert({
        'user_id': uid,
        'dormitory_id': dormitoryId,
        'room_id': null,
        'role': 'tenant',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ submitTenantRequest error: $e');
      return false;
    }
  }

  // ── 4. ตรวจสอบสถานะผู้เช่า ───────────────────────────────────────────────
  /// คืน 'pending' | 'approved' | 'rejected' | 'no_request' | 'no_auth'
  Future<String> checkTenantMemberStatus() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return 'no_auth';

      final row = await _db
          .from('dormitory_members')
          .select('status')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return 'no_request';
      return (row['status'] as String?) ?? 'no_request';
    } catch (e) {
      print('❌ checkTenantMemberStatus error: $e');
      return 'no_auth';
    }
  }

  // ── 5. ดึงข้อมูลหอพักของผู้เช่า ──────────────────────────────────────────
  /// คืน {dorm_name, dorm_code, status} หรือ null
  Future<Map<String, dynamic>?> getTenantDormInfo() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;

      final row = await _db
          .from('dormitory_members')
          .select('status, dormitory_id, dormitories(dorm_name, dorm_code)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return null;

      final dorm = row['dormitories'] as Map<String, dynamic>?;
      return {
        'status': row['status'] ?? '',
        'dormitory_id': row['dormitory_id'] ?? '',
        'dorm_name': dorm?['dorm_name'] ?? '',
        'dorm_code': dorm?['dorm_code'] ?? '',
      };
    } catch (e) {
      print('❌ getTenantDormInfo error: $e');
      return null;
    }
  }

  // ── 6. ดึง profile ของ user ปัจจุบัน ─────────────────────────────────────
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;

      final row = await _db
          .from('profiles')
          .select('id, full_name, phone, role, avatar_url')
          .eq('id', uid)
          .maybeSingle();

      // ถ้าไม่มี profile ให้ดึงจาก auth metadata แทน
      if (row == null) {
        final user = _db.auth.currentUser;
        final meta = user?.userMetadata ?? {};
        return {
          'id': uid,
          'full_name': meta['full_name'] ?? meta['name'] ?? '',
          'avatar_url': meta['avatar_url'] ?? meta['picture'] ?? '',
          'phone': '',
          'role': 'tenant',
        };
      }
      return row;
    } catch (e) {
      print('❌ getCurrentProfile error: $e');
      return null;
    }
  }

  // ── 7. Sign Out ───────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _db.auth.signOut();
  }

  // ── 8. ตรวจสอบ session ปัจจุบัน ──────────────────────────────────────────
  bool get isLoggedIn => _db.auth.currentUser != null;
  User? get currentUser => _db.auth.currentUser;
}
