import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/user_bottom_nav.dart';
import '../services/chat_service.dart';

import '../widgets/app_sizes.dart';
/// หน้า "แจ้งซ่อม" สำหรับผู้เช่า (User)
/// แสดงรายการงานซ่อมของห้องตัวเอง (ผู้เช่าหลัก + Roommate เห็นงานของห้องเดียวกัน)
/// กดการ์ด → เปิดห้องแชทงานนั้น, กดปุ่ม + → แจ้งซ่อมใหม่ด้วยบอท
class UserReportARepairScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToBill;

  /// แท็บ "บิล/ค่าเช่า" ในแถบเมนูล่าง (ไปหน้า rental_fee เหมือนหน้าอื่น)
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToReportRepair;

  /// กด "แจ้งซ่อมใหม่" → เปิดแชทบอท (repairId = null)
  final VoidCallback? onNewRepair;

  /// กดการ์ดงานซ่อม → เปิดห้องแชทงานนั้น
  final ValueChanged<String>? onOpenRepairChat;

  final int selectedIndex;
  final bool showChatBadge;

  const UserReportARepairScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToBill,
    this.onNavigateToRentalFee,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onNavigateToProfile,
    this.onNavigateToReportRepair,
    this.onNewRepair,
    this.onOpenRepairChat,
    this.selectedIndex = 2,
    this.showChatBadge = false,
  });

  @override
  State<UserReportARepairScreen> createState() =>
      _UserReportARepairScreenState();
}

class _UserReportARepairScreenState extends State<UserReportARepairScreen> {
  final _db = Supabase.instance.client;

  bool _loading = true;

  // ── สรุปห้องแชทซ่อม (แนวทาง A) ──
  bool _hasAnyRepair = false;      // เคยมีงานซ่อมไหม
  int _activeCount = 0;            // จำนวนงานที่ยังไม่เสร็จ (new + in_progress)
  String _latestRepairId = '';     // repairId ล่าสุด (ใช้เปิดห้องแชท)
  String _lastMessage = '';        // preview ประเภทงานที่ค้าง
  String _lastMessageTime = '';    // เวลาข้อความล่าสุด
  bool _isApprovedMember = false;  // สถานะสมาชิกที่อนุมัติแล้ว

  static const Color kTextSecondary = Color(0xFF70766E);
  static const Color kBorderColor = Color(0xFFD9D9D9);

