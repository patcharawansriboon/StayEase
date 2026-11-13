import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/room_members_service.dart';

import 'widgets/app_sizes.dart';
class DormitoryRequestScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  /// id ของแถวคำขอใน dormitory_members ที่เลือกจากหน้า request.dart
  final String? requestId;

  const DormitoryRequestScreen({
    super.key,
    this.onBack,
    this.onApprove,
    this.onReject,
    this.requestId,
  });

  @override
  State<DormitoryRequestScreen> createState() => DormitoryRequestScreenState();
}

class DormitoryRequestScreenState extends State<DormitoryRequestScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  /// ปุ่มที่กดอยู่ ('approved' / 'rejected') เพื่อให้แสดงวงกลมหมุนเฉพาะปุ่มนั้น
  /// ถ้าใช้ flag เดียวกันทั้งคู่จะกลายเป็นวงกลมหมุนพร้อมกัน
  String? _submittingFor;
  Map<String, dynamic>? _request;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

   /// เรียกจากภายนอกเมื่อกลับมาที่หน้านี้
   void refresh() {
     _loadRequest();
   }


  Future<void> _loadRequest() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _request = null;
          _error = 'ยังไม่ได้เข้าสู่ระบบ กรุณาล็อกอินใหม่';
        });
        return;
      }

      final isAdmin = await Supabase.instance.client
          .from('admins')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (isAdmin == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _request = null;
          _error =
              'บัญชีนี้ไม่ใช่ผู้ดูแลหอพัก กรุณาออกจากระบบแล้วล็อกอินในสิทธิ์ผู้ดูแลอีกครั้ง';
        });
        return;
      }

      final dormRows = await Supabase.instance.client
          .from('dormitories')
          .select('id, dorm_code')
          .eq('created_by', user.id);

      if ((dormRows as List).isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _request = null;
          _error = 'ไม่พบหอพักที่คุณสร้าง กรุณาสร้างหอพักก่อน';
        });
        return;
      }

      final dormIds = (dormRows as List)
          .map((d) => d['id'].toString())
          .toList();

      // ดึงเฉพาะแถวของคำขอที่เลือกจากหน้า request.dart (ส่ง id มา ไม่ใช่ index
      // เพราะสองหน้านี้กรองสถานะไม่เหมือนกัน → index ไม่ตรงกัน)
      // หมายเหตุ: ห้ามต่อ .order() ก่อน .eq() เพราะ order() จะเปลี่ยนชนิด
      // ของ builder ทำให้เรียก eq() ไม่ได้
      final base = Supabase.instance.client
          .from('dormitory_members')
          .select(
            'id, user_id, status, member_type, created_at, room_id, prev_room_id, prev_dormitory_id, prev_member_type, dormitories!dormitory_members_dormitory_id_fkey(dorm_code), rooms!dormitory_members_room_id_fkey(room_number)',
          )
          .inFilter('dormitory_id', dormIds);

      final hasId = widget.requestId != null && widget.requestId!.isNotEmpty;

      final row = await (hasId ? base.eq('id', widget.requestId!) : base)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (row == null) {
        setState(() {
          _isLoading = false;
          _request = null;
          _error = 'ไม่พบคำขอเข้าหอพัก';
        });
        return;
      }

      final userId = row['user_id'].toString();
      final memberType = row['member_type']?.toString() ?? 'tenant';
      final isRoommate = memberType == 'roommate';
      final isUpgrade = memberType == 'upgrade';
      final isLeave = memberType == 'leave';

      // upgrade และ roommate เก็บชื่อใน roommate_invites
      // tenant เก็บใน tenants — แต่ถ้าเคยเป็น roommate มาก่อน (เช่น leave แล้วสมัครใหม่)
      // ข้อมูลอาจอยู่ใน roommate_invites จึง fallback ไปดึงจากที่นั่น
      Map<String, dynamic>? person;
      if (isRoommate || isUpgrade) {
        person = await Supabase.instance.client
            .from('roommate_invites')
            .select('full_name, phone, invite_code')
            .eq('id', userId)
            .maybeSingle();
      } else {
        person = await Supabase.instance.client
            .from('tenants')
            .select('full_name, phone')
            .eq('id', userId)
            .maybeSingle();

        // fallback: tenant ไม่มีข้อมูล → ลองดึงจาก roommate_invites
        if (person == null || (person['full_name']?.toString() ?? '').isEmpty) {
          final fromRoommate = await Supabase.instance.client
              .from('roommate_invites')
              .select('full_name, phone, invite_code')
              .eq('id', userId)
              .maybeSingle();
          if (fromRoommate != null) person = fromRoommate;
        }
      }

      Map<String, dynamic>? avatarRow = await Supabase.instance.client
          .from('tenants')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      if (avatarRow == null ||
          (avatarRow['avatar_url']?.toString() ?? '').isEmpty) {
        avatarRow = await Supabase.instance.client
            .from('roommate_invites')
            .select('avatar_url')
            .eq('id', userId)
            .maybeSingle();
      }

       // ดึงหมายเลขห้องเดิม (ห้องที่เป็น Roommate อยู่) สำหรับคำขอ upgrade
       String prevRoomNumber = '-';
       final prevRoomId = row['prev_room_id']?.toString();
       if (prevRoomId != null && prevRoomId.isNotEmpty) {
         try {
           final prevRoom = await Supabase.instance.client
               .from('rooms')
               .select('room_number')
               .eq('id', prevRoomId)
               .maybeSingle();
           prevRoomNumber = prevRoom?['room_number']?.toString() ?? '-';
         } catch (_) {}
       }

       if (!mounted) return;
       setState(() {
        _isLoading = false;
        final dorm = row['dormitories'] as Map<String, dynamic>?;
        _request = {
          'id': row['id'],
          'userId': userId,
          'isRoommate': isRoommate,
          'isUpgrade': isUpgrade,
          'isLeave': isLeave,
          'memberType': memberType,
          'fullName': person?['full_name'] ?? 'Unknown',
          'phone': person?['phone']?.toString() ?? '',
          'inviteCode': person?['invite_code']?.toString() ?? '',
          'avatarUrl': avatarRow?['avatar_url']?.toString() ?? '',
          'dormCode': dorm?['dorm_code'] ?? '-',
           'roomNumber':
               (row['rooms'] as Map<String, dynamic>?)?['room_number']
                   ?.toString() ??
               '-',
           'prevRoomNumber': prevRoomNumber,
          'roomId': row['room_id']?.toString(),
          'dormitoryId': row['dormitory_id']?.toString(),
          'status': row['status'] ?? 'pending',
          'date': row['created_at'] ?? '',
          // snapshot สถานะ Roommate เดิม (ใช้ตอนปฏิเสธ upgrade เพื่อคืนค่า)
          'prevRoomId': row['prev_room_id']?.toString(),
          'prevDormitoryId': row['prev_dormitory_id']?.toString(),
          'prevMemberType': row['prev_member_type']?.toString(),
        };
        _error = null;
      });
    } catch (e) {
      print('❌ Load request detail error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _request = null;
        _error = 'โหลดข้อมูลคำขอไม่สำเร็จ: $e';
      });
    }
  }

  Future<void> _setStatus(String status) async {
    final req = _request;
    if (req == null) return;

    setState(() {
      _isSubmitting = true;
      _submittingFor = status;
    });
    try {
      // ถ้าเป็น Roommate ต้องตรวจห้องก่อน แล้วค่อย update status
      if (status == 'approved' && req['isRoommate'] == true) {
        final service = RoomMembersService();
        var roomId = await service.resolveRoomForRoommate(
          req['userId'].toString(),
        );

        if (roomId == null) {
          final member = await Supabase.instance.client
              .from('dormitory_members')
              .select('room_id')
              .eq('id', req['id'])
              .maybeSingle();
          roomId = member?['room_id']?.toString();
        }

        if (roomId != null && roomId.isNotEmpty) {
          final canJoin = await service.canJoinRoom(
            roomId,
            excludeMemberId: req['id'].toString(),
          );
          if (!canJoin) {
            if (!mounted) return;
            setState(() {
              _isSubmitting = false;
              _submittingFor = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'ห้องนี้เต็มแล้ว ไม่สามารถอนุมัติ Roommate เพิ่มได้',
                  style: TextStyle(fontFamily: 'Noto Sans Thai'),
                ),
                backgroundColor: Color(0xFFFF0303),
              ),
            );
            return;
          }
          // ผ่าน → update room_id ก่อน update status
          await Supabase.instance.client
              .from('dormitory_members')
              .update({'room_id': roomId})
              .eq('id', req['id']);
        }
      }

      // อนุมัติคำขอออกจากหอพัก: ผู้เช่าหลักออกจากหอพัก
      // → Roommate ที่อยู่ห้องเดียวกันถูกนำออกจากห้องด้วย
      if (status == 'approved' && req['isLeave'] == true) {
        await _approveLeave(req);
      } else if (status == 'rejected' && req['isLeave'] == true) {
        await _rejectLeave(req);
      } else if (status == 'approved' && req['isUpgrade'] == true) {
        await Supabase.instance.client
            .from('dormitory_members')
            .update({
              'status': 'approved',
              'member_type': 'tenant',
              'prev_room_id': null,
              'prev_dormitory_id': null,
              'prev_member_type': null,
            })
            .eq('id', req['id']);

        // ผูกผู้เช่าหลักเข้าห้องใหม่
        final newRoomId = await Supabase.instance.client
            .from('dormitory_members')
            .select('room_id')
            .eq('id', req['id'])
            .maybeSingle();
        final roomId = newRoomId?['room_id']?.toString();
        if (roomId != null && roomId.isNotEmpty) {
          await Supabase.instance.client
              .from('rooms')
              .update({'tenant_id': req['userId']})
              .eq('id', roomId);
        }

        // insert เข้า tenants table
        await Supabase.instance.client.from('tenants').upsert({
          'id': req['userId'],
          'full_name': req['fullName'],
          'phone': req['phone'],
          'dorm_code': req['dormCode'],
          'status': 'approved',
          'created_at': DateTime.now().toIso8601String(),
        });

        await Supabase.instance.client
            .from('roommate_invites')
            .update({'status': 'approved', 'is_verified': true})
            .eq('id', req['userId']);
      } else if (status == 'rejected' && req['isUpgrade'] == true) {
        // ปฏิเสธ upgrade: คืนแถวกลับเป็น Roommate ห้องเดิมจาก snapshot
        final prevDorm = req['prevDormitoryId']?.toString();
        final prevRoom = req['prevRoomId']?.toString();
        final prevType = (req['prevMemberType']?.toString().isNotEmpty ?? false)
            ? req['prevMemberType'].toString()
            : 'roommate';
        await Supabase.instance.client
            .from('dormitory_members')
            .update({
              'status': 'approved',
              'member_type': prevType,
              if (prevDorm != null) 'dormitory_id': prevDorm,
              'room_id': prevRoom,
              'prev_room_id': null,
              'prev_dormitory_id': null,
              'prev_member_type': null,
            })
            .eq('id', req['id']);

        // คืนสถานะ roommate_invites ให้สอดคล้อง (ยังเป็น Roommate อยู่)
        await Supabase.instance.client
            .from('roommate_invites')
            .update({'status': 'approved', 'is_verified': true})
            .eq('id', req['userId']);
      } else {
        // ── เส้นทางเดิม (roommate / ผู้เช่าหลักปกติ) ──
        // update status หลังจากตรวจผ่านแล้ว
        await Supabase.instance.client
            .from('dormitory_members')
            .update({'status': status})
            .eq('id', req['id']);

        if (status == 'approved') {
          if (req['isRoommate'] == true) {
            // room_id ถูก set ไว้แล้วในขั้นตอนก่อน update status
            await Supabase.instance.client
                .from('roommate_invites')
                .update({'status': 'approved', 'is_verified': true})
                .eq('id', req['userId']);
          } else {
            await Supabase.instance.client
                .from('tenants')
                .update({'status': 'approved'})
                .eq('id', req['userId']);
            final roomId = await RoomMembersService().ensureRoomForMember(
              req['id'].toString(),
            );
            if (roomId != null && roomId.isNotEmpty) {
              await Supabase.instance.client
                  .from('rooms')
                  .update({'tenant_id': req['userId']})
                  .eq('id', roomId);
            }
          }
        } else {
          // ปฏิเสธ (เฉพาะ roommate / ผู้เช่าหลักปกติ — upgrade จัดการด้านบนแล้ว)
          if (req['isRoommate'] == true) {
            await Supabase.instance.client
                .from('roommate_invites')
                .update({'status': 'rejected'})
                .eq('id', req['userId']);
          } else {
            await Supabase.instance.client
                .from('tenants')
                .delete()
                .eq('id', req['userId']);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _request = {...req, 'status': status};
        _isSubmitting = false;
        _submittingFor = null;
      });
      widget.onApprove?.call();
    } catch (e) {
      print('❌ Update request status error: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submittingFor = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'อัปเดตสถานะไม่สำเร็จ กรุณาลองอีกครั้ง',
            style: const TextStyle(fontFamily: 'Noto Sans Thai'),
          ),
          backgroundColor: const Color(0xFFFF0303),
        ),
      );
    }
  }

  /// อนุมัติคำขอออกจากหอพัก
  /// - ผู้เช่าหลัก → ออกจากหอพัก (status = 'left', member_type = 'left')
  /// - Roommate ที่อยู่ห้องเดียวกัน → ถูกนำออกจากห้องด้วย
  Future<void> _approveLeave(Map<String, dynamic> req) async {
    final db = Supabase.instance.client;
    final roomId = req['roomId']?.toString() ?? '';
    final userId = req['userId'].toString();

    if (roomId.isNotEmpty) {
      // 1) Roommate ในห้องเดียวกัน → ออกจากห้องด้วย
      final roommates = await db
          .from('dormitory_members')
          .select('id, user_id')
          .eq('room_id', roomId)
          .eq('member_type', 'roommate')
          .eq('status', 'approved');

      for (final rm in (roommates as List)) {
        final rmId = rm['id']?.toString();
        if (rmId == null) continue;

        await db
            .from('dormitory_members')
            .update({
              'status': 'left',
              'member_type': 'left',
              'room_id': null,
            })
            .eq('id', rmId);

        final rmUserId = rm['user_id']?.toString();
        if (rmUserId != null) {
          await db
              .from('roommate_invites')
              .update({'status': 'left', 'is_verified': false})
              .eq('id', rmUserId);
        }
      }

      // 2) ล้างผู้เช่าห้องในห้องนั้น (ห้องกลับเป็นห้องว่าง)
      await db.from('rooms').update({'tenant_id': null}).eq('id', roomId);
    }

    // 3) ผู้เช่าหลักออกจากหอพัก
    await db
        .from('dormitory_members')
        .update({
          'status': 'left',
          'member_type': 'left',
          'room_id': null,
          'prev_room_id': null,
          'prev_dormitory_id': null,
          'prev_member_type': null,
        })
        .eq('id', req['id']);

    // 4) อัปเดตสถานะในตาราง tenants
    await db.from('tenants').update({'status': 'left'}).eq('id', userId);

    print('✅ Approved leave request: member=${req['id']} room=$roomId');
  }

  /// ปฏิเสธคำขอออกจากหอพัก → คืนสถานะผู้เช่าหลักเดิม
  Future<void> _rejectLeave(Map<String, dynamic> req) async {
    final db = Supabase.instance.client;
    final prevRoom = req['prevRoomId']?.toString();
    final prevType = (req['prevMemberType']?.toString().isNotEmpty ?? false)
        ? req['prevMemberType'].toString()
        : 'tenant';

    final data = <String, dynamic>{
      'status': 'approved',
      'member_type': prevType,
      'prev_room_id': null,
      'prev_dormitory_id': null,
      'prev_member_type': null,
    };
    if (prevRoom != null && prevRoom.isNotEmpty) {
      data['room_id'] = prevRoom;
    }

    await db.from('dormitory_members').update(data).eq('id', req['id']);
    print('❌ Rejected leave request: member=${req['id']}');
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final d =
          '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      final t =
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
      return '$d $t น.';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _request == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _error ?? 'ไม่มีคำขอเข้าหอพัก',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildDetail(_request!),
                  ),
          ),
          // แสดงแถบปุ่มตลอดที่มีคำขอ ไม่ว่าสถานะจะเป็นอะไร
          // (ภายใน _buildBottomButtons จะสลับเป็นปุ่มสถานะเองเมื่อไม่ใช่ pending)
          if (_request != null) _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildDetail(Map<String, dynamic> r) {
    final isRoommate = r['isRoommate'] == true;
    final isUpgrade = r['isUpgrade'] == true;
    final isLeave = r['isLeave'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        // ── ผู้ขอ ──
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage:
                  (r['avatarUrl']?.toString().isNotEmpty ?? false)
                      ? NetworkImage(r['avatarUrl'])
                      : const AssetImage('assets/images/user_avatar.png')
                          as ImageProvider,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['fullName'],
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBCDEFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLeave
                          ? 'ขอออกจากหอพัก'
                          : isUpgrade
                          ? 'ขอเปลี่ยนเป็นผู้เช่าหลัก'
                          : isRoommate
                          ? 'ขอเข้าร่วมห้อง'
                          : 'ขอเข้าหอพัก',
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2A5D9F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(r['date']?.toString() ?? ''),
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'ข้อมูลส่วนตัว',
          rows: [
            ['ชื่อ-นามสกุล', r['fullName']?.toString() ?? '-'],
            ['เบอร์มือถือ', r['phone']?.toString() ?? '-'],
          ],
        ),
        const SizedBox(height: 12),
        _buildSection(
          title: isLeave
              ? 'ข้อมูลการขอออกจากหอพัก'
              : isUpgrade
              ? 'ข้อมูลการขอเปลี่ยนสถานะ'
              : isRoommate
              ? 'ข้อมูลการเข้าร่วมห้อง'
              : 'ข้อมูลการเข้าพัก',
          rows: isLeave
              ? [
                  ['รหัสหอพัก', r['dormCode']?.toString() ?? '-'],
                  ['ห้องปัจจุบัน', r['roomNumber']?.toString() ?? '-'],
                  ['ประเภทคำขอ', 'ขอออกจากหอพัก'],
                  [
                    'หมายเหตุ',
                    'เมื่ออนุมัติ Roommate ในห้องเดียวกันจะถูกนำออกจากห้องด้วย',
                  ],
                ]
              : isUpgrade
              ? [
                   ['รหัสหอพัก', r['dormCode']?.toString() ?? '-'],
                   ['ห้องที่ต้องการ', r['roomNumber']?.toString() ?? '-'],
                   ['ประเภทคำขอ', 'ขอเปลี่ยนเป็นผู้เช่าหลัก'],
                ]
              : isRoommate
               ? [
                   ['รหัสหอพัก', r['dormCode']?.toString() ?? '-'],
                   ['เลขห้อง', r['roomNumber']?.toString() ?? '-'],
                   ['รหัสคำเชิญ', r['inviteCode']?.toString() ?? '-'],
                   ['ประเภท', 'Roommate'],
                 ]
              : [
                  ['รหัสหอพัก', r['dormCode']?.toString() ?? '-'],
                  ['ห้องที่ต้องการ', r['roomNumber']?.toString() ?? '-'],
                  ['ประเภท', 'ผู้เช่าหลัก'],
                ],
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final status = _request?['status'] as String? ?? 'pending';
    final isPending = status == 'pending';

    // หลังอนุมัติ/ปฏิเสธแล้ว ยังคงแถบปุ่มไว้ แต่เปลี่ยนเป็นป้ายสถานะ
    // (เดิมกลับ status ทำให้แถบนี้หายไป หน้าจอขยับขึ้นทันที)
    // เป็นแค่กรอบ ไม่มีสีพื้นหลัง และกดไม่ได้ ให้ดูเป็นปุ่มที่หมดสถานะแล้ว
    if (!isPending) {
      final isApproved = status == 'approved';
      final accent = isApproved
          ? const Color(0xFF5B93D4)
          : const Color(0xFFFF0303);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: accent, width: 1.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            isApproved ? 'อนุมัติแล้ว' : 'ปฏิเสธคำขอแล้ว',
            style: TextStyle(fontFamily: 'Noto Sans Thai', fontSize: 14, color: accent),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _setStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFF0303)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submittingFor == 'rejected'
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF0303),
                        ),
                      )
                    : const Text(
                        'ปฏิเสธ',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFFFF0303),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _setStatus('approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B93D4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submittingFor == 'approved'
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'อนุมัติ',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<List<String>> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4181CB),
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      r[0],
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r[1],
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'รายละเอียดคำขอ',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}
