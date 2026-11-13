import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/app_sizes.dart';
/// หน้า "แจ้งซ่อม" ฝั่งแอดมิน — รายการงานซ่อมทุกห้องในหอที่ดูแล
/// กดการ์ด → เปิดห้องแชทของงานนั้น (chat_admin)
class ReportARepairScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToAnnounce;

  /// เปิดห้องแชทของงานซ่อม: ส่ง repairId + ข้อมูลหัวการ์ด
  final void Function(String repairId, Map<String, dynamic> info)?
      onOpenChat;

  const ReportARepairScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTenant,
    this.onNavigateToProfile,
    this.onNavigateToBill,
    this.onNavigateToAnnounce,
    this.onOpenChat,
  });

  @override
  State<ReportARepairScreen> createState() => ReportARepairScreenState();
}

// public state เพื่อให้ main.dart เรียก reload() ผ่าน GlobalKey ได้
class ReportARepairScreenState extends State<ReportARepairScreen> {
  final _searchController = TextEditingController();
  final _db = Supabase.instance.client;

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _repairs = [];

  @override
  void initState() {
    super.initState();
    _loadRepairs();
  }

  /// เรียกจาก main.dart ทุกครั้งที่กลับมาหน้านี้ (เช่น หลังเปลี่ยนสถานะในแชท)
  void reload() {
    if (!mounted) return;
    setState(() => _loading = true);
    _loadRepairs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// โหลดงานซ่อมของทุกห้องในหอที่แอดมินดูแล
  Future<void> _loadRepairs() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      // หอที่แอดมินสร้าง
      final dorms = await _db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);
      final dormIds = (dorms as List).map((d) => d['id'].toString()).toList();
      if (dormIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'ไม่พบหอพักที่คุณดูแล';
        });
        return;
      }

      // user ทั้งหมดในหอเหล่านี้ (จาก dormitory_members)
      final members = await _db
          .from('dormitory_members')
          .select('user_id')
          .inFilter('dormitory_id', dormIds);
      final userIds =
          (members as List).map((m) => m['user_id'].toString()).toSet().toList();
      if (userIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _repairs = [];
        });
        return;
      }

      final rows = await _db
          .from('repairs')
          .select('id, user_id, room_id, room_number, reporter_name, category, description, status, created_at')
          .inFilter('user_id', userIds)
          .order('created_at', ascending: false);

      final allRepairs =
          (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();

      // group ตามห้อง → เก็บแค่งานล่าสุดต่อห้อง (1 card = 1 ห้อง)
      // rows เรียง created_at ใหม่→เก่าแล้ว ดังนั้นตัวแรกของแต่ละห้อง = ล่าสุด
      final seenRooms = <String>{};
      final repairList = <Map<String, dynamic>>[];
      for (final r in allRepairs) {
        // key ของห้อง: ใช้ room_id ถ้ามี ไม่งั้น user_id (กันกรณี room_id null)
        final roomKey = (r['room_id']?.toString().isNotEmpty == true)
            ? 'room_${r['room_id']}'
            : 'user_${r['user_id']}';
        if (seenRooms.add(roomKey)) {
          repairList.add(r);
        }
      }

      // โหลด avatar_url ของผู้แจ้งทั้งหมด (จาก tenants/roommate_invites)
      final avatarMap = <String, String>{};
      for (final table in ['tenants', 'roommate_invites']) {
        try {
          final res = await _db
              .from(table)
              .select('id, avatar_url')
              .inFilter('id', userIds);
          for (final row in (res as List)) {
            final id = row['id']?.toString() ?? '';
            final url = row['avatar_url']?.toString() ?? '';
            if (id.isNotEmpty && url.isNotEmpty) {
              avatarMap.putIfAbsent(id, () => url);
            }
          }
        } catch (_) {}
      }
      // map avatar เข้าแต่ละ repair
      for (final r in repairList) {
        final uid = r['user_id']?.toString() ?? '';
        r['avatar_url'] = avatarMap[uid] ?? '';
      }

      if (!mounted) return;
      setState(() {
        _repairs = repairList;
        _loading = false;
        _error = '';
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ load repairs (admin) error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'โหลดรายการแจ้งซ่อมไม่สำเร็จ';
      });
    }
  }

  // ตัวกรองสถานะ: all / new / in_progress / done
  String _filter = 'all';

  String _statusOf(Map<String, dynamic> r) {
    final s = r['status']?.toString() ?? 'new';
    return (s == 'done' || s == 'in_progress') ? s : 'new';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    final byStatus = _filter == 'all'
        ? _repairs
        : _repairs.where((r) => _statusOf(r) == _filter).toList();
    if (q.isEmpty) return byStatus;
    return byStatus.where((r) {
      final name = (r['reporter_name']?.toString() ?? '').toLowerCase();
      final room = (r['room_number']?.toString() ?? '').toLowerCase();
      return name.contains(q) || room.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 10),
              if (!_loading && _error.isEmpty && _repairs.isNotEmpty)
                _buildStatusSummary(),
              if (!_loading && _error.isEmpty && _repairs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilters(),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF4F8FDB)))
                    : _error.isNotEmpty
                        ? Center(
                            child: Text(_error,
                                style: const TextStyle(
                                    fontFamily: 'Noto Sans Thai',
                                    fontSize: 13,
                                    color: Color(0xFF888888))))
                        : _filtered.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                onRefresh: _loadRepairs,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 100),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, i) =>
                                      _buildRepairCard(_filtered[i]),
                                ),
                              ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  /// ปุ่มกรองสถานะ (ทั้งหมด / งานใหม่ / กำลังดำเนินการ / เสร็จสิ้น)
  Widget _buildFilters() {
    const filters = <(String, String)>[
      ('all', 'ทั้งหมด'),
      ('new', 'งานใหม่'),
      ('in_progress', 'กำลังดำเนินการ'),
      ('done', 'เสร็จสิ้น'),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final value = filters[index].$1;
          final label = filters[index].$2;
          final selected = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF4F8FDB) : Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4F8FDB)
                      : const Color(0xFFDDE5EE),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : const Color(0xFF667085),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// การ์ดสรุปจำนวนงานตามสถานะ (งานใหม่ / กำลังดำเนินการ / เสร็จสิ้น)
  Widget _buildStatusSummary() {
    int newCount = 0, inProgress = 0, done = 0;
    for (final r in _repairs) {
      switch (r['status']?.toString() ?? 'new') {
        case 'done':
          done++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        default:
          newCount++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _summaryChip(
              label: 'งานใหม่',
              count: newCount,
              color: const Color(0xFFE05C5C),
              bg: const Color(0xFFFCE9E9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryChip(
              label: 'กำลังดำเนินการ',
              count: inProgress,
              color: const Color(0xFFE6A700),
              bg: const Color(0xFFFFF8E5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryChip(
              label: 'เสร็จสิ้น',
              count: done,
              color: const Color(0xFF2E7D32),
              bg: const Color(0xFFE9F7EC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFBBBBBB)),
        SizedBox(height: 12),
        Center(
          child: Text('ยังไม่มีงานแจ้งซ่อม',
              style: TextStyle(
                  fontFamily: 'Noto Sans Thai', fontSize: 14, color: Color(0xFF999999))),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 60, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'แจ้งซ่อม',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: kPageTitleFontSize,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4181CB),
            ),
          ),
          SizedBox(height: 2),
          Text(
            'จัดการคำขอแจ้งซ่อมทั้งหมด',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            color: Color(0xFF000000),
          ),
          decoration: const InputDecoration(
            hintText: 'ค้นหาชื่อหรือเลขห้อง',
            hintStyle: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              color: Color(0xFFAAAAAA),
            ),
            prefixIcon: Icon(Icons.search, color: Color(0xFFAAAAAA), size: 20),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildRepairCard(Map<String, dynamic> repair) {
    final status = repair['status']?.toString() ?? 'new';
    final (statusLabel, statusBg, statusColor) = _statusStyle(status);
    final jobId = _shortJobId(repair['id']?.toString() ?? '');
    final time = _formatTime(repair['created_at']?.toString());
    final room = repair['room_number']?.toString() ?? '-';
    final name = repair['reporter_name']?.toString() ?? 'ผู้เช่า';

    return GestureDetector(
      onTap: () => widget.onOpenChat?.call(
        repair['id'].toString(),
        {
          'tenantName': name,
          'roomNumber': room,
          'jobId': jobId,
          'status': status,
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: (repair['avatar_url']?.toString().isNotEmpty == true)
                    ? Image.network(
                        repair['avatar_url'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/user_avatar.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset('assets/images/user_avatar.png',
                        fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ห้อง $room  •  ${repair['category'] ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jobId,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 11,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, Color) _statusStyle(String status) {
    switch (status) {
      case 'done':
        return ('เสร็จสิ้น', const Color(0xFFE9F7EC), const Color(0xFF2E7D32));
      case 'in_progress':
        return ('กำลังดำเนินการ', const Color(0xFFFFF8E5), const Color(0xFFE6A700));
      case 'new':
      default:
        return ('งานใหม่', const Color(0xFFFCE9E9), const Color(0xFFF16C6C));
    }
  }

  String _shortJobId(String id) =>
      id.isEmpty ? '' : 'RM-${id.substring(0, id.length < 8 ? id.length : 8).toUpperCase()}';

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return '';
    }
  }

  Widget _buildBottomNav() {
    const navWidth = 320.0;
    const itemCount = 6;
    const circleSize = 40.0;
    const activeIndex = 3; // report repair = index 3 เสมอ
    final slot = navWidth / itemCount;
    final indicatorLeft = slot * activeIndex + (slot - circleSize) / 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: navWidth,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF4F8FDB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: indicatorLeft,
            top: 6,
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: const BoxDecoration(
                color: Color(0xFFFEFFAF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: _buildBottomNavItems(slot),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBottomNavItems(double slot) {
    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/persons.svg',
      2: 'assets/images/icon_bill.svg',
      4: 'assets/images/icon_announcement.svg',
      5: 'assets/images/icon_user.svg',
    };
    final materialIcons = <int, IconData>{
      3: Icons.build_outlined,
    };

    const activeIndex = 3;
    return List.generate(6, (i) {
      final isActive = i == activeIndex;
      final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
      return GestureDetector(
        onTap: () {
          if (i == 0 && widget.onNavigateToDashboard != null) {
            widget.onNavigateToDashboard!();
          } else if (i == 1 && widget.onNavigateToTenant != null) {
            widget.onNavigateToTenant!();
          } else if (i == 2 && widget.onNavigateToBill != null) {
            widget.onNavigateToBill!();
          } else if (i == 4 && widget.onNavigateToAnnounce != null) {
            widget.onNavigateToAnnounce!();
          } else if (i == 5 && widget.onNavigateToProfile != null) {
            widget.onNavigateToProfile!();
          }
        },
        child: SizedBox(
          width: slot,
          height: 52,
          child: Center(
            child: svgPaths.containsKey(i)
                ? SvgPicture.asset(
                    svgPaths[i]!,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(materialIcons[i], size: 22, color: color),
          ),
        ),
      );
    });
  }
}
