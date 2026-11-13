import 'package:supabase_flutter/supabase_flutter.dart';

/// จัดการข้อมูล "สมาชิกในห้อง" — ผู้เช่าหลัก + Roommate ที่อยู่ห้องเดียวกัน
///
/// โครงสร้างข้อมูล:
/// - `dormitory_members.room_id` → ห้องที่สมาชิกอาศัย
/// - ผู้เช่าหลัก (member_type = 'tenant') แต่ละคนได้ห้องของตัวเอง
/// - Roommate (member_type = 'roommate') ได้ห้องเดียวกับผู้ออกรหัสเชิญ
class RoomMembersService {
  final _supabase = Supabase.instance.client;

  /// หา room_id ของสมาชิก ถ้ายังไม่มีจะจัดห้องว่างให้อัตโนมัติ
  /// คืน null ถ้าหอนั้นยังไม่มีห้องว่าง
  Future<String?> ensureRoomForMember(String memberId) async {
    final existing = await _supabase
        .from('dormitory_members')
        .select('room_id, dormitory_id')
        .eq('id', memberId)
        .maybeSingle();

    final currentRoom = existing?['room_id']?.toString();
    if (currentRoom != null && currentRoom.isNotEmpty) return currentRoom;

    final dormitoryId = existing?['dormitory_id']?.toString();
    if (dormitoryId == null) return null;

    final room = await _findFreeRoom(dormitoryId);
    if (room == null) return null;

    await _supabase
        .from('dormitory_members')
        .update({'room_id': room})
        .eq('id', memberId);

    return room;
  }

  /// หาห้องของ Roommate จากรหัสเชิญ → ห้องของผู้ออกรหัส
  /// จำเป็นสำหรับรหัสที่สร้างก่อนมีคอลัมน์ room_id (room_id = null)
  /// คืน null ถ้าหาไม่ได้
  Future<String?> resolveRoomForRoommate(String userId) async {
    final invite = await _supabase
        .from('roommate_invites')
        .select('invite_code')
        .eq('id', userId)
        .maybeSingle();

    final code = invite?['invite_code']?.toString();
    if (code == null || code.isEmpty) return null;

    final inv = await _supabase
        .from('invitation_codes')
        .select('room_id, created_by')
        .eq('code', code)
        .maybeSingle();

    // รหัสมี room_id แล้ว → ใช้เลย
    final roomId = inv?['room_id']?.toString();
    if (roomId != null && roomId.isNotEmpty) return roomId;

    // ไม่มี room_id → ไปหาห้องของผู้ออกรหัสแทน
    final inviterId = inv?['created_by']?.toString();
    if (inviterId == null) return null;

    final inviterMember = await _supabase
        .from('dormitory_members')
        .select('room_id')
        .eq('user_id', inviterId)
        .eq('status', 'approved')
        .limit(1)
        .maybeSingle();

    return inviterMember?['room_id']?.toString();
  }

  /// ห้องนี้ยังมีที่ว่างไหม (นับเฉพาะคนที่อนุมัติแล้ว)
  /// [excludeMemberId] ใช้ตอนอนุมัติ เพื่อไม่นับตัวเอง
  Future<bool> canJoinRoom(String roomId, {String? excludeMemberId}) async {
    final room = await _supabase
        .from('rooms')
        .select('max_tenants')
        .eq('id', roomId)
        .maybeSingle();
    if (room == null) return false;
    final max = (room['max_tenants'] as num?)?.toInt() ?? 1;

    // นับสมาชิกที่ approved แล้วในห้องนี้
    final rows = await _supabase
        .from('dormitory_members')
        .select('id')
        .eq('room_id', roomId)
        .eq('status', 'approved');

    var count = (rows as List).length;

    print('🔍 canJoinRoom: roomId=$roomId max=$max approvedCount=$count excludeMemberId=$excludeMemberId');

    // excludeMemberId คือ Roommate ที่กำลังจะอนุมัติ
    // ถ้ามันยังอยู่ใน approved count อยู่แล้ว (กรณี re-approve) ให้ไม่นับ
    if (excludeMemberId != null) {
      final alreadyCounted = (rows as List)
          .any((r) => r['id']?.toString() == excludeMemberId);
      if (alreadyCounted) count -= 1;
    }

    print('🔍 canJoinRoom: finalCount=$count result=${count < max}');
    return count < max;
  }

