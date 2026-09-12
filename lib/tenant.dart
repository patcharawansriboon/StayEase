import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TenantScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToMasterTenant;
  final VoidCallback? onNavigateToEditeTenant;

  const TenantScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToMasterTenant,
    this.onNavigateToEditeTenant,
  });

  @override
  State<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen> {
  int _selectedIndex = 1;
  final _searchController = TextEditingController();
  String _filter = 'ทั้งหมด';

  final List<Map<String, String>> _tenants = [
    {
      'name': 'พัชราวรรณ  ศรีบุญ',
      'room': 'A303',
      'role': 'ผู้เช่าหลัก',
      'phone': '099-999999',
      'status': 'กำลังเช่า',
    },
    {
      'name': 'พัชราวรรณ  ศรีบุญ',
      'room': 'A303',
      'role': 'Roommate',
      'phone': '099-999999',
      'status': 'กำลังเช่า',
    },
    {
      'name': 'พัชราวรรณ  ศรีบุญ',
      'room': 'C101',
      'role': 'ผู้เช่าหลัก',
      'phone': '099-999999',
      'status': 'ว่าง/รอ',
    },
  ];

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
                _buildFilterDropdown(),
                const SizedBox(height: 12),
                ..._tenants.map(_buildTenantCard),
              ],
            ),
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
      height: 38,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: const Text(
          'เพิ่มผู้เช่า',
          style: TextStyle(
            fontFamily: 'Prompt',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4181CB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildStatBar() {
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
              number: '50',
              label: 'ผู้เช่าทั้งหมด',
            ),
          ),
          Expanded(
            child: _buildStatCell(
              bg: const Color(0xFFE9F7EC),
              icon: Icons.people,
              iconColor: const Color(0xFF4CAF50),
              number: '48',
              label: 'กำลังเช่า',
            ),
          ),
          Expanded(
            child: _buildStatCell(
              bg: const Color(0xFFF2F2F2),
              icon: Icons.person_outline,
              iconColor: const Color(0xFF999999),
              number: '2',
              label: 'ว่าง/รอ',
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

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4181CB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter,
          isDense: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 20, color: Colors.white),
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 13,
            color: Colors.white,
          ),
          selectedItemBuilder: (context) => ['ทั้งหมด', 'กำลังเช่า', 'ว่าง/รอ']
              .map((e) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(e,
                        style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Colors.white)),
                  ))
              .toList(),
          items: ['ทั้งหมด', 'กำลังเช่า', 'ว่าง/รอ']
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e,
                        style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Color(0xFF000000))),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _filter = v ?? 'ทั้งหมด'),
        ),
      ),
    );
  }

  Widget _buildTenantCard(Map<String, String> t) {
    final isActive = t['status'] == 'กำลังเช่า';
    final isMaster = t['role'] == 'ผู้เช่าหลัก';
    final isRoommate = t['role'] == 'Roommate';
    return GestureDetector(
      onTap: isMaster
          ? widget.onNavigateToMasterTenant
          : isRoommate
              ? widget.onNavigateToEditeTenant
              : null,
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
    final slot = navWidth / itemCount;
    final indicatorLeft = slot * _selectedIndex + (slot - circleSize) / 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: navWidth,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF78A2D2),
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

    return List.generate(6, (i) {
      final isActive = i == _selectedIndex;
      final color = isActive ? const Color(0xFF78A2D2) : Colors.white;
      return GestureDetector(
        onTap: () {
          if (i == 0 && widget.onNavigateToDashboard != null) {
            widget.onNavigateToDashboard!();
          } else {
            setState(() => _selectedIndex = i);
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
