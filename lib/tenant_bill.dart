import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TenantBillScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToReportRepair;
  final VoidCallback? onNavigateToAnnouncement;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onCreateBill;
  final void Function(Map<String, dynamic> bill)? onTapBill;
  final List<Map<String, String>> tenants;
  final Map<String, dynamic> currentBill;

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
    this.tenants = const [],
    this.currentBill = const {},
  });

  @override
  State<TenantBillScreen> createState() => _TenantBillScreenState();
}

class _TenantBillScreenState extends State<TenantBillScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bills = _buildBills()
        .where((bill) => _filter == 'all' || bill['status'] == _filter)
        .where((bill) {
          final query = _searchController.text.trim().toLowerCase();
          if (query.isEmpty) return true;
          return '${bill['tenantName']} ${bill['room']}'.toLowerCase().contains(
            query,
          );
        })
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
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
                    _buildEmptyState()
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
                    fontFamily: 'Prompt',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'จัดการบิลและสถานะการชำระ',
                  style: TextStyle(
                    fontFamily: 'Prompt',
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
                  fontFamily: 'Prompt',
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
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'รอชำระ',
            value: '12',
            color: const Color(0xFFE05C5C),
            background: const Color(0xFFFCE9E9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'รอตรวจสอบ',
            value: '3',
            color: const Color(0xFFE6A700),
            background: const Color(0xFFFFF8E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'ชำระแล้ว',
            value: '45',
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
            style: TextStyle(fontFamily: 'Prompt', fontSize: 11, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Prompt',
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
                    fontFamily: 'Prompt',
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
                  fontFamily: 'Prompt',
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
                backgroundImage: const AssetImage(
                  'assets/images/user_avatar.png',
                ),
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
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ห้อง ${bill['room']}  •  ${bill['month']}',
                      style: const TextStyle(
                        fontFamily: 'Prompt',
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
                    fontFamily: 'Prompt',
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
                        fontFamily: 'Prompt',
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatAmount(bill['total'] as num),
                      style: const TextStyle(
                        fontFamily: 'Prompt',
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
                      fontFamily: 'Prompt',
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bill['dueDate'] as String,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'ไม่พบรายการบิล',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ลองเปลี่ยนตัวกรองหรือค้นหาใหม่',
            style: TextStyle(
              fontFamily: 'Prompt',
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
                        ? Icon(Icons.build_outlined, size: 22, color: color)
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
    final bill = widget.currentBill;
    final tenantList = widget.tenants.isNotEmpty
        ? widget.tenants
        : [
            {'name': 'พัชราวรรณ ศรีบุญ', 'room': 'A101', 'role': 'ผู้เช่าหลัก', 'phone': '0999999999', 'status': 'กำลังเช่า'},
            {'name': 'สมชาย ใจดี',        'room': 'A101', 'role': 'Roommate',    'phone': '0888888888', 'status': 'กำลังเช่า'},
            {'name': 'วิภา รักเรียน',     'room': 'A102', 'role': 'ผู้เช่าหลัก', 'phone': '0777777777', 'status': 'กำลังเช่า'},
          ];
    return tenantList.asMap().entries.map((entry) {
      final index = entry.key;
      final tenant = entry.value;
      final pending = index == 0;
      final review = index == 1;
      return {
        'tenantName': tenant['name'],
        'room': tenant['room'],
        'month': index == 0 ? (bill['month'] ?? 'กรกฎาคม 2569') : 'สิงหาคม 2569',
        'total': index == 0 ? (bill['total'] ?? 5090) : 5090 - index * 110,
        'dueDate': index == 0 ? (bill['due_date'] ?? '5 สิงหาคม 2569') : '5 สิงหาคม 2569',
        'status': pending ? 'pending' : review ? 'review' : 'paid',
        'statusLabel': pending ? 'รอชำระ' : review ? 'รอตรวจสอบ' : 'ชำระแล้ว',
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
