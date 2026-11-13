import 'package:supabase_flutter/supabase_flutter.dart';

/// บริการระบบแชทงานแจ้งซ่อม
/// โมเดล: 1 ห้องแชท = 1 ผู้เช่า (ผูกผ่าน room_id ของผู้เช่า)
/// งานซ่อมใหม่จะยิง repair_summary เข้าห้องเดิม → ประวัติแชทไม่หาย
/// สมาชิก: ผู้เช่าหลัก + Roommate ในห้องเดียวกัน + แอดมินของหอ (คุมด้วย RLS)
class ChatService {
  final _db = Supabase.instance.client;

  String? get currentUserId => _db.auth.currentUser?.id;

  /// หาห้องแชทที่มีอยู่แล้วของ "ห้องพัก" (room_id) นี้
  /// คืน chatRoomId หรือ null ถ้ายังไม่มี
  Future<String?> _findExistingRoomByRoomId(String roomId) async {
    if (roomId.isEmpty) return null;
    try {
      final existing = await _db
          .from('chat_rooms')
          .select('id')
          .eq('room_id', roomId)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();
      return existing?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// สร้างงานแจ้งซ่อมใหม่ + ห้องแชท + ข้อความสรุปของบอท
  /// คืน {repairId, chatRoomId} หรือ null เมื่อทำไม่สำเร็จ
  Future<Map<String, String>?> createRepairWithChat({
    required String category,
    required String description,
    String? imageUrl,
    String senderRole = 'tenant',
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      // 1) หา room_id / dormitory_id / room_number ของผู้แจ้ง (จาก dormitory_members)
      final member = await _db
          .from('dormitory_members')
          .select('room_id, dormitory_id')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final roomId = member?['room_id']?.toString();
      final dormitoryId = member?['dormitory_id']?.toString();

      // ถ้าไม่มีห้อง ยังสร้างคำขอได้ (room_id = null)
      String roomNumber = '';
      if (roomId != null && roomId.isNotEmpty) {
        final room = await _db
            .from('rooms')
            .select('room_number')
            .eq('id', roomId)
            .maybeSingle();
        roomNumber = room?['room_number']?.toString() ?? '';
      }

      // ชื่อผู้แจ้ง (จาก tenants ก่อน ไม่งั้น roommate_invites)
      final reporterName = await _resolveName(uid);

      // 2) สร้างงานซ่อม
      final repair = await _db
          .from('repairs')
          .insert({
            'user_id': uid,
            'room_id': roomId,
            'room_number': roomNumber,
            'reporter_name': reporterName,
            'category': category,
            'description': description,
            'image_url': imageUrl,
            'status': 'new',
            // ส่งเป็น UTC (มี Z ต่อท้าย) ไม่งั้น Postgres ตีความเวลาท้องถิ่นเป็น UTC
            // แล้วเวลาที่แสดงเลื่อนไป 7 ชั่วโมง
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      final repairId = repair['id'].toString();

      // 3) หาห้องแชทเดิมของผู้เช่า (ผูกกับ room_id) → ถ้ามีใช้ห้องเดิม
      //    ถ้าไม่มีค่อยสร้างใหม่ ผูก repair_id กับงานแรก
      String? chatRoomId;
      if (roomId != null && roomId.isNotEmpty) {
        chatRoomId = await _findExistingRoomByRoomId(roomId);
      }
      if (chatRoomId == null) {
        final chatRoom = await _db
            .from('chat_rooms')
            .insert({
              'repair_id': repairId,
              'room_id': roomId,
              'dormitory_id': dormitoryId,
            })
            .select('id')
            .single();
        chatRoomId = chatRoom['id'].toString();
      }

      // 4) บอทโพสต์ข้อความสรุปงานแจ้งซ่อม (เข้าห้องเดิมของผู้เช่า)
      await _db.from('chat_messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': null,
        'sender_role': 'bot',
        'text': 'สรุปข้อมูลการแจ้งซ่อม',
        'image_url': imageUrl,
        'meta': {
          'type': 'repair_summary',
          'repair_id': repairId,
          'room': roomNumber,
          'category': category,
          'description': description,
          'image_url': imageUrl,
          'reporter_name': reporterName,
        },
      });

      return {'repairId': repairId, 'chatRoomId': chatRoomId};
    } catch (e) {
      // ignore: avoid_print
      print('❌ createRepairWithChat error: $e');
      return {'error': e.toString()};
    }
  }

  /// หา/สร้างห้องแชทของห้องพักปัจจุบัน (สำหรับคุยทั่วไป ไม่ผูกงานซ่อม)
  /// คืน chatRoomId หรือ null ถ้าไม่พบสมาชิก/ห้อง
  Future<String?> getOrCreateRoomChatForCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final member = await _db
          .from('dormitory_members')
          .select('room_id, dormitory_id')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final roomId = member?['room_id']?.toString();
      if (roomId == null || roomId.isEmpty) return null;

      final existing = await _findExistingRoomByRoomId(roomId);
      if (existing != null) {
        // backfill room_id/dormitory_id เผื่อห้องเก่ามีค่าว่าง ทำให้ roommate เข้าถึงไม่ได้
        try {
          await _db.from('chat_rooms').update({
            'room_id': roomId,
            if (member?['dormitory_id'] != null)
              'dormitory_id': member?['dormitory_id']?.toString(),
          }).eq('id', existing);
        } catch (_) {}
        return existing;
      }

      String? dormitoryId = member?['dormitory_id']?.toString();
      dormitoryId ??= await _resolveDormitoryIdForRoom(roomId);

      final created = await _db
          .from('chat_rooms')
          .insert({
            'room_id': roomId,
            'dormitory_id': dormitoryId,
          })
          .select('id')
          .single();
      return created['id'].toString();
    } catch (e) {
      // ignore: avoid_print
      print('❌ getOrCreateRoomChatForCurrentUser error: $e');
      return null;
    }
  }

  /// หา chat_room_id จาก repair_id
  /// โมเดล: 1 ห้องแชทต่อ 1 ห้องพัก (room_id) — สมาชิกในห้องเดียวกันใช้ห้องเดียวกัน
  /// งานซ่อมหลายงานของห้องเดียวกันจะ map มาที่ห้องแชทเดียวกัน
  Future<String?> resolveChatRoomId(String repairId) async {
    try {
      // หา room_id / user_id ของเจ้าของงานซ่อม
      final repair = await _db
          .from('repairs')
          .select('user_id, room_id')
          .eq('id', repairId)
          .maybeSingle();
      if (repair == null) return null;

      final ownerId = repair['user_id']?.toString();
      String? roomId = repair['room_id']?.toString();
      String? dormitoryId;

      // ถ้า repair ไม่มี room_id → หาจาก dormitory_members ของเจ้าของ
      if ((roomId == null || roomId.isEmpty) && ownerId != null) {
        final member = await _db
            .from('dormitory_members')
            .select('room_id, dormitory_id')
            .eq('user_id', ownerId)
            .eq('status', 'approved')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        roomId = member?['room_id']?.toString();
        dormitoryId = member?['dormitory_id']?.toString();
      }

      // fallback: ใช้ห้องของผู้ใช้ปัจจุบัน (เช่น Roommate เปิดงานซ่อมของผู้เช่าหลัก)
      if (roomId == null || roomId.isEmpty) {
        final uid = currentUserId;
        if (uid != null) {
          final me = await _db
              .from('dormitory_members')
              .select('room_id, dormitory_id')
              .eq('user_id', uid)
              .eq('status', 'approved')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          roomId = me?['room_id']?.toString();
          dormitoryId ??= me?['dormitory_id']?.toString();
        }
      }

      // หาห้องแชทเดิมของห้องพักนี้
      if (roomId != null && roomId.isNotEmpty) {
        final existing = await _findExistingRoomByRoomId(roomId);
        if (existing != null) {
          try {
            await _db.from('chat_rooms').update({
              'room_id': roomId,
              if (dormitoryId != null) 'dormitory_id': dormitoryId,
            }).eq('id', existing);
          } catch (_) {}
          return existing;
        }
        dormitoryId ??= await _resolveDormitoryIdForRoom(roomId);
      }

      // ถ้ายังไม่มี dormitoryId ให้ลองดึงจากงานซ่อม/สมาชิก
      if (dormitoryId == null && ownerId != null) {
        final member = await _db
            .from('dormitory_members')
            .select('dormitory_id')
            .eq('user_id', ownerId)
            .eq('status', 'approved')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        dormitoryId = member?['dormitory_id']?.toString();
      }

      // ยังไม่มีห้องแชท → สร้างใหม่ ผูก repair_id กับงานนี้
      final created = await _db
          .from('chat_rooms')
          .insert({
            'repair_id': repairId,
            'room_id': roomId,
            'dormitory_id': dormitoryId,
          })
          .select('id')
          .single();
      return created['id'].toString();
    } catch (e) {
      // ignore: avoid_print
      print('❌ resolveChatRoomId error: $e');
      return null;
    }
  }

  Future<String?> _resolveDormitoryIdForRoom(String roomId) async {
    try {
      final room = await _db
          .from('rooms')
          .select('dormitory_id')
          .eq('id', roomId)
          .maybeSingle();
      return room?['dormitory_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// โหลดข้อความทั้งหมดในห้องแชท (เรียงเก่า→ใหม่)
  Future<List<Map<String, dynamic>>> loadMessages(String chatRoomId) async {
    try {
      final rows = await _db
          .from('chat_messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true);
      return (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ loadMessages error: $e');
      return [];
    }
  }

  /// เช็คว่าข้อความล่าสุดในห้องแชทของผู้ใช้ปัจจุบันมาจาก admin/bot หรือไม่
  /// (= มีข้อความ/สถานะใหม่ที่ผู้เช่ายังไม่ได้ตอบ) → ใช้แสดง badge แจ้งเตือน
  Future<bool> hasUnreadFromAdmin() async {
    final uid = currentUserId;
    if (uid == null) return false;
    try {
      // หา room_id ของผู้ใช้
      final member = await _db
          .from('dormitory_members')
          .select('room_id')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final roomId = member?['room_id']?.toString();
      if (roomId == null || roomId.isEmpty) return false;

      // หาห้องแชทของห้องพักนี้
      final chatRoomId = await _findExistingRoomByRoomId(roomId);
      if (chatRoomId == null) return false;

      // ดูข้อความล่าสุด
      final rows = await _db
          .from('chat_messages')
          .select('sender_role')
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: false)
          .limit(1);
      if ((rows as List).isEmpty) return false;
      final role = rows.first['sender_role']?.toString() ?? '';
      // ข้อความล่าสุดเป็นของ admin หรือ bot → ถือว่ามีสิ่งใหม่ให้ผู้เช่าดู
      return role == 'admin' || role == 'bot';
    } catch (e) {
      // ignore: avoid_print
      print('❌ hasUnreadFromAdmin error: $e');
      return false;
    }
  }

  /// (ฝั่งแอดมิน) เช็คว่ามีงานซ่อมที่ยังไม่เสร็จ หรือข้อความใหม่จากผู้เช่าไหม
  /// → ใช้แสดง badge ที่ไอคอนแจ้งซ่อมของแอดมิน
  Future<bool> hasUnreadForAdmin() async {
    final uid = currentUserId;
    if (uid == null) return false;
    try {
      // หา dormitory ที่แอดมินดูแล
      final dorms = await _db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);
      final dormIds = (dorms as List).map((d) => d['id'].toString()).toList();
      if (dormIds.isEmpty) return false;

      // มีงานซ่อมที่ยังไม่เสร็จไหม (new / in_progress)
      final members = await _db
          .from('dormitory_members')
          .select('user_id')
          .inFilter('dormitory_id', dormIds);
      final userIds =
          (members as List).map((m) => m['user_id'].toString()).toSet().toList();
      if (userIds.isEmpty) return false;

      final activeRepairs = await _db
          .from('repairs')
          .select('id')
          .inFilter('user_id', userIds)
          .neq('status', 'done')
          .limit(1);
      if ((activeRepairs as List).isNotEmpty) return true;

      // ไม่งั้นเช็คว่ามีห้องแชทที่ข้อความล่าสุดเป็นของผู้เช่า
      final rooms = await _db
          .from('chat_rooms')
          .select('id')
          .inFilter('dormitory_id', dormIds);
      for (final r in (rooms as List)) {
        final chatRoomId = r['id']?.toString() ?? '';
        if (chatRoomId.isEmpty) continue;
        final msg = await _db
            .from('chat_messages')
            .select('sender_role')
            .eq('chat_room_id', chatRoomId)
            .order('created_at', ascending: false)
            .limit(1);
        if ((msg as List).isNotEmpty) {
          final role = msg.first['sender_role']?.toString() ?? '';
          if (role == 'tenant' || role == 'roommate') return true;
        }
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('❌ hasUnreadForAdmin error: $e');
      return false;
    }
  }

  /// Realtime stream ของข้อความในห้องนี้ (เรียงเก่า→ใหม่)
  /// ข้อความใหม่จะเด้งเข้ามาเองโดยไม่ต้อง refresh
  Stream<List<Map<String, dynamic>>> messagesStream(String chatRoomId) {
    return _db
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((r) => Map<String, dynamic>.from(r)).toList());
  }

  /// ส่งข้อความ (ผู้เช่า/Roommate/แอดมิน)
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderRole, // 'tenant' | 'roommate' | 'admin'
    String? text,
    String? imageUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) return false;
    if ((text == null || text.trim().isEmpty) &&
        (imageUrl == null || imageUrl.isEmpty)) {
      return false;
    }
    try {
      await _db.from('chat_messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': uid,
        'sender_role': senderRole,
        'text': text?.trim(),
        'image_url': imageUrl,
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ sendMessage error: $e');
      return false;
    }
  }

  /// ดึงรายการงานซ่อมทั้งหมดในห้องแชทนี้ (ผ่าน room_id ของห้องแชท)
  /// คืน list ของ {id, category, status, created_at} เรียงใหม่→เก่า
  Future<List<Map<String, dynamic>>> getRepairsForChatRoom(
    String chatRoomId,
  ) async {
    try {
      // หา room_id ของห้องแชท
      final room = await _db
          .from('chat_rooms')
          .select('room_id')
          .eq('id', chatRoomId)
          .maybeSingle();
      final roomId = room?['room_id']?.toString();
      if (roomId == null || roomId.isEmpty) return [];

      // หา user ทั้งหมดในห้องพักนี้
      final members = await _db
          .from('dormitory_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('status', 'approved');
      final userIds =
          (members as List).map((m) => m['user_id'].toString()).toList();
      if (userIds.isEmpty) return [];

      final rows = await _db
          .from('repairs')
          .select('id, category, status, created_at')
          .inFilter('user_id', userIds)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ getRepairsForChatRoom error: $e');
      return [];
    }
  }

  /// แอดมินเปลี่ยนสถานะงานซ่อม + บอทโพสต์แจ้งอัตโนมัติ
  /// [category] = ประเภทงาน (เช่น "ระบบไฟฟ้า") เพื่อระบุว่างานไหนเปลี่ยน
  Future<bool> updateRepairStatus({
    required String repairId,
    required String chatRoomId,
    required String status, // 'new' | 'in_progress' | 'done'
    String? category,
  }) async {
    try {
      // .select() กลับมาเพื่อตรวจว่ามีแถวถูกอัปเดตจริง (0 แถว = RLS บล็อก)
      final updated = await _db
          .from('repairs')
          .update({'status': status})
          .eq('id', repairId)
          .select('id');

      if ((updated as List).isEmpty) {
        // ไม่มีแถวถูกอัปเดต → RLS บล็อก UPDATE
        return false;
      }

      // ระบุประเภทงานในข้อความถ้ามี → ผู้เช่ารู้ว่างานไหนเปลี่ยน
      final jobText = (category != null && category.isNotEmpty)
          ? 'งานซ่อม [$category] '
          : 'สถานะการซ่อม';
      await _db.from('chat_messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': null,
        'sender_role': 'bot',
        'text': '${jobText}เปลี่ยนสถานะเป็น "${statusLabel(status)}"\n'
            'หากพบปัญหาเพิ่มเติมสามารถแจ้งได้ตลอดเลยครับ',
        'meta': {
          'type': 'status_change',
          'status': status,
          'repair_id': repairId,
          'category': category,
        },
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ updateRepairStatus error: $e');
      return false;
    }
  }

  Future<String> _resolveName(String uid) async {
    try {
      final t = await _db
          .from('tenants')
          .select('full_name')
          .eq('id', uid)
          .maybeSingle();
      final tn = t?['full_name']?.toString() ?? '';
      if (tn.isNotEmpty) return tn;

      final r = await _db
          .from('roommate_invites')
          .select('full_name')
          .eq('id', uid)
          .maybeSingle();
      return r?['full_name']?.toString() ?? 'ผู้เช่า';
    } catch (_) {
      return 'ผู้เช่า';
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'done':
        return 'เสร็จสิ้น';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'new':
      default:
        return 'งานใหม่';
    }
  }
}
