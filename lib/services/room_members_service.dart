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
}
