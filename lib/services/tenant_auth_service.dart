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
        'created_at': DateTime.now().toUtc().toIso8601String(),
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
        'created_at': DateTime.now().toUtc().toIso8601String(),
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
          .select('status, dormitory_id, dormitories!dormitory_members_dormitory_id_fkey(dorm_name, dorm_code)')
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
          .select('id, room_number, category, description, created_at, status')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => {
                'id': r['id'],
                'room': r['room_number'] ?? '',
                'title': r['category'] ?? '',
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

      final result = <Map<String, dynamic>>[];
      for (final r in (rows as List)) {
        final memberId = r['member_id']?.toString() ?? r['id']?.toString() ?? '';
        String avatarUrl = r['avatar_url']?.toString() ?? r['avatar']?.toString() ?? '';

        if (avatarUrl.isEmpty && memberId.isNotEmpty) {
          try {
            final memberRow = await _db
                .from('dormitory_members')
                .select('user_id')
                .eq('id', memberId)
                .maybeSingle();
            final userId = memberRow?['user_id']?.toString();
            if (userId != null && userId.isNotEmpty) {
              final tenantRow = await _db
                  .from('tenants')
                  .select('avatar_url')
                  .eq('id', userId)
                  .maybeSingle();
              avatarUrl = tenantRow?['avatar_url']?.toString() ?? '';

              if (avatarUrl.isEmpty) {
                final roommateRow = await _db
                    .from('roommate_invites')
                    .select('avatar_url')
                    .eq('id', userId)
                    .maybeSingle();
                avatarUrl = roommateRow?['avatar_url']?.toString() ?? '';
              }

              if (avatarUrl.isEmpty) {
                final profileRow = await _db
                    .from('profiles')
                    .select('avatar_url')
                    .eq('id', userId)
                    .maybeSingle();
                avatarUrl = profileRow?['avatar_url']?.toString() ?? '';
              }

              if (avatarUrl.isEmpty) {
                final userRow = await _db.auth.admin.getUserById(userId);
                final meta = userRow.user?.userMetadata ?? {};
                avatarUrl = (meta['avatar_url'] ?? meta['picture'] ?? '').toString();
              }
            }
          } catch (e) {
            // ignore avatar fetch errors
          }
        }

        result.add({
          'id': memberId,
          'name': r['name'] ?? r['full_name'] ?? '',
          'phone': r['phone']?.toString() ?? '',
          'room': r['room_number']?.toString() ?? r['room']?.toString() ?? '',
          'role': r['role'] == 'tenant' ? 'ผู้เช่าหลัก' : (r['role'] == 'roommate' ? 'Roommate' : (r['role'] ?? '')),
          'status': r['status'] == 'approved' ? 'กำลังเช่า' :
                    r['status'] == 'pending'  ? 'รอการอนุมัติ' : (r['status'] == 'rejected' ? 'ไม่ได้รับอนุมัติ' : (r['status'] ?? '')),
          'member_id': memberId,
          'building': r['building']?.toString() ?? '',
          'floor': r['floor']?.toString() ?? '',
          'check_in':  r['check_in']?.toString() ?? r['check_in_date']?.toString() ?? '',
          'check_out': r['check_out']?.toString() ?? r['check_out_date']?.toString() ?? '',
          'rent':    r['rent']?.toString() ?? '',
          'deposit': r['deposit']?.toString() ?? '',
          'avatar_url': avatarUrl,
          'user_id': r['user_id']?.toString() ?? '',
        });
      }

      return result;
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

      // ดึงจาก tenant_rentals ก่อน (admin กรอกข้อมูลการเช่า + ผู้เช่ากรอกข้อมูลส่วนตัว)
      final rentalRow = await _db
          .from('tenant_rentals')
          .select(
              'building, room_number, floor, check_in_date, check_out_date, rent, deposit, id_card, birthdate, gender, address, emergency_contact, emergency_phone, documents')
          .eq('member_id', uid)
          .maybeSingle();

      // ดึงเลขห้องจาก dormitory_members → rooms (ข้อมูลที่ผู้เช่ากรอกตอน sign up)
      final memberRow = await _db
          .from('dormitory_members')
          .select('room_id, rooms!dormitory_members_room_id_fkey(room_number, floor, building)')
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
        // ข้อมูลส่วนตัว/ติดต่อ/เอกสาร (ผู้เช่ากรอกเอง)
        'idCard':           rentalRow?['id_card']?.toString() ?? '',
        'birthdate':        rentalRow?['birthdate']?.toString() ?? '',
        'gender':           rentalRow?['gender']?.toString() ?? '',
        'address':          rentalRow?['address']?.toString() ?? '',
        'emergencyContact': rentalRow?['emergency_contact']?.toString() ?? '',
        'emergencyPhone':   rentalRow?['emergency_phone']?.toString() ?? '',
        'documents':        rentalRow?['documents']?.toString() ?? '',
      };
    } catch (e) {
      print('❌ getTenantRentalInfo error: $e');
      return null;
    }
  }

  // ── 14. บันทึกข้อมูลส่วนตัวของผู้เช่า ───────────────────────────────────────
  /// บันทึกข้อมูลที่ผู้เช่ากรอกในหน้าแก้ไขข้อมูลการเช่า
  /// ใช้ member_id = auth user ID (สอดคล้องกับ getTenantRentalInfo)
  /// [name] / [phone] → อัปเดตชื่อ-เบอร์ในตารางที่ผู้เช่าของตัวเองอยู่
  ///   (ผู้เช่าหลัก = tenants, Roommate = roommate_invites)
  Future<bool> saveTenantPersonalInfo({
    required String idCard,
    required String birthdate,
    required String gender,
    required String address,
    required String emergencyContact,
    required String emergencyPhone,
    String? name,
    String? phone,
    String? documents,
  }) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;

      final data = {
        'member_id': uid,
        'id_card': idCard,
        'birthdate': birthdate,
        'gender': gender,
        'address': address,
        'emergency_contact': emergencyContact,
        'emergency_phone': emergencyPhone,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (documents != null) data['documents'] = documents;

      await _db.from('tenant_rentals').upsert(data);

      // อัปเดตชื่อ-เบอร์ให้ตรงกับที่ผู้เช่ากรอก
      await _updateContactInfo(uid, name, phone);

      return true;
    } catch (e) {
      print('❌ saveTenantPersonalInfo error: $e');
      return false;
    }
  }

  /// อัปเดตชื่อ/เบอร์ของผู้เช่าปัจจุบัน
  /// (ผู้เช่าหลักเก็บใน tenants, Roommate เก็บใน roommate_invites → อัปเดตทั้งสองตาราง)
  Future<void> _updateContactInfo(
      String uid, String? name, String? phone) async {
    final patch = <String, String>{};
    if (name != null && name.trim().isNotEmpty) {
      patch['full_name'] = name.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      patch['phone'] = phone.trim();
    }
    if (patch.isEmpty) return;

    try {
      await _db.from('tenants').update(patch).eq('id', uid);
    } catch (e) {
      print('⚠️ update tenants error: $e');
    }
    try {
      await _db.from('roommate_invites').update(patch).eq('id', uid);
    } catch (e) {
      print('⚠️ update roommate_invites error: $e');
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
  Future<bool> saveAnnouncement({
    required String title,
    required String content,
    String? imageUrl,
    required String dormitoryId,
    String? announcementId,
    bool isDraft = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;

      final data = <String, dynamic>{
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'dormitory_id': dormitoryId,
        'created_by': uid,
        'status': isDraft ? 'draft' : 'published',
        'start_date': startDate?.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (announcementId != null && announcementId.isNotEmpty) {
        await _db.from('announcements').update(data).eq('id', announcementId);
      } else {
        data['created_at'] = DateTime.now().toUtc().toIso8601String();
        await _db.from('announcements').insert(data);
      }

      return true;
    } catch (e) {
      print('❌ saveAnnouncement error: $e');
      return false;
    }
  }

  // ── 17. ลบประกาศ ─────────────────────────────────────────────────────────
  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;

      final announcement = await _db
          .from('announcements')
          .select('dormitory_id, created_by')
          .eq('id', announcementId)
          .maybeSingle();

      if (announcement == null) return false;

      final dormitoryId = announcement['dormitory_id'] as String;
      final createdBy = announcement['created_by'] as String;

      final dorm = await _db
          .from('dormitories')
          .select('created_by')
          .eq('id', dormitoryId)
          .maybeSingle();

      final isAdmin = dorm?['created_by'] == uid;
      final isOwner = createdBy == uid;

      if (!isAdmin && !isOwner) return false;

      await _db.from('announcements').delete().eq('id', announcementId);
      return true;
    } catch (e) {
      print('❌ deleteAnnouncement error: $e');
      return false;
    }
  }
}
