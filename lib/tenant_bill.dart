import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/app_sizes.dart';
class TenantBillScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToReportRepair;
  final VoidCallback? onNavigateToAnnouncement;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onCreateBill;
  final void Function(Map<String, dynamic> bill)? onTapBill;
  final void Function(String billId)? onApproveBill;
  final List<Map<String, String>> tenants;
  final Map<String, dynamic> currentBill;

  /// บิลจริงจาก Supabase (ถ้ามี) — ถ้าว่างจะใช้ข้อมูลจำลองเดิม
  final List<Map<String, dynamic>> bills;

  /// สรุปจำนวนบิลตามสถานะ {pending, review, paid}
  final Map<String, int> billStats;
  final bool showRepairBadge;

  const TenantBillScreen({
    super.key,
    this.onBack,
    this.onNavigateToDashboard,
    this.onNavigateToTenant,
    this.onNavigateToReportRepair,
    this.onNavigateToAnnouncement,
    this.onNavigateToProfile,
    this.onCreateBill,
    this.onTapBill,
    this.onApproveBill,
    this.tenants = const [],
    this.currentBill = const {},
    this.bills = const [],
    this.billStats = const {},
    this.showRepairBadge = false,
  });

  @override
  State<TenantBillScreen> createState() => TenantBillScreenState();
}