  /// ตำแหน่งแท็บ "แจ้งซ่อม" (icon_message) ในแถบเมนูล่าง
  static const int kRepairTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadRepairs();
  }

  /// โหลดงานซ่อมของห้องตัวเอง
  /// RLS: ผู้เช่าเห็นงานที่ตัวเองแจ้ง + งานของเพื่อนร่วมห้อง (ผ่าน room ของ chat)
  /// ที่นี่ใช้วิธีง่าย: ดึงงานที่ user_id ของทุกคนในห้องเดียวกัน
  Future<void> _loadRepairs() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      // หา room ของตัวเอง
      final me = await _db
          .from('dormitory_members')
          .select('room_id')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final roomId = me?['room_id']?.toString();

      final isApproved = me != null && roomId != null && roomId.isNotEmpty;

      // รายชื่อ user ทั้งหมดในห้องเดียวกัน (ผู้เช่าหลัก + Roommate)
      List<String> roomUserIds = [uid];
      if (roomId != null && roomId.isNotEmpty) {
        final members = await _db
            .from('dormitory_members')
            .select('user_id')
            .eq('room_id', roomId)
            .eq('status', 'approved');
        roomUserIds =
            (members as List).map((m) => m['user_id'].toString()).toList();
        if (!roomUserIds.contains(uid)) roomUserIds.add(uid);
      }

      final rows = await _db
          .from('repairs')
          .select('id, user_id, room_number, reporter_name, category, description, status, created_at')
          .inFilter('user_id', roomUserIds)
          .order('created_at', ascending: false);

      final allRepairs =
          (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();

      // คำนวณสรุปห้องแชทซ่อม
      final activeRepairs = allRepairs
          .where((r) => (r['status']?.toString() ?? 'new') != 'done')
          .toList();
      final activeCount = activeRepairs.length;
      final latest = allRepairs.isNotEmpty ? allRepairs.first : null;
      final latestRepairId = latest?['id']?.toString() ?? '';

      // รวมประเภทงานที่ยัง active (ไม่ซ้ำ) → แสดงเป็น preview
      final categories = <String>[];
      for (final r in activeRepairs) {
        final c = r['category']?.toString() ?? '';
        if (c.isNotEmpty && !categories.contains(c)) categories.add(c);
      }

      String lastMessage;
      if (categories.isNotEmpty) {
        lastMessage = 'แจ้งซ่อม: ${categories.join(', ')}';
      } else {
        lastMessage = 'ไม่มีงานค้าง';
      }

      // ดึงเวลาข้อความล่าสุดในห้องแชท
      String lastMessageTime = '';
      if (latestRepairId.isNotEmpty) {
        try {
          final chatRoomId = await ChatService().resolveChatRoomId(latestRepairId);
          if (chatRoomId != null) {
            final msgRows = await _db
                .from('chat_messages')
                .select('created_at')
                .eq('chat_room_id', chatRoomId)
                .order('created_at', ascending: false)
                .limit(1);
            if (msgRows.isNotEmpty) {
              lastMessageTime = _formatTime(msgRows.first['created_at']?.toString());
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _hasAnyRepair = allRepairs.isNotEmpty;
        _activeCount = activeCount;
        _latestRepairId = latestRepairId;
        _lastMessage = lastMessage;
        _lastMessageTime = lastMessageTime;
        _isApprovedMember = isApproved;
        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ load repairs (user) error: $e');
      if (mounted) setState(() => _loading = false);
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
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F8FDB)))
                : !_hasAnyRepair
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadRepairs,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [_buildChatRoomCard()],
                        ),
                      ),
          ),
          // ปุ่ม "แจ้งซ่อม" วางเหนือแถบเมนูล่าง ไม่ให้ทับไอคอนในแถบ
          // แสดงเฉพาะผู้เช่าที่เข้าร่วมหอพักแล้ว (อนุมัติแล้วและมีห้อง)
          if (_isApprovedMember)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 12),
                child: GestureDetector(
                  onTap: widget.onNewRepair,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F8FDB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('แจ้งซ่อม',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: kPageTitleFontSize,
              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.build_outlined, size: 48, color: Color(0xFFBBBBBB)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _isApprovedMember
                ? 'ยังไม่มีงานแจ้งซ่อม\nกดปุ่ม "แจ้งซ่อม" เพื่อเริ่ม'
                : 'ยังไม่ได้เข้าร่วมหอพัก\nเมื่อเข้าร่วมแล้วจึงจะแจ้งซ่อมได้',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Noto Sans Thai', fontSize: 14, color: Color(0xFF999999)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      child: Column(
        children: const [
          SizedBox(height: 8),
          Text(
            'แจ้งซ่อม',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Card แบบ "ห้องแชทซ่อม" (แนวทาง A) — 1 card = ห้องคุยกับแอดมิน
  Widget _buildChatRoomCard() {
    final hasActive = _activeCount > 0;
    return GestureDetector(
      onTap: () {
        if (_latestRepairId.isNotEmpty) {
          widget.onOpenRepairChat?.call(_latestRepairId);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'งานซ่อมของฉัน',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // badge จำนวนงานค้าง / เสร็จทั้งหมด
                      if (hasActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE9E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_activeCount งานค้าง',
                            style: const TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 12,
                              color: Color(0xFFF16C6C),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F7EC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'เสร็จทั้งหมด',
                            style: TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _lastMessage.isNotEmpty ? _lastMessage : 'เริ่มการสนทนา',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 13,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _lastMessageTime,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return '';
    }
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEEF4FB),
      ),
      child: const Icon(
        Icons.apartment,
        size: 26,
        color: Color(0xFF4F8FDB),
      ),
    );
  }

  Widget _buildBottomNav() {
    // ใช้แถบเมนูล่างตัวเดียวกับหน้าหลักอื่น โดยวงกลมสีเหลืองอยู่ที่ไอคอนที่ 3 (แจ้งซ่อม)
    return UserBottomNav(
      selectedIndex: kRepairTabIndex,
      onHome: widget.onNavigateToHome,
      onBill: widget.onNavigateToRentalFee ?? widget.onNavigateToBill,
      onChat: widget.onNavigateToReportRepair ?? widget.onNavigateToChat,
      onAnnounce: widget.onNavigateToAnnounce,
      onProfile: widget.onNavigateToProfile,
      showChatBadge: widget.showChatBadge,
    );
  }
}
