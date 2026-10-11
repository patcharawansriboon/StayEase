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
            .select('full_name, phone')
            .eq('id', uid)
            .maybeSingle();
        if (row != null) {
          return {
            'full_name': (row['full_name'] as String?) ?? '',
            'phone':     (row['phone']?.toString()) ?? '',
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
          .select('room_id, rooms(room_number, floor, building, status)')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .maybeSingle();

      final approvedRoom = approvedRow?['rooms'] as Map<String, dynamic>?;
      if (approvedRoom != null && (approvedRoom['room_number'] ?? '').toString().isNotEmpty) {
        return Map<String, dynamic>.from(approvedRoom);
      }

      // 2. fallback: ดึงจาก dormitory_members ที่ pending (ห้องที่เลือกตอน sign up)
      final pendingRow = await _db
          .from('dormitory_members')
          .select('room_id, rooms(room_number, floor, building, status)')
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
  Future<Map<String, dynamic>> getCurrentBill() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return _fallbackBill();

      final row = await _db
          .from('bills')
          .select('id, month, rent, electricity, water, penalty, total, due_date, status')
          .eq('tenant_id', uid)
          .eq('status', 'pending')
          .order('due_date', ascending: false)
          .limit(1)
          .maybeSingle();

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
        };
      }
      return _fallbackBill();
    } catch (_) {
      return _fallbackBill();
    }
  }

  Map<String, dynamic> _fallbackBill() => {
        'month':        'กรกฎาคม 2569',
        'due_date':     '5 สิงหาคม 2569',
        'rent':         4500,
        'electricity':  320,
        'water':        180,
        'penalty':      0,
        'total':        5000,
        'status':       'pending',
        'status_label': 'รอชำระ',
      };

  String _billStatusLabel(String? status) {
    switch (status) {
      case 'paid':     return 'ชำระแล้ว';
      case 'overdue':  return 'เกินกำหนด';
      case 'pending':
      default:         return 'รอชำระ';
    }
  }

  // ── ประวัติบิล ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getBillHistory() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return _fallbackBillHistory();

      final rows = await _db
          .from('bills')
          .select('month, total, status, due_date')
          .eq('tenant_id', uid)
          .neq('status', 'pending')
          .order('due_date', ascending: false)
          .limit(12);

      if (rows.isEmpty) return _fallbackBillHistory();
      return (rows as List).map((r) => {
        'month':        r['month'] ?? '',
        'total':        r['total'] ?? 0,
        'status':       r['status'] ?? 'paid',
        'status_label': _billStatusLabel(r['status']),
        'paid_date':    r['due_date'] ?? '',
      }).toList();
    } catch (_) {
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
  Future<List<Map<String, String>>> getTenantList({String? dormitoryId}) async {
    try {
      dynamic tenantsQuery = _db
          .from('tenants')
          .select('full_name, phone, status, id');

      dynamic roommatesQuery = _db
          .from('roommates')
          .select('full_name, phone, status, id, tenant_id');

      dynamic roomsQuery = _db
          .from('rooms')
          .select('tenant_id, room_number')
          .not('tenant_id', 'is', null);

      if (dormitoryId != null) {
        tenantsQuery = tenantsQuery.eq('dormitory_id', dormitoryId);
        roommatesQuery = roommatesQuery.eq('dormitory_id', dormitoryId);
        roomsQuery = roomsQuery.eq('dormitory_id', dormitoryId);
      }

      tenantsQuery = tenantsQuery.order('full_name');

      final tenants = await tenantsQuery;
      final roommates = await roommatesQuery;
      final rooms = await roomsQuery;

      final roomMap = <String, String>{};
      for (final r in (rooms as List)) {
        if (r['tenant_id'] != null) {
          roomMap[r['tenant_id']] = r['room_number'] ?? '';
        }
      }

      final result = <Map<String, String>>[];

      for (final t in (tenants as List)) {
        result.add({
          'name':   t['full_name'] ?? '',
          'room':   roomMap[t['id']] ?? '-',
          'role':   'ผู้เช่าหลัก',
          'phone':  t['phone']?.toString() ?? '',
          'status': t['status'] ?? '',
        });
      }
      for (final r in (roommates as List)) {
        result.add({
          'name':   r['full_name'] ?? '',
          'room':   roomMap[r['tenant_id']] ?? '-',
          'role':   'Roommate',
          'phone':  r['phone']?.toString() ?? '',
          'status': r['status'] ?? '',
        });
      }

      if (result.isEmpty) return _fallbackTenantList();
      return result;
    } catch (_) {
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
          .select('id, title, content, image_url, created_at, status');

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

      return (rows as List).map<Map<String, String>>((r) => {
        'id':      r['id']?.toString() ?? '',
        'title':   r['title']?.toString() ?? '',
        'content': r['content']?.toString() ?? '',
        'image':   r['image_url']?.toString() ?? '',
        'status':  r['status']?.toString() ?? 'published',
        'date':    _formatDate(r['created_at']?.toString()),
      }).toList();
    } catch (e) {
      print('❌ getAnnouncements error: $e');
      return [];
    }
  }

  List<Map<String, String>> _fallbackAnnouncements() => [
        {'id': '1', 'title': 'ประกาศปิดน้ำชั่วคราว',                  'image': 'assets/images/announcement_1.png', 'date': '5 ก.ย. 2569'},
        {'id': '2', 'title': 'กำหนดชำระค่าเช่าเดือนกรกฎาคม',         'image': 'assets/images/announcement_2.png', 'date': '1 ก.ย. 2569'},
      ];

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
}

// global instance
final mockService = MockService();
