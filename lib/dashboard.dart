import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  final String adminName;
  final String avatarUrl;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToNotification;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToReportRepair;
  final VoidCallback? onNavigateToProfile;
  final bool showRepairBadge;
  // mock data
  final Map<String, int> stats;
  final List<Map<String, String>> repairRequests;

  const DashboardScreen({
    super.key,
    this.adminName = 'พัชราวรรณ  ศรีบุญ',
    this.avatarUrl = '',
    this.onNavigateToTenant,
    this.onNavigateToBill,
    this.onNavigateToNotification,
    this.onNavigateToAnnounce,
    this.onNavigateToReportRepair,
    this.onNavigateToProfile,
    this.showRepairBadge = false,
    this.stats = const {
      'total_tenants': 58,
      'total_rooms': 60,
      'vacant_rooms': 2,
      'repair_requests': 3,
    },
    this.repairRequests = const [],
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int? _totalRooms;
  int? _vacantRooms;
  int? _totalTenants;
  String? _adminAvatarUrl;
  RealtimeChannel? _adminAvatarChannel;
  RealtimeChannel? _requestChannel;

  int _billPending = 0;
  int _billReview = 0;
  int _billPaid = 0;

  // มีคำขอเข้าหอพัก (pending) ค้างอยู่ไหม → จุดแดงที่ bell
  bool _hasPendingRequest = false;

  // รายการงานแจ้งซ่อมที่ยังไม่เสร็จ (ดึงจริงจาก Supabase)
  List<Map<String, dynamic>> _activeRepairs = [];
  int _repairCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  /// โหลดข้อมูลทุก card ใหม่ (เรียกจาก main.dart ทุกครั้งที่เข้าหน้า dashboard
  /// และหลังล็อกอิน เพราะหน้านี้อยู่ใน IndexedStack จึงสร้างครั้งเดียวตอนเปิดแอป
  /// ซึ่งตอนนั้นยังไม่ได้ล็อกอิน → โหลดข้อมูลไม่ได้)
  Future<void> reload() async {
    await Future.wait([
      _loadRoomStats(),
      _loadTenantCount(),
      _loadBillStats(),
      _loadActiveRepairs(),
      _loadAdminAvatar(),
      _loadPendingRequest(),
    ]);
    if (!mounted) return;
    // subscribe เฉพาะเมื่อล็อกอินแล้วและยังไม่เคย subscribe
    if (_adminAvatarChannel == null) _subscribeAdminAvatarChanges();
    if (_requestChannel == null) _subscribeRequestChanges();
  }

  /// โหลดงานแจ้งซ่อมที่ยังไม่เสร็จ (active) ของหอพักแอดมิน
  Future<void> _loadActiveRepairs() async {
    try {
      final db = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid == null) return;

      final dormRows = await db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);
      final dormIds =
          (dormRows as List).map((d) => d['id'].toString()).toList();
      if (dormIds.isEmpty) return;

      final members = await db
          .from('dormitory_members')
          .select('user_id')
          .inFilter('dormitory_id', dormIds);
      final userIds = (members as List)
          .map((m) => m['user_id'].toString())
          .toSet()
          .toList();
      if (userIds.isEmpty) return;

      final rows = await db
          .from('repairs')
          .select('id, user_id, room_id, room_number, reporter_name, category, status, created_at')
          .inFilter('user_id', userIds)
          .neq('status', 'done')
          .order('created_at', ascending: false)
          .limit(3);

      final repairList =
          (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();

      // โหลด avatar_url ของผู้แจ้ง (จาก tenants/roommate_invites)
      final avatarMap = <String, String>{};
      final repairUserIds = repairList
          .map((r) => r['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (repairUserIds.isNotEmpty) {
        for (final table in ['tenants', 'roommate_invites']) {
          try {
            final res = await db
                .from(table)
                .select('id, avatar_url')
                .inFilter('id', repairUserIds);
            for (final row in (res as List)) {
              final id = row['id']?.toString() ?? '';
              final url = row['avatar_url']?.toString() ?? '';
              if (id.isNotEmpty && url.isNotEmpty) {
                avatarMap.putIfAbsent(id, () => url);
              }
            }
          } catch (_) {}
        }
      }
      for (final r in repairList) {
        r['avatar_url'] = avatarMap[r['user_id']?.toString() ?? ''] ?? '';
      }

      if (!mounted) return;
      setState(() {
        _activeRepairs = repairList;
        _repairCount = _activeRepairs.length;
      });
    } catch (e) {
      print('❌ _loadActiveRepairs error: $e');
    }
  }

  /// เช็คว่ามีคำขอเข้าหอพัก (pending) ค้างอยู่ไหม
  Future<void> _loadPendingRequest() async {
    try {
      final db = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid == null) return;

      final dormRows = await db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);
      final dormIds =
          (dormRows as List).map((d) => d['id'].toString()).toList();
      if (dormIds.isEmpty) return;

      final pending = await db
          .from('dormitory_members')
          .select('id')
          .eq('status', 'pending')
          .inFilter('dormitory_id', dormIds)
          .limit(1);

      if (!mounted) return;
      setState(() => _hasPendingRequest = (pending as List).isNotEmpty);
    } catch (e) {
      print('❌ _loadPendingRequest error: $e');
    }
  }

  /// ฟังคำขอใหม่ + งานซ่อมใหม่แบบ realtime → อัปเดต dashboard ทันที
  void _subscribeRequestChanges() {
    final client = Supabase.instance.client;
    _requestChannel = client.channel('realtime:dashboard_requests');
    _requestChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dormitory_members',
          callback: (payload) => _loadPendingRequest(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'repairs',
          callback: (payload) => _loadActiveRepairs(),
        )
        .subscribe();
  }

  Future<void> _loadRoomStats() async {
    try {
      final db = Supabase.instance.client;
      String? uid = db.auth.currentUser?.id;

      if (uid == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        uid = db.auth.currentUser?.id;
      }
      if (uid == null) return;

      // ดึง dormitory id ทั้งหมดของแอดมินคนนี้
      final dormRows = await db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);

      final dormIds =
          (dormRows as List).map((d) => d['id'].toString()).toList();
      if (dormIds.isEmpty) return;

      // ห้องทั้งหมดของหอพักนี้ (จากตาราง rooms)
      final roomsRes = await db
          .from('rooms')
          .select('id')
          .inFilter('dormitory_id', dormIds);
      final allRoomIds = (roomsRes as List)
          .map((r) => r['id'].toString())
          .toSet();

      // ห้องที่มีผู้เช่าสถานะ approved อยู่แล้ว
      final membersRes = await db
          .from('dormitory_members')
          .select('room_id')
          .eq('status', 'approved')
          .inFilter('dormitory_id', dormIds);
      final occupiedRoomIds = (membersRes as List)
          .map((r) => r['room_id']?.toString())
          .whereType<String>()
          .toSet();

      if (!mounted) return;
      setState(() {
        _totalRooms = allRoomIds.length;
        _vacantRooms =
            allRoomIds.where((id) => !occupiedRoomIds.contains(id)).length;
      });
    } catch (e) {
      print('❌ _loadRoomStats error: $e');
    }
  }

  /// นับจำนวนบิลตามสถานะของหอพักที่แอดมินสร้าง
  Future<void> _loadBillStats() async {
    try {
      final db = Supabase.instance.client;
      String? uid = db.auth.currentUser?.id;

      if (uid == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        uid = db.auth.currentUser?.id;
      }
      if (uid == null) return;

      final dormRows = await db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);
      final dormIds =
          (dormRows as List).map((d) => d['id'].toString()).toList();
      if (dormIds.isEmpty) {
        if (mounted) {
          setState(() {
            _billPending = 0;
            _billReview = 0;
            _billPaid = 0;
          });
        }
        return;
      }

      final billsRes = await db
          .from('bills')
          .select('status')
          .inFilter('dormitory_id', dormIds);

      int pending = 0;
      int review = 0;
      int paid = 0;

      for (final bill in billsRes as List) {
        final status = bill['status']?.toString() ?? '';
        if (status == 'pending') {
          pending++;
        } else if (status == 'review') {
          review++;
        } else if (status == 'paid') {
          paid++;
        }
      }

      if (!mounted) return;
      setState(() {
        _billPending = pending;
        _billReview = review;
        _billPaid = paid;
      });
    } catch (e) {
      print('❌ _loadBillStats error: $e');
      if (mounted) {
        setState(() {
          _billPending = 0;
          _billReview = 0;
          _billPaid = 0;
        });
      }
    }
  }

  /// ดึง avatar_url ของแอดมินจากตาราง admins / tenants / roommate_invites / profiles
  Future<void> _loadAdminAvatar() async {
    try {
      final db = Supabase.instance.client;
      String? uid = db.auth.currentUser?.id;
      if (uid == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        uid = db.auth.currentUser?.id;
      }
      if (uid == null) return;

       String? avatar;
       final row = await db
           .from('admins')
           .select('avatar_url')
           .eq('id', uid)
           .maybeSingle();
       if (row != null &&
           (row['avatar_url'] as String?)?.isNotEmpty == true) {
         avatar = row['avatar_url'] as String;
       }

      if (!mounted) return;
      setState(() => _adminAvatarUrl = avatar);
    } catch (e) {
      print('❌ _loadAdminAvatar error: $e');
    }
  }

  /// นับจำนวนผู้เช่าหลัก (status=approved) ของหอพักที่แอดมินสร้าง
  Future<void> _loadTenantCount() async {
    try {
      final db = Supabase.instance.client;
      String? uid = db.auth.currentUser?.id;
      if (uid == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        uid = db.auth.currentUser?.id;
      }
      if (uid == null) return;

      final dormRows = await db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);
      final dormIds =
          (dormRows as List).map((d) => d['id'].toString()).toList();
      if (dormIds.isEmpty) {
        if (mounted) setState(() => _totalTenants = 0);
        return;
      }

      final res = await db
          .from('dormitory_members')
          .select('id')
          .eq('status', 'approved')
          .inFilter('dormitory_id', dormIds);
      final count = (res as List).length;

      if (!mounted) return;
      setState(() => _totalTenants = count);
    } catch (e) {
      print('❌ _loadTenantCount error: $e');
      if (mounted) setState(() => _totalTenants = 0);
    }
  }

  /// ฟังการเปลี่ยนแปลง avatar ของแอดมินแบบ real-time
  void _subscribeAdminAvatarChanges() {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    _adminAvatarChannel = client.channel('realtime:admin_avatar');
    final channel = _adminAvatarChannel!;
    channel
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'admins',
      callback: (payload) async {
        final changedId = payload.newRecord['id']?.toString() ?? '';
        final newAvatar = payload.newRecord['avatar_url']?.toString() ?? '';
        if (changedId == uid && newAvatar.isNotEmpty && mounted) {
          setState(() => _adminAvatarUrl = newAvatar);
        }
      },
    );
    channel.subscribe();
  }

  @override
  void dispose() {
    _adminAvatarChannel?.unsubscribe();
    _requestChannel?.unsubscribe();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStatGrid(),
                const SizedBox(height: 16),
                _buildActiveRepairsCard(),
                const SizedBox(height: 16),
                _buildPaymentSection(),
              ],
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: _buildBottomNav()),
        ],
      ),
    );
  }

  // ---- Header ----
  Widget _buildHeader() {
    // widget.avatarUrl (จาก main.dart) มาก่อนเสมอ
    // ถ้าว่างค่อย fallback ไปที่ _adminAvatarUrl ที่โหลดจาก Supabase ใน initState
    final effectiveAvatar = widget.avatarUrl.isNotEmpty
        ? widget.avatarUrl
        : _adminAvatarUrl;
    return GestureDetector(
      onTap: widget.onNavigateToProfile,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: ClipOval(
              child: effectiveAvatar != null && effectiveAvatar.isNotEmpty
                  ? Image.network(
                      effectiveAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/user_avatar.png',
                        fit: BoxFit.cover,
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.person,
                                size: 28, color: Colors.white),
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/user_avatar.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.adminName,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onNavigateToNotification,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FB),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/icon_bell.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4181CB),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // จุดแดงเมื่อมีคำขอค้างอยู่
                if (_hasPendingRequest)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Stat grid (2x2) ----
  Widget _buildStatGrid() {
    final s = widget.stats;
    // ห้องทั้งหมดและห้องว่าง: ดึงจาก Supabase โดยตรงใน initState
    final totalRoomsDisplay  = '${_totalRooms  ?? 0}';
    final vacantRoomsDisplay = '${_vacantRooms ?? 0}';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                bg: const Color(0xFFEAF2FB),
                icon: Icons.people,
                iconColor: const Color(0xFF4181CB),
                number: '${_totalTenants ?? 0}',
                label: 'ผู้เช่าทั้งหมด',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                bg: const Color(0xFFFFF8E5),
                icon: Icons.home,
                iconColor: const Color(0xFFE6A700),
                number: totalRoomsDisplay,
                label: 'ห้องทั้งหมด',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                bg: const Color(0xFFE9F7EC),
                icon: Icons.meeting_room,
                iconColor: const Color(0xFF4CAF50),
                number: vacantRoomsDisplay,
                label: 'ห้องว่าง',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                bg: const Color(0xFFFCE9E9),
                icon: Icons.build,
                iconColor: const Color(0xFFE05C5C),
                number: '$_repairCount',
                label: 'แจ้งซ่อม',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String number,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: iconColor),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000000),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairCard() {
    final repairs = widget.repairRequests.isNotEmpty
        ? widget.repairRequests.take(3).toList()
        : [
            {
              'room': 'A301',
              'tenant': widget.adminName,
              'time': '8 ก.ย. 09:45',
              'status': 'กำลังดำเนินการ',
            },
            {
              'room': 'A303',
              'tenant': widget.adminName,
              'time': '8 ก.ย. 10:12',
              'status': 'กำลังดำเนินการ',
            },
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.build_outlined,
                size: 20,
                color: Color(0xFFE05C5C),
              ),
              const SizedBox(width: 6),
              const Text(
                'แจ้งซ่อม',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          ...repairs.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRepairRow(
                r['room'] ?? '',
                r['time'] ?? '',
                r['tenant'] ?? '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairRow(String room, String time, [String? tenantName]) {
    final name = tenantName ?? widget.adminName;
    final effectiveAvatar = widget.avatarUrl.isNotEmpty
        ? widget.avatarUrl
        : _adminAvatarUrl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: ClipOval(
              child: effectiveAvatar != null && effectiveAvatar.isNotEmpty
                  ? Image.network(
                      effectiveAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/user_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/user_avatar.png',
                      fit: BoxFit.cover,
                    ),
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
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                    children: [
                      TextSpan(text: 'ห้อง $room  •  '),
                      const TextSpan(
                        text: 'กำลังดำเนินการ',
                        style: TextStyle(color: Color(0xFFE6A700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 11,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // ---- การ์ดงานแจ้งซ่อมที่ค้างอยู่ ----
  Widget _buildActiveRepairsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_outlined,
                  size: 20, color: Color(0xFFE05C5C)),
              const SizedBox(width: 6),
              const Text(
                'งานแจ้งซ่อม',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onNavigateToReportRepair,
                child: const Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF4181CB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activeRepairs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'ไม่มีงานแจ้งซ่อมที่ค้างอยู่',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
            )
          else
            ..._activeRepairs.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActiveRepairRow(r),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveRepairRow(Map<String, dynamic> r) {
    final status = r['status']?.toString() ?? 'new';
    final (statusLabel, statusColor) = _repairStatusStyle(status);
    return GestureDetector(
      onTap: widget.onNavigateToReportRepair,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: (r['avatar_url']?.toString().isNotEmpty == true)
                    ? Image.network(
                        r['avatar_url'].toString(),
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
                    r['reporter_name']?.toString() ?? 'ผู้เช่า',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000000),
                    ),
                  ),
                  Text(
                    'ห้อง ${r['room_number'] ?? '-'}  •  ${r['category'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
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
          ],
        ),
      ),
    );
  }

  (String, Color) _repairStatusStyle(String status) {
    switch (status) {
      case 'in_progress':
        return ('กำลังดำเนินการ', const Color(0xFFE6A700));
      case 'done':
        return ('เสร็จสิ้น', const Color(0xFF4CAF50));
      case 'new':
      default:
        return ('งานใหม่', const Color(0xFFE05C5C));
    }
  }

  // ---- การชำระเงิน ----
  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การชำระเงิน',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildPaymentChip(
                bg: const Color(0xFFFCE9E9),
                titleColor: const Color(0xFFE05C5C),
                title: 'รอชำระ',
                number: '$_billPending',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentChip(
                bg: const Color(0xFFFFF8E5),
                titleColor: const Color(0xFFE6A700),
                title: 'รอตรวจสอบ',
                number: '$_billReview',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentChip(
                bg: const Color(0xFFE9F7EC),
                titleColor: const Color(0xFF4CAF50),
                title: 'ชำระแล้ว',
                number: '$_billPaid',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentChip({
    required Color bg,
    required Color titleColor,
    required String title,
    required String number,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 11,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            number,
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }

   // ---- Bottom Navigation (6 icons) ----
  Widget _buildBottomNav() {
    const navWidth = 320.0;
    const circleSize = 40.0;
    const itemCount = 6;
    const activeIndex = 0; // dashboard = index 0 เสมอ
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
    final materialIcons = <int, IconData>{3: Icons.build_outlined};

    const activeIndex = 0; // dashboard = index 0 เสมอ
    return List.generate(6, (i) {
      final isActive = i == activeIndex;
      final iconColor = isActive ? const Color(0xFF4F8FDB) : Colors.white;

      Widget iconWidget = svgPaths.containsKey(i)
          ? SvgPicture.asset(
              svgPaths[i]!,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          : Icon(materialIcons[i], size: 22, color: iconColor);

      // badge จุดแดงที่ไอคอนแจ้งซ่อม (index 3)
      if (i == 3 && widget.showRepairBadge) {
        iconWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF4F8FDB), width: 1.5),
                ),
              ),
            ),
          ],
        );
      }

      return GestureDetector(
        onTap: () {
          print('DASHBOARD BOTTOM NAV TAP: index=$i');
          if (i == 1 && widget.onNavigateToTenant != null) {
            widget.onNavigateToTenant!();
          } else if (i == 2) {
            print('DASHBOARD BOTTOM NAV TAP: going to bill via callback');
            if (widget.onNavigateToBill != null) {
              widget.onNavigateToBill!();
            } else {
              print('DASHBOARD BOTTOM NAV TAP: onNavigateToBill is NULL');
            }
          } else if (i == 3 && widget.onNavigateToReportRepair != null) {
            widget.onNavigateToReportRepair!();
          } else if (i == 4 && widget.onNavigateToAnnounce != null) {
            widget.onNavigateToAnnounce!();
          } else if (i == 5 && widget.onNavigateToProfile != null) {
            widget.onNavigateToProfile!();
          }
        },
        child: SizedBox(
          width: slot,
          height: 52,
          child: Center(child: iconWidget),
        ),
      );
    });
  }
}
