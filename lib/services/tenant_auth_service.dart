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

      // insert ใหม่ (ตาราง dormitory_members ไม่มีคอลัมน์ role/room_id)
      await _db.from('dormitory_members').insert({
        'user_id': uid,
        'dormitory_id': dormitoryId,
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

  // ── 5b. ดึง dormitory_id ของแอดมิน ────────────────────────────────────────
  Future<String?> getAdminDormitoryId() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;

      // dormitory ที่ admin สร้าง (created_by = uid)
      final dormRow = await _db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return dormRow?['id']?.toString();
    } catch (e) {
      print('❌ getAdminDormitoryId error: $e');
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

  // ── 9. ดึงข้อมูลประกาศของหอพัก ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDormAnnouncements() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return [];
      final member = await _db
          .from('dormitory_members')
          .select('dormitory_id')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .limit(1)
          .maybeSingle();
      if (member == null) return [];
      final dormId = member['dormitory_id'] as String;
      final rows = await _db
          .from('announcements')
          .select('id, title, content, image_url, created_at')
          .eq('dormitory_id', dormId)
          .order('created_at', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => {
                'id': r['id'],
                'title': r['title'] ?? '',
                'content': r['content'] ?? '',
                'image': r['image_url'] ?? '',
                'date': r['created_at'] ?? '',
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── 10. ดึงบิลของผู้เช่า ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTenantBills() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return [];
      final rows = await _db
          .from('bills')
          .select('id, month, total, due_date, status')
          .eq('tenant_id', uid)
          .order('due_date', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => {
                'id': r['id'],
                'month': r['month'] ?? '',
                'total': r['total'] ?? 0,
                'due_date': r['due_date'] ?? '',
                'status': r['status'] ?? 'pending',
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── 11. ดึงรายการแจ้งซ่อม ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTenantRepairs() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return [];
      final rows = await _db
          .from('repairs')
          .select('id, room_number, title, description, created_at, status')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => {
                'id': r['id'],
                'room': r['room_number'] ?? '',
                'title': r['title'] ?? '',
                'description': r['description'] ?? '',
                'date': r['created_at'] ?? '',
                'status': r['status'] ?? '',
              })
            .toList();
    } catch (e) {
      return [];
    }
  }

  // ── 12. ดึงรายชื่อผู้เช่าทั้งหมดในหอพัก (สำหรับ Admin) ─────────────────────
  Future<List<Map<String, dynamic>>> getDormitoryTenants() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return [];

      final rows = await _db.rpc('get_dormitory_tenants', params: {
        'admin_uid': uid,
      });

      return (rows as List).map((r) => {
        'id': r['member_id']?.toString() ?? '',
        'name': r['name'] ?? '',
        'phone': r['phone']?.toString() ?? '',
        'room': r['room_number']?.toString() ?? '',
        'role': r['role'] == 'tenant' ? 'ผู้เช่าหลัก' : 'Roommate',
        'status': r['status'] == 'approved' ? 'กำลังเช่า' :
                  r['status'] == 'pending'  ? 'รอการอนุมัติ' : 'ไม่ได้รับอนุมัติ',
        'member_id': r['member_id']?.toString() ?? '',
        'building': r['building']?.toString() ?? '',
        'floor': r['floor']?.toString() ?? '',
        'check_in':  '',
        'check_out': '',
        'rent':    '',
        'deposit': '',
      }).toList();
    } catch (e) {
      print('❌ getDormitoryTenants error: $e');
      return [];
    }
  }

  // ── 13. ดึงข้อมูลการเช่าของ user ปัจจุบัน ────────────────────────────────
  Future<Map<String, String>?> getTenantRentalInfo() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;

      // ดึงจาก tenant_rentals ก่อน (ข้อมูลที่ admin กรอกเพิ่มเติม)
      final rentalRow = await _db
          .from('tenant_rentals')
          .select('building, room_number, floor, check_in_date, check_out_date, rent, deposit')
          .eq('member_id', uid)
          .maybeSingle();

      // ดึงเลขห้องจาก dormitory_members → rooms (ข้อมูลที่ผู้เช่ากรอกตอน sign up)
      final memberRow = await _db
          .from('dormitory_members')
          .select('room_id, rooms(room_number, floor, building)')
          .eq('user_id', uid)
          .maybeSingle();

      final roomData = memberRow?['rooms'] as Map<String, dynamic>?;
      final signupRoomNumber = roomData?['room_number']?.toString() ?? '';
      final signupFloor      = roomData?['floor']?.toString() ?? '';
      final signupBuilding   = roomData?['building']?.toString() ?? '';

      return {
        'building': rentalRow?['building']?.toString().isNotEmpty == true
            ? rentalRow!['building'].toString()
            : signupBuilding,
        'room': rentalRow?['room_number']?.toString().isNotEmpty == true
            ? rentalRow!['room_number'].toString()
            : signupRoomNumber,
        'floor': rentalRow?['floor']?.toString().isNotEmpty == true
            ? rentalRow!['floor'].toString()
            : signupFloor,
        'check_in':  rentalRow?['check_in_date']?.toString() ?? '',
        'check_out': rentalRow?['check_out_date']?.toString() ?? '',
        'rent':      rentalRow?['rent']?.toString() ?? '',
        'deposit':   rentalRow?['deposit']?.toString() ?? '',
      };
    } catch (e) {
      print('❌ getTenantRentalInfo error: $e');
      return null;
    }
  }

  // ── 14. บันทึกข้อมูลส่วนตัวของผู้เช่า ───────────────────────────────────────
  /// บันทึกข้อมูลที่ผู้เช่ากรอกในหน้าแก้ไขข้อมูลการเช่า
  /// ใช้ member_id = auth user ID (สอดคล้องกับ getTenantRentalInfo)
  Future<bool> saveTenantPersonalInfo({
    required String idCard,
    required String birthdate,
    required String gender,
    required String address,
    required String emergencyContact,
    required String emergencyPhone,
  }) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;

      await _db.from('tenant_rentals').upsert({
        'member_id': uid,
        'id_card': idCard,
        'birthdate': birthdate,
        'gender': gender,
        'address': address,
        'emergency_contact': emergencyContact,
        'emergency_phone': emergencyPhone,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ saveTenantPersonalInfo error: $e');
      return false;
    }
  }

  // ── 15. ดึงข้อมูลส่วนตัวของผู้เช่าจาก tenant_rentals ────────────────────────
  /// ใช้สำหรับ admin ดูข้อมูลที่ผู้เช่ากรอกเอง
  Future<Map<String, String>?> getTenantPersonalInfo(String memberId) async {
    try {
      final row = await _db
          .from('tenant_rentals')
          .select('id_card, birthdate, gender, address, emergency_contact, emergency_phone')
          .eq('member_id', memberId)
          .maybeSingle();

      if (row == null) return null;

      return {
        'idCard': row['id_card']?.toString() ?? '',
        'birthdate': row['birthdate']?.toString() ?? '',
        'gender': row['gender']?.toString() ?? '',
        'address': row['address']?.toString() ?? '',
        'emergencyContact': row['emergency_contact']?.toString() ?? '',
        'emergencyPhone': row['emergency_phone']?.toString() ?? '',
      };
    } catch (e) {
      print('❌ getTenantPersonalInfo error: $e');
      return null;
    }
  }

  // ── 16. บันทึก/อัปเดตประกาศ ───────────────────────────────────────────────
  /// สำหรับแอดมินสร้าง/แก้ไขประกาศ
  Future<bool> saveAnnouncement({
    required String title,
    required String content,
    String? imageUrl,
    required String dormitoryId,
    String? announcementId, // null = create new, non-null = update
    bool isDraft = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;

      final data = {
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'dormitory_id': dormitoryId,
        'created_by': uid,
        'status': isDraft ? 'draft' : 'published',
        'start_date': startDate?.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (announcementId != null && announcementId.isNotEmpty) {
        // Update existing
        await _db.from('announcements').update(data).eq('id', announcementId);
      } else {
        // Create new
        data['created_at'] = DateTime.now().toIso8601String();
        await _db.from('announcements').insert(data);
      }

      return true;
    } catch (e) {
      print('❌ saveAnnouncement error: $e');
      return false;
    }
  }
}