  /// ห้องว่างที่ยังไม่มีสมาชิกครบ max_tenants คน
  Future<String?> _findFreeRoom(String dormitoryId) async {    final rooms = await _supabase
        .from('rooms')
        .select('id, max_tenants')
        .eq('dormitory_id', dormitoryId)
        .order('floor')
        .order('room_number');

    final roomIds = (rooms as List).map((r) => r['id'].toString()).toList();
    if (roomIds.isEmpty) return null;

    // นับสมาชิกที่อนุมัติแล้วในแต่ละห้อง
    final members = await _supabase
        .from('dormitory_members')
        .select('room_id')
        .inFilter('room_id', roomIds)
        .eq('status', 'approved');

    final counts = <String, int>{};
    for (final m in (members as List)) {
      final rid = m['room_id']?.toString();
      if (rid == null) continue;
      counts[rid] = (counts[rid] ?? 0) + 1;
    }

    for (final r in (rooms as List)) {
      final rid = r['id'].toString();
      final max = (r['max_tenants'] as num?)?.toInt() ?? 1;
      if ((counts[rid] ?? 0) < max) return rid;
    }
    return null;
  }

  /// ดึงสมาชิกทั้งหมดในห้องของผู้ใช้ปัจจุบัน
  /// คืนรายการ: {name, phone, role ('ผู้เช่าหลัก'/'Roommate'), isMe}
  Future<Map<String, dynamic>> loadMyRoom() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      return {'members': <Map<String, String>>[], 'room': null};
    }

    // 1) หา room_id ของผู้ใช้ปัจจุบัน
    final myMembership = await _supabase
        .from('dormitory_members')
        .select('id, room_id, status, member_type')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    var roomId = myMembership?['room_id']?.toString();

    if ((roomId == null || roomId.isEmpty) && myMembership != null) {
      roomId = await ensureRoomForMember(myMembership['id'].toString());
    }

    if (roomId == null || roomId.isEmpty) {
      return {'members': <Map<String, String>>[], 'room': null};
    }

    // 2) ข้อมูลห้อง
    final room = await _supabase
        .from('rooms')
        .select('id, room_number, building, floor, max_tenants')
        .eq('id', roomId)
        .maybeSingle();

    // 3) ดึงสมาชิกผ่าน SECURITY DEFINER function (bypass RLS)
    final rows = await _supabase.rpc('get_room_members', params: {
      'p_user_id': uid,
    });

    final members = <Map<String, String>>[];
    for (final m in (rows as List)) {
      final u = m['user_id']?.toString() ?? '';
      final isTenant = m['member_type']?.toString() != 'roommate';
      members.add({
        'name':  m['full_name']?.toString() ?? 'Unknown',
        'phone': m['phone']?.toString() ?? '-',
        'role':  isTenant ? 'ผู้เช่าหลัก' : 'Roommate',
        'isMe':  u == uid ? '1' : '',
      });
    }

    members.sort((a, b) {
      final aMain = a['role'] == 'ผู้เช่าหลัก' ? 0 : 1;
      final bMain = b['role'] == 'ผู้เช่าหลัก' ? 0 : 1;
      if (aMain != bMain) return aMain.compareTo(bMain);
      return (a['name'] ?? '').compareTo(b['name'] ?? '');
    });

    return {
      'members': members,
      'room': room,
    };
  }

  /// ดึง "ค่าเช่ารายคน" ในห้องของผู้ใช้ปัจจุบัน (ผู้เช่าหลัก + Roommate)
  ///
  /// คืนรายการ: {name, phone, role, rent, deposit, isMe, isMainTenant}
  /// - rent เป็นตัวเลข (double) หรือ null ถ้ายังไม่มีข้อมูล
  ///
  /// หมายเหตุ: ตาราง tenant_rentals ถูกล็อกด้วย RLS ให้อ่านได้แค่แถวของตัวเอง
  /// จึงต้องใช้ RPC `get_room_rent_breakdown` (security definer) ที่อ่านข้าม RLS ได้
  /// ถ้ายังไม่ได้รัน SQL ใน Supabase (ดู fix-room-rent-breakdown.sql)
  /// จะ fallback ไปใช้ `get_room_members` + ค่าเช่าของตัวเองเท่านั้น
  Future<List<Map<String, dynamic>>> loadRoomRentBreakdown() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return [];

    // ── 1) RPC: ได้ค่าเช่าจริงของทุกคนในห้อง ──
    try {
      final rows = await _supabase.rpc('get_room_rent_breakdown', params: {
        'p_user_id': uid,
      });
      final list = _mapBreakdownRows(rows as List, uid);
      if (list.isNotEmpty) return list;
    } catch (e) {
      print('⚠️ get_room_rent_breakdown ไม่พร้อมใช้งาน: $e');
    }

    // ── 2) Fallback: รายชื่อสมาชิกจาก get_room_members + ค่าเช่าของตัวเอง ──
    final room = await loadMyRoom();
    final members = (room['members'] as List?) ?? [];
    if (members.isEmpty) return [];

    final myRent = await _loadMyRent();

    final list = <Map<String, dynamic>>[];
    for (final m in members) {
      final isMe = m['isMe']?.toString() == '1';
      list.add({
        'name': m['name']?.toString() ?? '-',
        'phone': m['phone']?.toString() ?? '',
        'role': m['role']?.toString() ?? 'Roommate',
        'rent': isMe ? myRent : null,
        'deposit': null,
        'isMe': isMe,
        'isMainTenant': m['role']?.toString() == 'ผู้เช่าหลัก',
      });
    }
    return list;
  }

  /// แปลงแถวจาก RPC เป็นรูปแบบที่การ์ดค่าเช่าใช้
  List<Map<String, dynamic>> _mapBreakdownRows(List rows, String uid) {
    final list = <Map<String, dynamic>>[];
    for (final r in rows) {
      final m = r as Map<String, dynamic>;
      final memberType = m['member_type']?.toString() ?? 'tenant';
      final isRoommate = memberType == 'roommate';
      final rent = _toDouble(m['rent']);
      list.add({
        'name': m['full_name']?.toString() ?? '-',
        'phone': m['phone']?.toString() ?? '',
        'role': isRoommate ? 'Roommate' : 'ผู้เช่าหลัก',
        'rent': rent,
        'deposit': _toDouble(m['deposit']),
        'isMe': m['user_id']?.toString() == uid,
        'isMainTenant': !isRoommate,
      });
    }
    // ผู้เช่าหลักขึ้นก่อน แล้วค่อย Roommate
    list.sort((a, b) {
      final aMain = a['isMainTenant'] == true ? 0 : 1;
      final bMain = b['isMainTenant'] == true ? 0 : 1;
      if (aMain != bMain) return aMain.compareTo(bMain);
      return (a['name'] ?? '').compareTo(b['name'] ?? '');
    });
    return list;
  }

  /// ค่าเช่าของตัวเอง (อ่านได้เพราะเป็นแถวของตัวเองใน tenant_rentals / bills)
  Future<double?> _loadMyRent() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return null;

      final rental = await _supabase
          .from('tenant_rentals')
          .select('rent')
          .eq('member_id', uid)
          .maybeSingle();
      final rent = _toDouble(rental?['rent']);
      if (rent != null && rent > 0) return rent;

      final bill = await _supabase
          .from('bills')
          .select('rent')
          .eq('tenant_id', uid)
          .order('due_date', ascending: false)
          .limit(1)
          .maybeSingle();
      return _toDouble(bill?['rent']);
    } catch (e) {
      print('⚠️ _loadMyRent error: $e');
      return null;
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
