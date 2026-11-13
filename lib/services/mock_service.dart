import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  SupabaseService  — ดึงข้อมูลจริงจาก Supabase
//  ทุก method คืน Future และมี fallback กรณี error/ว่างเปล่า
// ─────────────────────────────────────────────────────────────

class MockService {
  final _db = Supabase.instance.client;

  // ── user ที่ login อยู่ ────────────────────────────────────

  /// ตรวจว่า user ที่ login อยู่เป็น Roommate ไหม
  /// (member_type = 'roommate' ใน dormitory_members)
  Future<bool> isCurrentUserRoommate() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return false;
      final row = await _db
          .from('dormitory_members')
          .select('member_type')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row?['member_type']?.toString() == 'roommate';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>> getCurrentUser() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return _fallbackUser();

      for (final entry in [
        {'table': 'admins',           'role': 'admin'},
        {'table': 'tenants',          'role': 'tenant'},
        {'table': 'roommate_invites', 'role': 'roommate'},
      ]) {
        final row = await _db
            .from(entry['table']!)
          .select('full_name, phone, avatar_url')
            .eq('id', uid)
            .maybeSingle();
        if (row != null) {
          return {
            'full_name': (row['full_name'] as String?) ?? '',
            'phone':     (row['phone']?.toString()) ?? '',
            'avatar_url': (row['avatar_url'] as String?) ?? '',
            'role':      entry['role']!,
          };
        }
      }
      return _fallbackUser();
    } catch (_) {
      return _fallbackUser();
    }
  }

  Map<String, String> _fallbackUser() => {
        'full_name': 'พัชราวรรณ ศรีบุญ',
        'phone':     '099-9999999',
        'role':      'tenant',
      };

  // ── ห้องของผู้เช่าที่ login ───────────────────────────────
  Future<Map<String, dynamic>> getTenantRoom() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return _fallbackRoom();

      // 1. ดึงจาก dormitory_members ที่ approved แล้ว (ห้องที่ admin ยืนยัน)
      final approvedRow = await _db
          .from('dormitory_members')
          .select('room_id, rooms!dormitory_members_room_id_fkey(room_number, floor, building, status, dormitory_id)')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .maybeSingle();

      final approvedRoom = approvedRow?['rooms'] as Map<String, dynamic>?;
      if (approvedRoom != null && (approvedRoom['room_number'] ?? '').toString().isNotEmpty) {
        final result = Map<String, dynamic>.from(approvedRoom);
        result['room_id'] = approvedRow?['room_id']?.toString() ?? '';
        return result;
      }

      // 2. fallback: ดึงจาก dormitory_members ที่ pending (ห้องที่เลือกตอน sign up)
      final pendingRow = await _db
          .from('dormitory_members')
          .select('room_id, rooms!dormitory_members_room_id_fkey(room_number, floor, building, status, dormitory_id)')
          .eq('user_id', uid)
          .maybeSingle();

      final pendingRoom = pendingRow?['rooms'] as Map<String, dynamic>?;
      if (pendingRoom != null && (pendingRoom['room_number'] ?? '').toString().isNotEmpty) {
        return Map<String, dynamic>.from(pendingRoom);
      }

      return _fallbackRoom();
    } catch (_) {
      return _fallbackRoom();
    }
  }

  Map<String, dynamic> _fallbackRoom() => {
        'room_number': '',
        'floor':       '',
        'building':    '',
        'status':      '',
      };

  // ── บิลปัจจุบัน (pending ล่าสุด) ─────────────────────────
  Future<Map<String, dynamic>> getCurrentBill({String? roomNumber, String? roomId}) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return _fallbackBill();

      // 1) หาบิลที่ผูกกับ user โดยตรง
      var row = await _db
          .from('bills')
          .select('id, month, rent, electricity, water, penalty, total, due_date, status, qr_image_url')
          .eq('tenant_id', uid)
          .inFilter('status', ['pending', 'review'])
          .order('due_date', ascending: false)
          .limit(1)
          .maybeSingle();

      // 2) ถ้ายังไม่เจอ ให้หาบิลของห้องตัวเอง (Roommate เห็นบิลเดียวกับผู้เช่าหลักของห้อง)
      //    ถ้าผู้เรียกไม่ได้ส่งเลขห้องมา ให้หาจากห้องที่ผู้ใช้เป็นสมาชิก
      //    และจำกัดเฉพาะหอพักของตัวเอง กันเลขห้องซ้ำกับหอพักอื่น
      String? dormId;
      var room = roomNumber;
      if (row == null) {
        final myRoom = await getTenantRoom();
        if (room == null || room.isEmpty) {
          room = myRoom['room_number']?.toString();
        }
        final d = myRoom['dormitory_id']?.toString() ?? '';
        if (d.isNotEmpty) dormId = d;
      }
      if (row == null && room != null && room.isNotEmpty) {
        dynamic billQuery = _db
            .from('bills')
            .select('id, month, rent, electricity, water, penalty, total, due_date, status, qr_image_url')
            .eq('room', room)
            .inFilter('status', ['pending', 'review']);
        if (dormId != null) {
          billQuery = billQuery.eq('dormitory_id', dormId);
        }
        row = await billQuery
            .order('due_date', ascending: false)
            .limit(1)
            .maybeSingle();
      }

      if (row != null) {
        return {
          'id':           row['id'],
          'month':        row['month'] ?? '',
          'rent':         row['rent'] ?? 0,
          'electricity':  row['electricity'] ?? 0,
          'water':        row['water'] ?? 0,
          'penalty':      row['penalty'] ?? 0,
          'total':        row['total'] ?? 0,
          'due_date':     row['due_date'] ?? '',
          'status':       row['status'] ?? 'pending',
          'status_label': _billStatusLabel(row['status']),
          'qrImageUrl':   row['qr_image_url']?.toString() ?? '',
        };
      }

      // ยังไม่มีบิลของตัวเอง (เช่น Roommate ที่แอดมินยังไม่ได้สร้างบิล)
      // → ใช้ "ค่าเช่า" ของตัวเองจาก tenant_rentals แทนค่า mock
      final ownRent = await _getMyRent(roomId: roomId);
      if (ownRent != null && ownRent > 0) {
        return {
          'id':           'rent_$uid',
          'month':        _currentBillMonth(),
          'due_date':     '',
          'rent':         ownRent,
          'electricity':  0,
          'water':        0,
          'penalty':      0,
          'total':        ownRent,
          'status':       'pending',
          'status_label': 'รอชำระ',
        };
      }
      return _fallbackBill();
    } catch (e) {
      print('❌ getCurrentBill error: $e');
      return _fallbackBill();
    }
  }

  /// ค่าเช่าของผู้ใช้ปัจจุบัน (จาก tenant_rentals) — null ถ้าไม่มีข้อมูล
  Future<double?> _getMyRent({String? roomId}) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;

      // 1) หาโดย member_id ของผู้ใช้โดยตรง
      var row = await _db
          .from('tenant_rentals')
          .select('rent')
          .eq('member_id', uid)
          .maybeSingle();

      // 2) ถ้ายังไม่เจอ และมี roomId ให้หาโดย room_id
      if (row == null && roomId != null && roomId.isNotEmpty) {
        row = await _db
            .from('tenant_rentals')
            .select('rent')
            .eq('room_id', roomId)
            .maybeSingle();
      }

      final rent = row?['rent'];
      if (rent == null) return null;
      if (rent is num) return rent.toDouble();
      return double.tryParse(rent.toString());
    } catch (_) {
      return null;
    }
  }

  /// เดือนปัจจุบันแบบไทย เช่น "ตุลาคม 2569"
  String _currentBillMonth() {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year + 543}';
  }

  Map<String, dynamic> _fallbackBill() => {};

  String _billStatusLabel(String? status) {
    switch (status) {
      case 'paid':     return 'ชำระแล้ว';
      case 'overdue':  return 'เกินกำหนด';
      case 'review':   return 'รอตรวจสอบ';
      case 'pending':
      default:         return 'รอชำระ';
    }
  }

  // ── ประวัติบิล ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getBillHistory() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return [];

      final byId = <String, Map<String, dynamic>>{};
      void addRows(List rows) {
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          final id = m['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          byId[id] = {
            'id': id,
            'month': m['month'] ?? '',
            'total': m['total'] ?? 0,
            'status': m['status'] ?? 'paid',
            'status_label': _billStatusLabel(m['status']),
            'paid_date': m['due_date'] ?? '',
            'payment_proof_url': m['payment_proof_url']?.toString() ?? '',
            'qr_image_url': m['qr_image_url']?.toString() ?? '',
            'tenant_name': m['tenant_name']?.toString() ?? '',
            'room': m['room']?.toString() ?? '',
          };
        }
      }

      // 1) บิลที่ผูกกับผู้ใช้โดยตรง
      final ownRows = await _db
          .from('bills')
          .select(
              'id, month, total, status, due_date, payment_proof_url, qr_image_url, tenant_name, room')
          .eq('tenant_id', uid)
          .order('due_date', ascending: false)
          .limit(12);
      addRows(ownRows as List);

      // 2) บิลของห้องเดียวกัน (ให้สมาชิกห้อง/Roommate อ่านบิลของห้องได้)
      final myRoom = await getTenantRoom();
      final room = myRoom['room_number']?.toString() ?? '';
      final dormId = myRoom['dormitory_id']?.toString() ?? '';
      if (room.isNotEmpty) {
        dynamic roomQuery = _db
            .from('bills')
            .select(
                'id, month, total, status, due_date, payment_proof_url, qr_image_url, tenant_name, room')
            .eq('room', room);
        if (dormId.isNotEmpty) {
          roomQuery = roomQuery.eq('dormitory_id', dormId);
        }
        final roomRows = await roomQuery
            .order('due_date', ascending: false)
            .limit(12);
        addRows(roomRows as List);
      }

      if (byId.isEmpty) return [];
      final list = byId.values.toList();
      list.sort((a, b) =>
          (b['paid_date']?.toString() ?? '')
              .compareTo(a['paid_date']?.toString() ?? ''));
      return list.take(12).toList();
    } catch (e) {
      print('❌ getBillHistory error: $e');
      return _fallbackBillHistory();
    }
  }

  List<Map<String, dynamic>> _fallbackBillHistory() => [
        {'month': 'มิถุนายน 2569', 'total': 5090, 'status': 'paid', 'status_label': 'ชำระแล้ว', 'paid_date': '3 ก.ค. 2569'},
        {'month': 'พฤษภาคม 2569', 'total': 4980, 'status': 'paid', 'status_label': 'ชำระแล้ว', 'paid_date': '2 มิ.ย. 2569'},
      ];

  // ── สถิติ dashboard (admin) ──────────────────────────────
  /// ดึง dormitory id ของ admin ที่ login อยู่
  Future<String?> getAdminDormitoryId() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;
      final row = await _db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid)
          .maybeSingle();
      return row?['id']?.toString();
    } catch (e) {
      print('❌ getAdminDormitoryId error: $e');
      return null;
    }
  }

  /// ดึงข้อมูลหอพักของ admin ที่ login อยู่ รวมถึงอัตราค่าไฟฟ้าและน้ำ
  Future<Map<String, dynamic>?> getDormitoryRates(String dormitoryId) async {
    try {
      final row = await _db
          .from('dormitories')
          .select('id, name, address, phone, electricity_rate, water_rate')
          .eq('id', dormitoryId)
          .maybeSingle();
      if (row == null) return null;
      return {
        'id': row['id']?.toString(),
        'name': row['name']?.toString() ?? '',
        'address': row['address']?.toString() ?? '',
        'phone': row['phone']?.toString() ?? '',
        'electricity_rate': (row['electricity_rate'] as num?)?.toDouble() ?? 0,
        'water_rate': (row['water_rate'] as num?)?.toDouble() ?? 0,
      };
    } catch (e) {
      print('❌ getDormitoryRates error: $e');
      return null;
    }
  }

  Future<Map<String, int>> getDashboardStats({String? dormitoryId}) async {
    try {
      dynamic tenantsQuery = _db.from('tenants').select('id');
      dynamic roomsQuery = _db.from('rooms').select('id, status');
      dynamic repairsQuery = _db.from('repairs').select('id');

      if (dormitoryId != null) {
        tenantsQuery = tenantsQuery.eq('dormitory_id', dormitoryId);
        roomsQuery = roomsQuery.eq('dormitory_id', dormitoryId);
        repairsQuery = repairsQuery.eq('dormitory_id', dormitoryId);
      }

      tenantsQuery = tenantsQuery.eq('status', 'กำลังเช่า');
      repairsQuery = repairsQuery.inFilter('status', ['รอดำเนินการ', 'กำลังดำเนินการ']);

      final tenantsRes = await tenantsQuery;
      final totalTenants = (tenantsRes as List).length;

      final roomsRes = await roomsQuery;
      final totalRooms = (roomsRes as List).length;
      final vacantRooms = roomsRes.where((r) => r['status'] == 'vacant').length;

      final repairsRes = await repairsQuery;
      final repairCount = (repairsRes as List).length;

      return {
        'total_tenants':   totalTenants,
        'total_rooms':     totalRooms,
        'vacant_rooms':    vacantRooms,
        'repair_requests': repairCount,
      };
    } catch (e) {
      print('❌ getDashboardStats error: $e');
      return {'total_tenants': 0, 'total_rooms': 0, 'vacant_rooms': 0, 'repair_requests': 0};
    }
  }

  // ── รายการแจ้งซ่อม (admin dashboard) ────────────────────
  Future<List<Map<String, String>>> getRepairRequests({String? dormitoryId}) async {
    try {
      dynamic query = _db
          .from('repairs')
          .select('room_number, reporter_name, created_at, status');

      if (dormitoryId != null) {
        query = query.eq('dormitory_id', dormitoryId);
      }

      query = query
          .inFilter('status', ['รอดำเนินการ', 'กำลังดำเนินการ'])
          .order('created_at', ascending: false)
          .limit(5);

      final rows = await query;

      if ((rows as List).isEmpty) return _fallbackRepairs();
      return rows.map<Map<String, String>>((r) => {
        'room':   r['room_number'] ?? '',
        'tenant': r['reporter_name'] ?? '',
        'time':   _formatDate(r['created_at']),
        'status': r['status'] ?? '',
      }).toList();
    } catch (_) {
      return _fallbackRepairs();
    }
  }

  List<Map<String, String>> _fallbackRepairs() => [
        {'room': 'A101', 'tenant': 'พัชราวรรณ ศรีบุญ', 'time': '8 ก.ย. 09:45', 'status': 'กำลังดำเนินการ'},
        {'room': 'A103', 'tenant': 'ธนกร มีสุข',       'time': '8 ก.ย. 10:12', 'status': 'กำลังดำเนินการ'},
        {'room': 'B201', 'tenant': 'นภา แก้วมณี',      'time': '7 ก.ย. 14:30', 'status': 'รอดำเนินการ'},
      ];

  // ── รายชื่อผู้เช่าทั้งหมด (admin) ───────────────────────
  // ดึงจาก dormitory_members (approved) + lookup ชื่อจาก tenants / roommate_invites
  // รวมทั้งผู้เช่าหลัก (member_type = tenant) และ Roommate (member_type = roommate)
  // หมายเหตุ: ไม่ embed เพราะ dormitory_members ไม่มี FK ตรงไปที่ tenants/roommate_invites
  //          (user_id อ้าง auth.users) → ต้อง query แยกแล้ว map เอง
  Future<List<Map<String, String>>> getTenantList({String? dormitoryId}) async {
    try {
      String? effectiveDormId = dormitoryId;
      if (effectiveDormId == null) {
        effectiveDormId = await getAdminDormitoryId();
      }

      dynamic membersQuery = _db
          .from('dormitory_members')
          .select('id, user_id, member_type, status, room_id');
      membersQuery = membersQuery.eq('status', 'approved');
      membersQuery =
          membersQuery.inFilter('member_type', ['tenant', 'roommate']);
      if (effectiveDormId != null) {
        membersQuery = membersQuery.eq('dormitory_id', effectiveDormId);
      }
      final members = await membersQuery;
      final memberRows = (members as List).cast<Map<String, dynamic>>();
      if (memberRows.isEmpty) {
        // ถ้าเป็นแอดมินและมี dormitoryId เฉพาะ ให้แสดงว่าง ไม่ใช้ fallback ทั่วไป
        if (effectiveDormId != null) return [];
        return _fallbackTenantList();
      }

      final userIds = memberRows
          .map((m) => m['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final roomIds = memberRows
          .map((m) => m['room_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      // ชื่อผู้เช่าหลักอยู่ใน tenants, Roommate อยู่ใน roommate_invites
      final tenantRows = userIds.isEmpty
          ? []
          : await _db
              .from('tenants')
              .select('id, full_name, phone')
              .inFilter('id', userIds);
      final roommateRows = userIds.isEmpty
          ? []
          : await _db
              .from('roommate_invites')
              .select('id, full_name, phone')
              .inFilter('id', userIds);
      final roomRows = roomIds.isEmpty
          ? []
          : await _db
              .from('rooms')
              .select('id, room_number')
              .inFilter('id', roomIds);

      final personMap = <String, Map<String, String>>{};
      for (final t in tenantRows) {
        personMap[t['id'].toString()] = {
          'name': t['full_name']?.toString() ?? '',
          'phone': t['phone']?.toString() ?? '',
        };
      }
      for (final r in roommateRows) {
        personMap.putIfAbsent(
          r['id'].toString(),
          () => {
            'name': r['full_name']?.toString() ?? '',
            'phone': r['phone']?.toString() ?? '',
          },
        );
      }
      final roomMap = <String, String>{};
      for (final r in roomRows) {
        roomMap[r['id'].toString()] = r['room_number']?.toString() ?? '-';
      }

      final result = <Map<String, String>>[];
      for (final m in memberRows) {
        final userId = m['user_id']?.toString() ?? '';
        final roomId = m['room_id']?.toString() ?? '';
        final person = personMap[userId];
        final name = person?['name'] ?? '';
        if (name.isEmpty) continue;

        final isRoommate = m['member_type']?.toString() == 'roommate';

        result.add({
          'userId': userId,
          'member_id': m['id']?.toString() ?? '',
          'name': name,
          'room': roomMap[roomId] ?? '-',
          'role': isRoommate ? 'Roommate' : 'ผู้เช่าหลัก',
          'phone': person?['phone'] ?? '',
          'status': 'กำลังเช่า',
        });
      }

      result.sort((a, b) {
        // ผู้เช่าหลักขึ้นก่อน แล้วค่อย Roommate (เรียงตามชื่อในกลุ่มเดียวกัน)
        final aMain = a['role'] == 'Roommate' ? 1 : 0;
        final bMain = b['role'] == 'Roommate' ? 1 : 0;
        if (aMain != bMain) return aMain.compareTo(bMain);
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      });

      if (result.isEmpty) {
        if (effectiveDormId != null) return [];
        return _fallbackTenantList();
      }
      return result;
    } catch (_) {
      if (dormitoryId != null) return [];
      return _fallbackTenantList();
    }
  }

  List<Map<String, String>> _fallbackTenantList() => [
        {'name': 'พัชราวรรณ ศรีบุญ', 'room': 'A101', 'role': 'ผู้เช่าหลัก', 'phone': '0999999999', 'status': 'กำลังเช่า'},
        {'name': 'สมชาย ใจดี',        'room': 'A101', 'role': 'Roommate',    'phone': '0888888888', 'status': 'กำลังเช่า'},
        {'name': 'วิภา รักเรียน',     'room': 'A102', 'role': 'ผู้เช่าหลัก', 'phone': '0777777777', 'status': 'กำลังเช่า'},
      ];

  // ── ประกาศ ───────────────────────────────────────────────
  /// [status] = 'published' | 'draft' | null (ทั้งหมด)
  Future<List<Map<String, String>>> getAnnouncements({
    String? dormitoryId,
    String? status,
  }) async {
    try {
       dynamic query = _db
           .from('announcements')
           .select('id, title, content, image_url, created_at, status, end_date');

       if (dormitoryId != null) {
         query = query.eq('dormitory_id', dormitoryId);
       }
       if (status != null) {
         query = query.eq('status', status);
       }

       query = query
           .order('created_at', ascending: false)
           .limit(50);

       final rows = await query;

       final now = DateTime.now();
       final today = DateTime(now.year, now.month, now.day);

       final list = <Map<String, String>>[];
       for (final r in rows as List) {
         final endDateStr = r['end_date']?.toString();
         if (endDateStr != null && endDateStr.isNotEmpty) {
           try {
             final ed = DateTime.parse(endDateStr);
             final end = DateTime(ed.year, ed.month, ed.day);
             if (!end.isAfter(today)) continue;
           } catch (_) {}
         }
         list.add({
           'id':      r['id']?.toString() ?? '',
           'title':   r['title']?.toString() ?? '',
           'content': r['content']?.toString() ?? '',
           'image':   r['image_url']?.toString() ?? '',
           'status':  r['status']?.toString() ?? 'published',
           'date':    _formatDate(r['created_at']?.toString()),
           'end_date': (r['end_date']?.toString() ?? '').split('T').first,
         });
       }
       return list;
    } catch (e) {
      print('❌ getAnnouncements error: $e');
      return [];
    }
  }

List<Map<String, String>> _fallbackAnnouncements() => [
        {'id': '1', 'title': ' Fuse announcement_1.png', 'date': '5 ก.ย. 2569'},
        {'id': '2', 'title': ' Fuse announcement_2.png', 'date': '1 ก.ย. 2569'},
      ];

  /// Realtime stream ของ announcements (published เท่านั้น)
  Stream<List<Map<String, String>>> announcementsStream({
    String? dormitoryId,
    String? status = 'published',
  }) {
    final controller = StreamController<List<Map<String, String>>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        var query = _db.from('announcements').select(
          'id, title, content, image_url, created_at, status, dormitory_id, end_date',
        );

        if (dormitoryId != null && dormitoryId.isNotEmpty) {
          query = query.eq('dormitory_id', dormitoryId);
        }
        if (status != null) {
          query = query.eq('status', status);
        }

        final rows = await query
            .order('created_at', ascending: false)
            .limit(50);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final list = <Map<String, String>>[];
        for (final r in rows as List) {
          final endDateStr = r['end_date']?.toString();
          if (endDateStr != null && endDateStr.isNotEmpty) {
            try {
              final ed = DateTime.parse(endDateStr);
              final end = DateTime(ed.year, ed.month, ed.day);
              if (!end.isAfter(today)) {
                continue;
              }
            } catch (_) {}
          }

          list.add({
            'id': r['id']?.toString() ?? '',
            'title': r['title']?.toString() ?? '',
            'content': r['content']?.toString() ?? '',
            'image': r['image_url']?.toString() ?? '',
            'status': r['status']?.toString() ?? 'published',
            'date': _formatDate(r['created_at']?.toString()),
            'end_date': (r['end_date']?.toString() ?? '').split('T').first,
          });
        }

        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (_) {}
    }

    fetch();

    channel = _db
        .channel('realtime:announcements_stream_${dormitoryId ?? 'all'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (_) => fetch(),
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) {
        await _db.removeChannel(channel!);
      }
    };

    return controller.stream;
  }

  // ── helper: แปลง ISO date → ไทย ─────────────────────────
  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const thMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
                         'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
      final buddhistYear = dt.year + 543;
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${thMonths[dt.month]} ${buddhistYear.toString().substring(2)} $h:$m';
    } catch (_) {
      return iso;
    }
  }

  // ── สมาชิกในห้อง ────────────────────────────────────────
  Future<List<Map<String, String>>> getRoomMembers() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return _fallbackRoomMembers();

      final tenant = await _db
          .from('tenants')
          .select('full_name, phone')
          .eq('id', uid)
          .maybeSingle();

      if (tenant == null) return _fallbackRoomMembers();

      final mates = await _db
          .from('roommates')
          .select('full_name, phone')
          .eq('tenant_id', uid);

      final result = <Map<String, String>>[
        {'name': tenant['full_name'] ?? '', 'role': 'ผู้เช่าหลัก', 'phone': tenant['phone']?.toString() ?? ''},
        for (final r in (mates as List))
          {'name': r['full_name'] ?? '', 'role': 'Roommate', 'phone': r['phone']?.toString() ?? ''},
      ];
      return result;
    } catch (_) {
      return _fallbackRoomMembers();
    }
  }

  List<Map<String, String>> _fallbackRoomMembers() => [
        {'name': 'พัชราวรรณ ศรีบุญ', 'role': 'ผู้เช่าหลัก', 'phone': '0999999999'},
        {'name': 'สมชาย ใจดี',        'role': 'Roommate',    'phone': '0888888888'},
      ];

  // ── ยอดชำระ breakdown ────────────────────────────────────
  Future<Map<String, dynamic>> getPaymentSummary() async {
    final bill = await getCurrentBill();
    return {
      'total': bill['total'] ?? 0,
      'month': bill['month'] ?? '',
      'breakdown': [
        {'label': 'ค่าเช่า',  'amount': bill['rent']        ?? 0},
        {'label': 'ค่าไฟ',   'amount': bill['electricity']  ?? 0},
        {'label': 'ค่าน้ำ',  'amount': bill['water']        ?? 0},
        {'label': 'อื่นๆ',    'amount': bill['penalty']      ?? 0},
      ],
    };
  }

  // ── สร้างบิลใหม่ (admin) ─────────────────────────────────
  /// บันทึกบิลลงตาราง bills + อัปโหลดรูป QR (ถ้ามี)
  /// คืน true เมื่อสำเร็จ
  Future<bool> createBill({
    required String tenantId,
    required String tenantName,
    required String room,
    required String? dormitoryId,
    required String month,
    required int rent,
    required int electricity,
    required int water,
    required int total,
    required String dueDate, // รูปแบบ ISO: yyyy-MM-dd
    Uint8List? qrBytes,
    String? qrFileName,
    String? electricMeterPrev,
    String? electricMeterCurr,
    String? waterMeterPrev,
    String? waterMeterCurr,
  }) async {
    try {
      final uid = _db.auth.currentUser?.id;

      // 1) อัปโหลดรูป QR ถ้ามี
      String? qrUrl;
      if (qrBytes != null) {
        final ext = (qrFileName != null && qrFileName.contains('.'))
            ? qrFileName.split('.').last
            : 'png';
        final path =
            'qr/${DateTime.now().millisecondsSinceEpoch}_$tenantId.$ext';
        await _db.storage.from('dormitory-images').uploadBinary(
              path,
              qrBytes,
              fileOptions: const FileOptions(upsert: true),
            );
        qrUrl = _db.storage.from('dormitory-images').getPublicUrl(path);
      }

      // 2) insert แถวบิล
      print('🔍 METER DEBUG: ePrev=$electricMeterPrev eCurr=$electricMeterCurr wPrev=$waterMeterPrev wCurr=$waterMeterCurr qrUrl=$qrUrl tenantId=$tenantId');
      await _db.from('bills').insert({
        'tenant_id': tenantId,
        'tenant_name': tenantName,
        'room': room,
        'dormitory_id': dormitoryId,
        'month': month,
        'rent': rent,
        'electricity': electricity,
        'water': water,
        'penalty': 0,
        'total': total,
        'due_date': dueDate,
        'status': 'pending',
        'qr_image_url': qrUrl,
        'created_by': uid,
        'electric_meter_prev': electricMeterPrev,
        'electric_meter_curr': electricMeterCurr,
        'water_meter_prev': waterMeterPrev,
        'water_meter_curr': waterMeterCurr,
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ createBill error: $e');
      return false;
    }
  }

  // ── อัปโหลดหลักฐานการโอน ──────────────────────────────────
  Future<String?> uploadPaymentProof({
    required String billId,
    required Uint8List bytes,
    String? fileName,
  }) async {
    try {
      final ext = (fileName != null && fileName.contains('.'))
          ? fileName.split('.').last.toLowerCase()
          : 'jpg';
      final path =
          'payment-proofs/${billId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      print('🔍 UPLOAD DEBUG: path=$path bucket=dormitory-images');
      await _db.storage.from('dormitory-images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = _db.storage.from('dormitory-images').getPublicUrl(path);
      print('🔍 UPLOAD DEBUG: success url=$url');
      return url;
    } catch (e) {
      print('❌ uploadPaymentProof error: $e');
      return null;
    }
  }

  // ── อัปเดตสถานะบิล (pending → review → paid) ────────────────
  Future<bool> updateBillStatus(
    String billId,
    String status, {
    String? paymentProofUrl,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (paymentProofUrl != null && paymentProofUrl.isNotEmpty) {
        data['payment_proof_url'] = paymentProofUrl;
      }
      print('🔍 UPDATE DEBUG: billId=$billId data=$data');
      await _db.from('bills').update(data).eq('id', billId);
      print('🔍 UPDATE DEBUG: done');
      return true;
    } catch (e) {
      print('❌ updateBillStatus error: $e');
      return false;
    }
  }

  // ── รายการบิลทั้งหมดในหอพัก (admin) ──────────────────────
  Future<List<Map<String, dynamic>>> getBills({String? dormitoryId}) async {
    try {
      dynamic q = _db.from('bills').select(
          'id, tenant_id, tenant_name, room, month, rent, electricity, water, penalty, total, due_date, status, qr_image_url, payment_proof_url, created_at, dormitory_id');
      if (dormitoryId != null && dormitoryId.isNotEmpty) {
        q = q.eq('dormitory_id', dormitoryId);
      }
      q = q.order('created_at', ascending: false);
      final rows = await q;

      return (rows as List).map<Map<String, dynamic>>((r) {
        return {
          'id': r['id']?.toString() ?? '',
          'tenantId': r['tenant_id']?.toString() ?? '',
          'tenantName': r['tenant_name']?.toString() ?? '-',
          'room': r['room']?.toString() ?? '-',
          'month': r['month']?.toString() ?? '',
          'rent': r['rent'] ?? 0,
          'electricity': r['electricity'] ?? 0,
          'water': r['water'] ?? 0,
          'total': r['total'] ?? 0,
          'dueDate': _formatThaiDate(r['due_date']?.toString()),
          'status': r['status']?.toString() ?? 'pending',
          'statusLabel': _billStatusLabel(r['status']?.toString()),
          'qrImageUrl': r['qr_image_url']?.toString() ?? '',
          'paymentProofUrl': r['payment_proof_url']?.toString() ?? '',
          'dormitoryId': r['dormitory_id']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── สรุปจำนวนบิลตามสถานะ (admin) ─────────────────────────
  Future<Map<String, int>> getBillStats({String? dormitoryId}) async {
    try {
      dynamic q = _db.from('bills').select('status');
      if (dormitoryId != null) {
        q = q.eq('dormitory_id', dormitoryId);
      }
      final rows = await q;
      int pending = 0, review = 0, paid = 0;
      for (final r in (rows as List)) {
        switch (r['status']?.toString()) {
          case 'pending':
            pending++;
            break;
          case 'review':
            review++;
            break;
          case 'paid':
            paid++;
            break;
        }
      }
      return {'pending': pending, 'review': review, 'paid': paid};
    } catch (_) {
      return {'pending': 0, 'review': 0, 'paid': 0};
    }
  }

  // แปลงวันที่ ISO (yyyy-MM-dd, ปีอาจเป็น พ.ศ.) → "5 สิงหาคม 2569"
  String _formatThaiDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final parts = iso.split('-');
      if (parts.length != 3) return iso;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      const months = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
      ];
      // ถ้าปีเป็น ค.ศ. แปลงเป็น พ.ศ.
      final buddhistYear = year < 2500 ? year + 543 : year;
      return '$day ${months[(month - 1) % 12]} $buddhistYear';
    } catch (_) {
      return iso;
    }
  }
}

// global instance
final mockService = MockService();
