import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/user_bottom_nav.dart';

class HomeUserScreen extends StatefulWidget {
  final VoidCallback? onNavigateToNotification;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToPayment;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToRepairDetail;
  final ValueChanged<String>? onOpenRepairChat;
  // เปลี่ยนค่าเมื่อต้องโหลดข้อมูลการ์ดแจ้งซ่อมใหม่ (เช่น กลับมาหน้า Home)
  final int reloadSeq;
  final ValueChanged<String>? onNavigateToAnnounceDetails;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToReportRepair;
  final bool isRoommate;
  final bool hasRoom;
  final String userName;
  final String userPhone;
  final String avatarUrl;
  final String roomNumber;
  final Map<String, dynamic> currentBill;
  final List<Map<String, String>> announcements;
  final List<Map<String, dynamic>> rentBreakdown;
  final bool showChatBadge;

  const HomeUserScreen({
    super.key,
    this.onNavigateToNotification,
    this.onNavigateToRentalFee,
    this.onNavigateToBill,
    this.onNavigateToPayment,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onNavigateToRepairDetail,
    this.onOpenRepairChat,
    this.reloadSeq = 0,
    this.onNavigateToAnnounceDetails,
    this.onNavigateToProfile,
    this.onNavigateToReportRepair,
    this.isRoommate = false,
    this.hasRoom = true,
    this.userName = 'พัชราวรรณ  ศรีบุญ',
    this.userPhone = '099-9999999',
    this.avatarUrl = '',
    this.roomNumber = 'A303',
    this.currentBill = const {},
    this.announcements = const [],
    this.rentBreakdown = const [],
    this.showChatBadge = false,
  });

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  int _selectedIndex = 0;

  final _db = Supabase.instance.client;
  RealtimeChannel? _repairChannel;

  // งานซ่อมล่าสุดที่จะแสดงในการ์ด (null = ยังไม่มีงานซ่อม)
  Map<String, dynamic>? _latestRepair;
  bool _repairLoading = true;
  int _activeCount = 0; // จำนวนงานที่ยังไม่เสร็จ

  @override
  void initState() {
    super.initState();
    _loadLatestRepair();
    _subscribeRepairs();
  }

  @override
  void dispose() {
    _repairChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeUserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSeq != widget.reloadSeq) {
      _loadLatestRepair();
      _subscribeRepairs();
    }
    if (_selectedIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
  }

