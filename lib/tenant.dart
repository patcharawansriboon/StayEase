import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/tenant_auth_service.dart';

class TenantScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToMasterTenant;
  final VoidCallback? onNavigateToEditeTenant;
  final VoidCallback? onNavigateToReportRepair;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToAnnounce;
  final void Function(int index)? selectedTenantIndex;
  final VoidCallback? onTenantSelected;
  final List<Map<String, String>> tenants;

  const TenantScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToMasterTenant,
    this.onNavigateToEditeTenant,
    this.onNavigateToReportRepair,
    this.onNavigateToProfile,
    this.onNavigateToBill,
    this.onNavigateToAnnounce,
    this.selectedTenantIndex,
    this.onTenantSelected,
    this.tenants = const [],
  });

  @override
  State<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen> {
  final _searchController = TextEditingController();
  String _filter = 'ทั้งหมด';
  List<Map<String, String>> _tenants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    final service = TenantAuthService();
    final rows = await service.getDormitoryTenants();
    if (rows.isNotEmpty) {
      _tenants = rows.map((r) => {
        'name': r['name']?.toString() ?? '',
        'room': r['room']?.toString() ?? '',
        'role': r['role']?.toString() ?? '',
        'phone': r['phone']?.toString() ?? '',
        'status': r['status']?.toString() ?? '',
        'member_id': r['member_id']?.toString() ?? '',
        'building': r['building']?.toString() ?? '',
        'floor': r['floor']?.toString() ?? '',
        'check_in': r['check_in']?.toString() ?? '',
        'check_out': r['check_out']?.toString() ?? '',
        'rent': r['rent']?.toString() ?? '',
        'deposit': r['deposit']?.toString() ?? '',
      }).toList();
    } else {
      _tenants = widget.tenants.isNotEmpty
          ? widget.tenants
          : [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void didUpdateWidget(covariant TenantScreen old) {
    super.didUpdateWidget(old);
    if (widget.tenants.isNotEmpty) {
      _tenants = widget.tenants;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (!_loading)
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ผู้เช่า',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4181CB),
                    ),
                  ),
                  const Text(
                    'จัดการข้อมูลผู้เช่าทั้งหมด',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 13,
                      color: Color(0xFF8AA0BE),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildAddButton(),
                  ),
                  const SizedBox(height: 12),
                  _buildStatBar(),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  const SizedBox(height: 12),
                  ..._tenants
                      .where((t) =>
                          _filter == 'ทั้งหมด' || t['status'] == _filter)
                      .map(_buildTenantCard),
                ],
              ),
            ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF4181CB)),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: Color(0xFF999999)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                  fontFamily: 'Prompt', fontSize: 14, color: Color(0xFF000000)),
              decoration: const InputDecoration(
                hintText: 'ค้นหาชื่อหรือเลขห้อง',
                hintStyle: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    color: Color(0xFFAAAAAA)),
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add, size: 14, color: Colors.white),
        label: const Text(
          'เพิ่มผู้เช่า',
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        ),
      ),
    );
  }

  Widget _buildStatBar() {
    final countTotal = _tenants.length;
    final countActive = _tenants.where((t) => t['status'] == 'กำลังเช่า').length;
    final countEmpty = _tenants.where((t) => t['status'] != 'กำลังเช่า').length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCell(
              bg: const Color(0xFFEAF2FB),
              icon: Icons.people,
              iconColor: const Color(0xFF4181CB),
              number: countTotal.toString(),
              label: 'ผู้เช่าทั้งหมด',
            ),
          ),
          Expanded(
            child: _buildStatCell(
              bg: const Color(0xFFE9F7EC),
              icon: Icons.people,
              iconColor: const Color(0xFF4CAF50),
              number: countActive.toString(),
              label: 'กำลังเช่า',
            ),
          ),
          Expanded(
            child: _buildStatCell(
              bg: const Color(0xFFF2F2F2),
              icon: Icons.person_outline,
              iconColor: const Color(0xFF999999),
              number: countEmpty.toString(),
              label: 'อื่นๆ',
              trailingChevron: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String number,
    required String label,
    bool trailingChevron = false,
  }) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 6),
              Text(
                number,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          if (trailingChevron)
            const Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFF999999)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = <String>['ทั้งหมด', 'กำลังเช่า', 'ว่าง/รอ'];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final label = filters[index];
          final selected = _filter == label;
          return GestureDetector(
            onTap: () => setState(() => _filter = label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4181CB)
                    : Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4181CB)
                      : const Color(0xFFDDE5EE),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
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

  Widget _buildTenantCard(Map<String, String> t) {
    final isActive = t['status'] == 'กำลังเช่า';
    final index = _tenants.indexOf(t);
    return GestureDetector(
      onTap: () {
        widget.selectedTenantIndex?.call(index);
        widget.onTenantSelected?.call();
        widget.onNavigateToMasterTenant?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['name']!,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 13,
                      color: Color(0xFF4181CB),
                    ),
                    children: [
                      TextSpan(text: t['room']),
                      const TextSpan(
                        text: '  •  ',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                      TextSpan(text: t['role']),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t['phone']!,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
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
              _buildStatusBadge(t['status']!, isActive),
              const SizedBox(height: 18),
              const Icon(Icons.chevron_right,
                  size: 20, color: Color(0xFF999999)),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isActive) {
    final bg = isActive ? const Color(0xFFE9F7EC) : const Color(0xFFF0F0F0);
    final fg = isActive ? const Color(0xFF4CAF50) : const Color(0xFF888888);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Prompt',
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }

  // ---- Bottom Navigation (6 icons) ----
  Widget _buildBottomNav() {
    const navWidth = 320.0;
    const itemCount = 6;
    const circleSize = 40.0;
    const activeIndex = 1; // tenant = index 1 เสมอ
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

    const activeIndex = 1; // tenant = index 1 เสมอ
    return List.generate(6, (i) {
      final isActive = i == activeIndex;
      final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
      return GestureDetector(
        onTap: () {
          if (i == 0 && widget.onNavigateToDashboard != null) {
            widget.onNavigateToDashboard!();
          } else if (i == 2 && widget.onNavigateToBill != null) {
            widget.onNavigateToBill!();
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
