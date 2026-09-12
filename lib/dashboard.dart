import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardScreen extends StatefulWidget {
  final String adminName;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToNotification;

  const DashboardScreen({
    super.key,
    this.adminName = 'พัชราวรรณ  ศรีบุญ',
    this.onNavigateToTenant,
    this.onNavigateToNotification,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

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
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStatGrid(),
                  const SizedBox(height: 16),
                  _buildRepairCard(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
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

  // ---- Header ----
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: const AssetImage('assets/images/user_avatar.png'),
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.adminName,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              const Text(
                'Admin',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: widget.onNavigateToNotification,
          child: Container(
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
        ),
      ],
    );
  }

  // ---- Stat grid (2x2) ----
  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                bg: const Color(0xFFEAF2FB),
                icon: Icons.people,
                iconColor: const Color(0xFF4181CB),
                number: '58',
                label: 'ผู้เช่าทั้งหมด',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                bg: const Color(0xFFFFF8E5),
                icon: Icons.home,
                iconColor: const Color(0xFFE6A700),
                number: '60',
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
                number: '2',
                label: 'ห้องว่าง',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                bg: const Color(0xFFFCE9E9),
                icon: Icons.build,
                iconColor: const Color(0xFFE05C5C),
                number: '3',
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
              fontFamily: 'Prompt',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000000),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

// ---- แจ้งซ่อม ----
  Widget _buildRepairCard() {
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
                'แจ้งซ่อม',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              const Spacer(),
              const Text(
                'ดูทั้งหมด',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 13,
                  color: Color(0xFF4181CB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRepairRow('A301', '8 ก.ย. 09:45'),
          const SizedBox(height: 10),
          _buildRepairRow('A303', '8 ก.ย. 09:45'),
        ],
      ),
    );
  }

  Widget _buildRepairRow(String room, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: const AssetImage('assets/images/user_avatar.png'),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.adminName,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Prompt',
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
              fontFamily: 'Prompt',
              fontSize: 11,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // ---- การชำระเงิน ----
  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การชำระเงิน',
          style: TextStyle(
            fontFamily: 'Prompt',
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
                number: '12',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentChip(
                bg: const Color(0xFFFFF8E5),
                titleColor: const Color(0xFFE6A700),
                title: 'รอตรวจสอบสลิป',
                number: '3',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentChip(
                bg: const Color(0xFFE9F7EC),
                titleColor: const Color(0xFF4CAF50),
                title: 'ชำระแล้ว',
                number: '45',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 11,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            number,
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const Text(
            'รายการ',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 11,
              color: Color(0xFF999999),
            ),
          ),
        ],
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
          if (i == 1 && widget.onNavigateToTenant != null) {
            widget.onNavigateToTenant!();
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