  /// ฟังการเปลี่ยนแปลงงานซ่อมแบบ realtime (แจ้งใหม่ / แอดมินเปลี่ยนสถานะ)
  void _subscribeRepairs() {
    if (_repairChannel != null || _db.auth.currentUser == null) return;
    _repairChannel = _db
        .channel('realtime:home_user_repairs')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'repairs',
          callback: (_) => _loadLatestRepair(),
        )
        .subscribe();
  }

  /// โหลดงานซ่อมล่าสุดของห้องตัวเอง
  /// ลำดับ: งานที่ยังไม่เสร็จล่าสุดก่อน ถ้าไม่มีใช้งานล่าสุด (เสร็จสิ้น)
  Future<void> _loadLatestRepair() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _latestRepair = null;
          _repairLoading = false;
        });
      }
      return;
    }
    try {
      final me = await _db
          .from('dormitory_members')
          .select('room_id')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final roomId = me?['room_id']?.toString();

      // ผู้เช่าทุกคนในห้องเดียวกัน (ผู้เช่าหลัก + Roommate)
      var userIds = <String>[uid];
      if (roomId != null && roomId.isNotEmpty) {
        final members = await _db
            .from('dormitory_members')
            .select('user_id')
            .eq('room_id', roomId)
            .eq('status', 'approved');
        userIds =
            (members as List).map((m) => m['user_id'].toString()).toList();
        if (!userIds.contains(uid)) userIds.add(uid);
      }

      final rows = await _db
          .from('repairs')
          .select('id, room_number, category, status, created_at')
          .inFilter('user_id', userIds)
          .order('created_at', ascending: false);
      final list =
          (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();

      Map<String, dynamic>? pick;
      for (final r in list) {
        if ((r['status']?.toString() ?? 'new') != 'done') {
          pick = r;
          break;
        }
      }
      pick ??= list.isNotEmpty ? list.first : null;
      final active =
          list.where((r) => (r['status']?.toString() ?? 'new') != 'done').length;

      if (!mounted) return;
      setState(() {
        _latestRepair = pick;
        _activeCount = active;
        _repairLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ home_user load repair error: $e');
      if (mounted) setState(() => _repairLoading = false);
    }
  }

  (String, Color) _repairStatusStyle(String status) {
    switch (status) {
      case 'done':
        return ('เสร็จสิ้น', const Color(0xFF2E7D32));
      case 'in_progress':
        return ('กำลังดำเนินการ', const Color(0xFFF57B39));
      default:
        return ('งานใหม่', const Color(0xFFE05C5C));
    }
  }

  String _thaiDate(DateTime d) {
    const months = [
      'ม.ค', 'ก.พ', 'มี.ค', 'เม.ย', 'พ.ค', 'มิ.ย',
      'ก.ค', 'ส.ค', 'ก.ย', 'ต.ค', 'พ.ย', 'ธ.ค',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year + 543}';
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: widget.hasRoom
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('ค่าเช่าเดือนนี้'),
                          const SizedBox(height: 10),
                          if (!_hasRealBill || (widget.currentBill['status']?.toString() ?? '') == 'paid')
                              _buildNoBillEmptyState()
                          else
                              _buildRentCard(),
                          const SizedBox(height: 20),
                          _buildSectionLabel('แจ้งซ่อม'),
                          const SizedBox(height: 10),
                          _buildRepairCard(),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionLabel('ประกาศล่าสุด'),
                              GestureDetector(
                                onTap: () => widget.onNavigateToAnnounce?.call(),
                                child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB7D6F5).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'ดูทั้งหมด',
                                      style: TextStyle(
                                        fontFamily: 'Noto Sans Thai',
                                        fontSize: 12,
                                        color: Color(0xFF4F8FDB),
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(Icons.chevron_right, size: 14, color: Color(0xFF4F8FDB)),
                                  ],
                                ),
                                ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          _buildAnnouncementRow(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    )
                  : _buildNoRoomEmptyState(),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          ClipOval(
            child: widget.avatarUrl.isNotEmpty
                ? Image.network(
                    widget.avatarUrl,
                    width: 45,
                    height: 44,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 45,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFB7D6F5),
                        ),
                        child: const Icon(Icons.person, size: 28, color: Colors.white),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 45,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFB7D6F5),
                      ),
                      child: const Icon(Icons.person, size: 28, color: Colors.white),
                    ),
                  )
                : Container(
                    width: 45,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB7D6F5),
                    ),
                    child: const Icon(Icons.person, size: 28, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName.isNotEmpty ? widget.userName : 'พัชราวรรณ  ศรีบุญ',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 4),
                if (widget.roomNumber.isNotEmpty)
                  Text(
                    'ห้อง ${widget.roomNumber}',
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF000000),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasRealBill {
    final id = widget.currentBill['id']?.toString();
    return id != null && id.isNotEmpty;
  }

  /// รายชื่อค่าเช่ารายคนในห้อง — Roommate เห็นครบทุกคนเหมือนผู้เช่าหลัก
  /// (เดิม Roommate เห็นเฉพาะของตัวเอง)
  List<Map<String, dynamic>> get _filteredRentBreakdown => widget.rentBreakdown;

  Widget _buildNoBillEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/invoice.svg',
                  width: 52,
                  height: 52,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่มีบิลค่าเช่า',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'รอแอดมินสร้างบิลรอบใหม่',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.45),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRoomEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.meeting_room_outlined,
                  size: 48, color: Color(0xFF4F8FDB)),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่ได้เข้าร่วมหอพัก',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'คุณยังไม่ได้เข้าร่วมห้องพักใด\\nไปที่หน้าโปรไฟล์เพื่อเข้าร่วมห้องพัก',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.45),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onNavigateToProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8FDB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: const Text(
                  'ไปหน้าโปรไฟล์',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Noto Sans Thai',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildRentCard() {
    return GestureDetector(
      onTap: widget.onNavigateToBill,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCE9F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB7D6F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/icon_wallet.svg',
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentBill['month'] ?? 'กรกฎาคม 2569',
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.currentBill['total'] != null
                                ? '${widget.currentBill['total']}'
                                : '5,090',
                            style: const TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F8FDB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 5),
                            child: Text(
                              'บาท',
                              style: TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 15,
                                color: Color(0xFF8FB4E0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB7D6F5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Color(0xFF4F8FDB),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD54A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.currentBill['status_label'] ?? 'รอชำระ',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(width: 14),
                Container(width: 1, height: 18, color: const Color(0xFFB7CDEB)),
                const SizedBox(width: 14),
                const Icon(Icons.calendar_month_outlined,
                    size: 17, color: Color(0xFF4F8FDB)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'ครบกำหนด  ${widget.currentBill['due_date'] ?? '5 สิงหาคม 2569'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.rentBreakdown.isNotEmpty && widget.isRoommate) ...[
              const SizedBox(height: 16),
              _buildBreakdownHeader(),
              const SizedBox(height: 10),
              ..._filteredRentBreakdown.map(_buildBreakdownRow),
              _buildBreakdownTotal(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownHeader() {
    final count = _filteredRentBreakdown.length;
    return Row(
      children: [
        Flexible(
          child: Text(
            'ค่าเช่ารายคนในห้อง',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count คน',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(Map<String, dynamic> member) {
    final isMe = member['isMe'] == true;
    final isMainTenant = member['isMainTenant'] == true;
    final name = member['name']?.toString() ?? '-';
    final role = member['role']?.toString() ??
        (isMainTenant ? 'ผู้เช่าหลัก' : 'Roommate');
    final rent = _toDouble(member['rent']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEAF2FB) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF4F8FDB) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : const Color(0xFF4F8FDB),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name (ฉัน)' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (rent != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(rent),
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: 1),
                  child: Text(
                    'บาท',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
              ],
            )
          else
            const Text(
              '-',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTotal() {
    var total = 0.0;
    var hasValue = false;
    for (final m in _filteredRentBreakdown) {
      final rent = _toDouble(m['rent']);
      if (rent != null) {
        total += rent;
        hasValue = true;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEEF1F5)),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'รวมค่าเช่าในห้อง',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const Spacer(),
          Text(
            hasValue ? '${_formatNumber(total)} บาท' : '-',
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F8FDB),
            ),
          ),
        ],
      ),
    );
  }

  IconData _repairIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('แอร์') || c.contains('ปรับอากาศ')) return Icons.ac_unit;
    if (c.contains('น้ำ') || c.contains('ท่อ') || c.contains('ก๊อก')) {
      return Icons.water_drop_outlined;
    }
    if (c.contains('ไฟ')) return Icons.bolt;
    if (c.contains('เน็ต') || c.contains('wifi') || c.contains('ไวไฟ')) {
      return Icons.wifi;
    }
    if (c.contains('ประตู') || c.contains('กุญแจ') || c.contains('หน้าต่าง')) {
      return Icons.door_front_door_outlined;
    }
    return Icons.build_outlined;
  }

  BoxDecoration get _repairCardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _buildRepairCard() {
    final repair = _latestRepair;
    if (repair == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: _repairCardDecoration,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_outlined,
                  size: 22, color: Color(0xFF4F8FDB)),
            ),
            const SizedBox(height: 8),
            Text(
              _repairLoading ? 'กำลังโหลด...' : 'ยังไม่มีงานแจ้งซ่อม',
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Color(0xFF70766E),
              ),
            ),
          ],
        ),
      );
    }

    final status = repair['status']?.toString() ?? 'new';
    final (statusLabel, statusColor) = _repairStatusStyle(status);
    final category = repair['category']?.toString() ?? '-';
    final roomNumber = repair['room_number']?.toString() ?? '';
    final created =
        DateTime.tryParse(repair['created_at']?.toString() ?? '')?.toLocal();
    final dateText = created == null
        ? ''
        : '${_thaiDate(created)}  ${_hhmm(created)} น.';
    final step = status == 'done' ? 2 : (status == 'in_progress' ? 1 : 0);
    final otherActive = _activeCount - (status == 'done' ? 0 : 1);

    return InkWell(
      onTap: () {
        if (repair != null) {
          // ignore: avoid_print
          print('🔧 [Home] Opening repair chat for repairId: ${repair['id']}');
          widget.onOpenRepairChat?.call(repair['id']?.toString() ?? '');
        } else {
          // ไม่มีงานซ่อม → เริ่มสร้างใหม่ (เหมือนกด + แจ้งซ่อม)
          // ignore: avoid_print
          print('🔧 [Home] No repairs, starting new repair flow');
          widget.onNavigateToRepairDetail?.call();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: _repairCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ---- หัวการ์ด: ไอคอน + ประเภท/ห้อง + ป้ายสถานะ ----
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_repairIcon(category),
                    size: 22, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    if (roomNumber.isNotEmpty)
                      Text(
                        'ห้อง $roomNumber',
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 13,
                          color: Color(0xFF70766E),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ---- ตัวแสดงขั้นตอน: แจ้งแล้ว → กำลังดำเนินการ → เสร็จสิ้น ----
          _buildRepairSteps(step, statusColor),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          const SizedBox(height: 10),

          // ---- ท้ายการ์ด: วันที่แจ้ง + งานค้างอื่น + ปุ่มรายละเอียด ----
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 14, color: Color(0xFF70766E)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF70766E),
                  ),
                ),
              ),
              if (otherActive > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'อีก $otherActive งานค้าง',
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 11,
                      color: Color(0xFFF57B39),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    ),
  );
  }

  /// เส้นขั้นตอนงานซ่อม 3 ขั้น (step 0..2) ขั้นที่ผ่านแล้วเติมสี
  Widget _buildRepairSteps(int step, Color activeColor) {
    const labels = ['แจ้งแล้ว', 'กำลังดำเนินการ', 'เสร็จสิ้น'];
    const grey = Color(0xFFD9D9D9);

    Widget dot(int i) {
      final reached = i <= step;
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached ? activeColor : Colors.white,
          border: Border.all(color: reached ? activeColor : grey, width: 2),
        ),
        child: reached
            ? const Icon(Icons.check, size: 10, color: Colors.white)
            : null,
      );
    }

    Widget line(int i) => Expanded(
          child: Container(
            height: 2,
            color: i < step ? activeColor : grey,
          ),
        );

    return Column(
      children: [
        Row(children: [dot(0), line(0), dot(1), line(1), dot(2)]),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            return Text(
              labels[i],
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 10,
                fontWeight: i == step ? FontWeight.w600 : FontWeight.w400,
                color: i <= step
                    ? const Color(0xFF000000)
                    : const Color(0xFF9AA0A6),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAnnouncementRow() {
    final list = List<Map<String, String>>.from(widget.announcements);
    list.sort((a, b) {
      final da = a['createdAt'] ?? a['date'] ?? '';
      final db = b['createdAt'] ?? b['date'] ?? '';
      return db.compareTo(da);
    });
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E6ED)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SvgPicture.asset(
                'assets/images/megaphone-flat.svg',
                width: 40,
                height: 40,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'ไม่มีประกาศจากหอพัก',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      );
    }
    final item = list.first;
    return _buildAnnouncementCard(item);
  }

  Widget _buildAnnouncementCard(Map<String, String> item) {
    final title = item['title'] ?? '';
    final date = item['date'] ?? '';

    return GestureDetector(
      onTap: () => widget.onNavigateToAnnounceDetails?.call(title),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCE9A8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Text(
                        title.isNotEmpty ? title : 'ประกาศ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 4,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 15, color: Color(0xFF888888)),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.4,
                            ),
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 13,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/proclaim.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.campaign,
                      size: 60, color: Color(0xFFE6A700)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'อ่านเพิ่มเติม',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 14,
                        color: Color(0xFF4F8FDB),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 16, color: Color(0xFF4F8FDB)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return UserBottomNav(
      selectedIndex: _selectedIndex,
      onSelected: (i) => setState(() => _selectedIndex = i),
      onBill: widget.onNavigateToRentalFee,
      onChat: widget.onNavigateToReportRepair ?? widget.onNavigateToChat,
      onAnnounce: widget.onNavigateToAnnounce,
      onProfile: widget.onNavigateToProfile,
      showChatBadge: widget.showChatBadge,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatNumber(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buffer.write(',');
      buffer.write(rounded[i]);
    }
    return buffer.toString();
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '-';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
