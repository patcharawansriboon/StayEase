import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/user_bottom_nav.dart';

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

  // ── รายการงานซ่อมทั้งหมดของห้อง ──
  List<Map<String, dynamic>> _allRepairs = [];
  bool _isApprovedMember = false;

  static const Color kTextSecondary = Color(0xFF70766E);

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
          .select(
              'id, user_id, room_number, reporter_name, category, description, status, created_at')
          .inFilter('user_id', roomUserIds)
          .order('created_at', ascending: false);

      final allRepairs =
          (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();

      if (!mounted) return;
      setState(() {
        _allRepairs = allRepairs;
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
                : RefreshIndicator(
                    onRefresh: _loadRepairs,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        // การ์ด "งานซ่อมของฉัน" — แสดงตั้งแต่เริ่มใช้งาน
                        _buildMyRepairsCard(),
                      ],
                    ),
                  ),
          ),
          // ปุ่ม "แจ้งซ่อม" วางเหนือแถบเมนูล่าง ไม่ให้ทับไอคอนในแถบ
          // แสดงเฉพาะผู้เช่าที่เข้าร่วมหอพักแล้ว (อนุมัติแล้วและมีห้อง)
          if (_isApprovedMember)
            SizedBox(
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: GestureDetector(
                    onTap: widget.onNewRepair,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F8FDB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('แจ้งซ่อม',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Thai',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                )),
                          ],
                        ),
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

  /// การ์ด "งานซ่อมของฉัน" — กดแล้วไปหน้าแชทห้องพัก (คุยทั่วไป), ปุ่ม + แจ้งซ่อมสำหรับสร้างใหม่
  Widget _buildMyRepairsCard() {
    final hasActive = _allRepairs.any((r) => (r['status']?.toString() ?? 'new') != 'done');
    final activeCount = _allRepairs.where((r) => (r['status']?.toString() ?? 'new') != 'done').length;

    // รวมประเภทงานที่ไม่ซ้ำกัน (เฉพาะงานที่ยังไม่เสร็จ)
    final categories = <String>[];
    for (final r in _allRepairs) {
      final status = r['status']?.toString() ?? 'new';
      if (status != 'done') {
        final c = r['category']?.toString() ?? '';
        if (c.isNotEmpty && !categories.contains(c)) categories.add(c);
      }
    }

    return InkWell(
      onTap: () {
        // ignore: avoid_print
        print('🔧 [Report] Opening room chat from card');
        widget.onOpenRepairChat?.call('');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE0E0E0),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวการ์ด (เหมือนแบบเก่า)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(_allRepairs.isNotEmpty ? _allRepairs.first : {}),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'งานซ่อมของฉัน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              _allRepairs.isNotEmpty
                                  ? _formatTime(_allRepairs.first['created_at']?.toString())
                                  : '',
                              style: const TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // badge จำนวนงานค้าง / เสร็จทั้งหมด (อยู่ขวา ข้างบนไอคอนลูกศร)
                    if (hasActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE9E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeCount งานค้าง',
                          style: const TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 12,
                            color: Color(0xFFF16C6C),
                          ),
                        ),
                      )
                    else if (_allRepairs.isNotEmpty)
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
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right, size: 24, color: Color(0xFF4F8FDB)),
                  ],
                ),
              ],
            ),
            // แสดงข้อความเมื่อไม่มีงานซ่อม / ชิปประเภทงานซ่อมเมื่อมี
            if (_allRepairs.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'คุณยังไม่มีรายการแจ้งซ่อมในขณะนี้',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                  color: kTextSecondary,
                ),
              ),
            ] else if (categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: categories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cat,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Color(0xFF4F8FDB),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
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

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return '';
    }
  }

  Widget _buildAvatar(Map<String, dynamic> repair) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEEF4FB),
      ),
      child: const Icon(
        Icons.build_outlined,
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