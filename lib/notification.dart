import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToDormitoryRequest;
  final VoidCallback? onNavigateToRoommateRequest;

  const NotificationScreen({
    super.key,
    this.onBack,
    this.onNavigateToDormitoryRequest,
    this.onNavigateToRoommateRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  _buildNotificationCard(
                    iconBg: const Color(0xFF4181CB),
                    icon: Icons.person_outline,
                    title: 'คำขอเข้าหอพัก (ผู้เช่าหลัก)',
                    description: 'พัชราวรรณ  ศรีบุญ ต้องการเข้าพัก',
                    time: '09:25 น.',
                    onTap: onNavigateToDormitoryRequest,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    iconBg: const Color(0xFF4CAF50),
                    icon: Icons.group_outlined,
                    title: 'คำขอ Roommate',
                    description: 'พัชราวรรณ  ศรีบุญ ขอเข้าพัก',
                    time: '09:25 น.',
                    onTap: onNavigateToRoommateRequest,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    iconBg: const Color(0xFFE6A700),
                    icon: Icons.swap_horiz,
                    title: 'คำขอเปลี่ยนเป็นผู้เช่าหลัก',
                    description: 'พัชราวรรณ  ศรีบุญ ต้องการย้าย',
                    time: '09:25 น.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required Color iconBg,
    required IconData icon,
    required String title,
    required String description,
    required String time,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'การแจ้งเตือน',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