// public state class เพื่อให้ main.dart เรียก reload() ผ่าน GlobalKey ได้
class TenantBillScreenState extends State<TenantBillScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';
  final Map<String, String> _avatarCache = {};
  RealtimeChannel? _tenantChannel;

  // บิลที่โหลดจาก Supabase โดยตรง (กรองแค่หอพักของแอดมินเอง)
  List<Map<String, dynamic>> _loadedBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadBills().then((_) => _subscribeTenantChanges()),
    );
  }

  /// เรียกจาก main.dart ผ่าน GlobalKey ทุกครั้งที่ navigate มาหน้านี้
  void reload() {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _loadBills();
  }

  /// โหลดบิลจาก Supabase — กรองเฉพาะหอพักที่แอดมินเป็นคนสร้าง
  Future<void> _loadBills() async {
    final db = Supabase.instance.client;
    String? uid = db.auth.currentUser?.id;
    if (uid == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      uid = db.auth.currentUser?.id;
    }
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // หา dormitory_id ของแอดมินคนนี้
      final dormRows = await db
          .from('dormitories')
          .select('id')
          .eq('created_by', uid);
      final dormIds =
          (dormRows as List).map((d) => d['id'].toString()).toList();

      if (dormIds.isEmpty) {
        if (mounted) setState(() { _loadedBills = []; _isLoading = false; });
        return;
      }

      // ดึงบิลทุกตัวในหอพักนี้
      final rows = await db
          .from('bills')
          .select(
              'id, tenant_id, tenant_name, room, month, rent, electricity, water, penalty, total, due_date, status, qr_image_url, payment_proof_url, created_at, dormitory_id')
          .inFilter('dormitory_id', dormIds)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _loadedBills = List<Map<String, dynamic>>.from(rows as List);
        _isLoading = false;
      });

      // โหลด avatar ของผู้เช่าที่พบในบิล
      await _loadAvatarsForBills(_loadedBills);
    } catch (e) {
      debugPrint('_loadBills error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tenantChannel?.unsubscribe();
    super.dispose();
  }

  /// โหลด avatar ของผู้เช่าจากบิลที่โหลดมาแล้ว
  Future<void> _loadAvatarsForBills(List<Map<String, dynamic>> bills) async {
    final memberIds = <String>{};
    for (final bill in bills) {
      final id = bill['tenant_id']?.toString() ?? '';
      if (id.isNotEmpty) memberIds.add(id);
    }
    for (final memberId in memberIds) {
      if (_avatarCache.containsKey(memberId)) continue;
      final avatar = await _fetchAvatarUrl(memberId);
      if (mounted && avatar != null && avatar.isNotEmpty) {
        setState(() => _avatarCache[memberId] = avatar);
      }
    }
  }

  /// (legacy) โหลด avatar จาก widget.bills/tenants — ยังคงไว้เผื่อใช้
  Future<void> _loadAvatars() async {
    final memberIds = <String>{};
    for (final bill in widget.bills) {
      final id = bill['tenant_id']?.toString()
          ?? bill['member_id']?.toString()
          ?? bill['user_id']?.toString()
          ?? '';
      if (id.isNotEmpty) memberIds.add(id);
    }
    for (final t in widget.tenants) {
      final id = t['member_id']?.toString() ?? t['id']?.toString() ?? '';
      if (id.isNotEmpty) memberIds.add(id);
    }
    for (final memberId in memberIds) {
      final avatar = await _fetchAvatarUrl(memberId);
      if (mounted && avatar != null && avatar.isNotEmpty) {
        _avatarCache[memberId] = avatar;
      }
    }
    if (mounted) setState(() {});
  }

  Future<String?> _fetchAvatarUrl(String memberId) async {
    final db = Supabase.instance.client;
    for (final table in ['tenants', 'roommate_invites', 'profiles']) {
      final row = await db
          .from(table)
          .select('avatar_url')
          .eq('id', memberId)
          .maybeSingle();
      if (row != null && (row['avatar_url'] as String?)?.isNotEmpty == true) {
        return row['avatar_url'] as String;
      }
    }
    return null;
  }

  /// ฟังการเปลี่ยนแปลง avatar ของผู้เช่าแบบ real-time
  void _subscribeTenantChanges() {
    final client = Supabase.instance.client;

    _tenantChannel = client.channel('realtime:tenant_bill_avatars');

    final channel = _tenantChannel!;
    channel
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'tenants',
      callback: (payload) async {
        final changedId = payload.newRecord['id']?.toString() ?? '';
        final newAvatar = payload.newRecord['avatar_url']?.toString() ?? '';
        if (changedId.isNotEmpty && newAvatar.isNotEmpty) {
          if (mounted) {
            setState(() => _avatarCache[changedId] = newAvatar);
          }
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'roommate_invites',
      callback: (payload) async {
        final changedId = payload.newRecord['id']?.toString() ?? '';
        final newAvatar = payload.newRecord['avatar_url']?.toString() ?? '';
        if (changedId.isNotEmpty && newAvatar.isNotEmpty) {
          if (mounted) {
            setState(() => _avatarCache[changedId] = newAvatar);
          }
        }
      },
    )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final bills = _buildBills()
        .where((bill) => _filter == 'all' || bill['status'] == _filter)
        .where((bill) {
          final query = _searchController.text.trim().toLowerCase();
          if (query.isEmpty) return true;
          return '${bill['tenantName']} ${bill['room']}'.toLowerCase().contains(query);
        })
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummary(),
                        const SizedBox(height: 20),
                        _buildFilters(),
                        const SizedBox(height: 14),
                        _buildSearchField(),
                        const SizedBox(height: 16),
                        if (bills.isEmpty)
                          _buildEmptyState(hasAnyBills: _loadedBills.isNotEmpty)
                        else
                          _buildBillList(bills),
                      ],
                    ),
                  ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 18),
      color: Colors.white,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'บิลผู้เช่า',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: kPageTitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'จัดการบิลและสถานะการชำระ',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: widget.onCreateBill,
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text(
                'สร้างบิล',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4181CB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    // คำนวณจากบิลที่โหลดจาก Supabase โดยตรง
    final source = _loadedBills.isNotEmpty ? _loadedBills : widget.bills;
    int pending = source.where((b) => b['status'] == 'pending').length;
    int review  = source.where((b) => b['status'] == 'review').length;
    int paid    = source.where((b) => b['status'] == 'paid').length;

    // fallback ไปที่ widget.billStats ถ้า source ว่าง
    if (source.isEmpty && widget.billStats.isNotEmpty) {
      pending = widget.billStats['pending'] ?? 0;
      review  = widget.billStats['review']  ?? 0;
      paid    = widget.billStats['paid']    ?? 0;
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'รอชำระ',
            value: '$pending',
            color: const Color(0xFFE05C5C),
            background: const Color(0xFFFCE9E9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'รอตรวจสอบ',
            value: '$review',
            color: const Color(0xFFE6A700),
            background: const Color(0xFFFFF8E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'ชำระแล้ว',
            value: '$paid',
            color: const Color(0xFF4CAF50),
            background: const Color(0xFFE9F7EC),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: 'Noto Sans Thai', fontSize: 11, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = <(String, String)>[
      ('all', 'ทั้งหมด'),
      ('pending', 'รอชำระ'),
      ('review', 'รอตรวจสอบ'),
      ('paid', 'ชำระแล้ว'),
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

  Widget _buildSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7EF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 21, color: Color(0xFF8A8A8A)),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: 'ค้นหาผู้เช่าหรือห้อง',
                hintStyle: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                  color: Color(0xFF9AA4B2),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF9AA4B2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBillList(List<Map<String, dynamic>> bills) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _buildBillCard(bills[index]),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final status = bill['status'] as String;
    final statusColor = _statusColor(status);
    final statusBackground = _statusBackground(status);
    final proofUrl = bill['paymentProofUrl']?.toString() ??
        bill['payment_proof_url']?.toString() ??
        '';

    return GestureDetector(
      onTap: () {
        widget.onTapBill?.call(bill);
      },
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFEAF2FB),
                backgroundImage: (bill['avatar_url']?.toString().isNotEmpty == true)
                    ? NetworkImage(bill['avatar_url'].toString())
                    : const AssetImage('assets/images/user_avatar.png') as ImageProvider,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill['tenantName'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ห้อง ${bill['room']}  •  ${bill['month']}',
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  bill['statusLabel'] as String,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F2F5), thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ยอดเงิน',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatAmount(bill['total'] as num),
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'ครบกำหนด',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bill['dueDate'] as String,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: InteractiveViewer(
                      child: Image.network(proofUrl),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.receipt_long, size: 18, color: Color(0xFF4F8FDB)),
                    SizedBox(width: 8),
                    Text(
                      'ดูหลักฐานการโอน',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Color(0xFF4F8FDB),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: Color(0xFF4F8FDB)),
                  ],
                ),
              ),
            ),
          ],
          if (status == 'review')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: bill['id'] != null
                      ? () => widget.onApproveBill?.call(bill['id'].toString())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'อนุมัติการชำระ',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState({bool hasAnyBills = false}) {
    // hasAnyBills = true  → มีบิลในระบบแต่ filter/search ไม่ตรง
    // hasAnyBills = false → ยังไม่มีบิลเลยในหอพักนี้
    final title = hasAnyBills ? 'ไม่พบรายการบิล' : 'ยังไม่มีบิล';
    final subtitle = hasAnyBills
        ? 'ลองเปลี่ยนตัวกรองหรือค้นหาใหม่'
        : 'กด "สร้างบิล" เพื่อออกบิลให้ผู้เช่าในหอพัก';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF3), width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 38,
            color: Color(0xFFB7C1CE),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 12,
              color: Color(0xFF9AA4B2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const width = 320.0;
    const count = 6;
    const size = 40.0;
    const activeIndex = 2; // bill = index 2 เสมอ
    final slot = width / count;
    final indicatorLeft = slot * activeIndex + (slot - size) / 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: width,
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
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Color(0xFFFEFFAF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: List.generate(count, (index) {
              const activeIndex = 2;
              final selected = index == activeIndex;
              final color = selected ? const Color(0xFF4F8FDB) : Colors.white;
              return GestureDetector(
                onTap: () => _navigate(index),
                child: SizedBox(
                  width: slot,
                  height: 52,
                  child: Center(
                    child: index == 3
                        ? (widget.showRepairBadge
                            ? Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(Icons.build_outlined,
                                      size: 22, color: color),
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
                                            color: const Color(0xFF4F8FDB),
                                            width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Icon(Icons.build_outlined, size: 22, color: color))
                        : SvgPicture.asset(
                            _iconPath(index),
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              color,
                              BlendMode.srcIn,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _iconPath(int index) {
    const paths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/persons.svg',
      2: 'assets/images/icon_bill.svg',
      4: 'assets/images/icon_announcement.svg',
      5: 'assets/images/icon_user.svg',
    };
    return paths[index]!;
  }

  void _navigate(int index) {
    // ไม่ setState _selectedIndex เพราะ indicator ต้อง fix ที่ index 2 (bill) เสมอ
    switch (index) {
      case 0:
        print('Bottom nav tapped: Home (index 0) → navigate to Dashboard');
        widget.onNavigateToDashboard?.call();
        break;
      case 1:
        print('Bottom nav tapped: Tenant (index 1) → navigate to Tenant list');
        widget.onNavigateToTenant?.call();
        break;
      case 2:
        print('Bottom nav tapped: Bill (index 2) → no navigation callback');
        break;
      case 3:
        print('Bottom nav tapped: Repair (index 3) → navigate to Report Repair');
        widget.onNavigateToReportRepair?.call();
        break;
      case 4:
        print('Bottom nav tapped: Announcement (index 4) → navigate to Announcement');
        widget.onNavigateToAnnouncement?.call();
        break;
      case 5:
        print('Bottom nav tapped: Profile (index 5) → navigate to Profile');
        widget.onNavigateToProfile?.call();
        break;
      default:
        print('Bottom nav tapped: index $index → no navigation callback');
        break;
    }
  }

  List<Map<String, dynamic>> _buildBills() {
    // ใช้บิลที่โหลดจาก Supabase ก่อน ถ้ายังไม่มีค่อยใช้ widget.bills (legacy)
    final source = _loadedBills.isNotEmpty ? _loadedBills : widget.bills;
    if (source.isEmpty) return [];

    return source.map((bill) {
        // normalize keys ให้เข้ากัน
        final status = bill['status']?.toString() ?? 'pending';
        final statusLabel = bill['statusLabel']?.toString() ??
            bill['status_label']?.toString() ??
            (status == 'review'
                ? 'รอตรวจสอบ'
                : status == 'paid'
                    ? 'ชำระแล้ว'
                    : 'รอชำระ');
        return {
          'id': bill['id'],
          'tenantName': bill['tenantName'] ?? bill['tenant_name'] ?? '',
          'room': bill['room'] ?? bill['room_number'] ?? '',
          'month': bill['month'] ?? '',
          'total': bill['total'] ?? bill['amount'] ?? 0,
          'dueDate': bill['dueDate'] ?? bill['due_date'] ?? '',
          'status': status,
          'statusLabel': statusLabel,
          'avatar_url': _avatarCache[bill['tenant_id']?.toString() ?? ''] ??
              bill['avatar_url'] ??
              bill['tenant_avatar_url'] ??
              '',
          ...bill,
        };
      }).toList();
  }

  Color _statusColor(String status) {
    if (status == 'pending') return const Color(0xFFE05C5C);
    if (status == 'review') return const Color(0xFFE6A700);
    return const Color(0xFF4CAF50);
  }

  Color _statusBackground(String status) {
    if (status == 'pending') return const Color(0xFFFCE9E9);
    if (status == 'review') return const Color(0xFFFFF8E5);
    return const Color(0xFFE9F7EC);
  }

  String _formatAmount(num value) {
    final whole = value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return '$whole บาท';
  }
}
