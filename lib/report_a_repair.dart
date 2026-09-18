import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReportARepairScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToChatAdmin;
  final VoidCallback? onNavigateToProfile;

  const ReportARepairScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTenant,
    this.onNavigateToChatAdmin,
    this.onNavigateToProfile,
  });

  @override
  State<ReportARepairScreen> createState() => _ReportARepairScreenState();
}

class _ReportARepairScreenState extends State<ReportARepairScreen> {
  int _selectedIndex = 3;
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _repairs = [
    {
      'name': 'พัชราวรรณ  ศรีบุญ',
      'room': 'A303',
      'jobId': 'JK-2569-0002',
      'time': '09:18 น.',
      'status': 'งานใหม่',
      'statusColor': Color(0xFFF16C6C),
      'statusBg': Color(0xFFFCE9E9),
    },
    {
      'name': 'พัชราวรรณ  ศรีบุญ',
      'room': 'A303',
      'jobId': 'RM-2569-0001',
      'time': '09:18 น.',
      'status': 'กำลังดำเนินการ',
      'statusColor': Color(0xFFE6A700),
      'statusBg': Color(0xFFFFF8E5),
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _repairs;
    return _repairs
        .where((r) =>
            (r['name'] as String).toLowerCase().contains(q) ||
            (r['room'] as String).toLowerCase().contains(q) ||
            (r['jobId'] as String).toLowerCase().contains(q))
        .toList();
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildRepairCard(_filtered[i]),
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

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 60, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'แจ้งซ่อม',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4181CB),
            ),
          ),
          SizedBox(height: 2),
          Text(
            'จัดการคำขอแจ้งซ่อมทั้งหมด',
            style: TextStyle(
              fontFamily: 'Prompt',
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
            fontFamily: 'Prompt',
            fontSize: 14,
            color: Color(0xFF000000),
          ),
          decoration: const InputDecoration(
            hintText: 'ค้นหาชื่อหรือเลขห้อง',
            hintStyle: TextStyle(
              fontFamily: 'Prompt',
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
    return GestureDetector(
      onTap: () {
        if (widget.onNavigateToChatAdmin != null) {
          widget.onNavigateToChatAdmin!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: const AssetImage('assets/images/user_avatar.png'),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repair['name'] as String,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ห้อง ${repair['room']}',
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    repair['jobId'] as String,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: repair['statusBg'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    repair['status'] as String,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 11,
                      color: repair['statusColor'] as Color,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  repair['time'] as String,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
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

    return List.generate(6, (i) {
      final isActive = i == _selectedIndex;
      final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
      return GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = i);
          if (i == 0 && widget.onNavigateToDashboard != null) {
            widget.onNavigateToDashboard!();
          } else if (i == 1 && widget.onNavigateToTenant != null) {
            widget.onNavigateToTenant!();
          } else if (i == 4 && widget.onNavigateToChatAdmin != null) {
            widget.onNavigateToChatAdmin!();
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
