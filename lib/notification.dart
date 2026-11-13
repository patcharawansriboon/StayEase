import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widgets/app_sizes.dart';
class NotificationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isTenant;
  final VoidCallback? onNavigateToDormitoryRequest;
  final VoidCallback? onNavigateToRoommateRequest;
  final VoidCallback? onNavigateToRequestChangeTenant;

  const NotificationScreen({
    super.key,
    this.onBack,
    this.isTenant = false,
    this.onNavigateToDormitoryRequest,
    this.onNavigateToRoommateRequest,
    this.onNavigateToRequestChangeTenant,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _dormitoryRequest = true;
  bool _roommateRequest = true;
  bool _changeRoomRequest = true;
  bool _repairRequest = true;

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
                  const SizedBox(height: 12),
                  SvgPicture.asset(
                    'assets/images/bell.svg',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'จัดการการแจ้งเตือน',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'เลือกประเภทการแจ้งเตือนที่ต้องการ',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 20),
                if (widget.isTenant) ...[
                  _buildToggleRow(
                     iconAsset: 'assets/images/plump_announce.svg',
                     label: 'ประกาศจากแอดมิน',
                     value: _dormitoryRequest,
                     onChanged: (v) => setState(() => _dormitoryRequest = v),
                  ),
                  const SizedBox(height: 10),
                  _buildToggleRow(
                    iconAsset: 'assets/images/icon_invoice.svg',
                    label: 'บิล/ค่าเช่า',
                    value: _roommateRequest,
                    onChanged: (v) => setState(() => _roommateRequest = v),
                  ),
                  const SizedBox(height: 10),
                  _buildToggleRow(
                    iconAsset: 'assets/images/icon_message.svg',
                    label: 'แชท',
                    value: _changeRoomRequest,
                    onChanged: (v) => setState(() => _changeRoomRequest = v),
                  ),
                ] else ...[
                   _buildToggleRow(
                     iconAsset: 'assets/images/fontisto_bell.svg',
                     label: 'คำขอเข้าหอพัก',
                     value: _dormitoryRequest,
                     onChanged: (v) => setState(() => _dormitoryRequest = v),
                  ),
                  const SizedBox(height: 10),
                   _buildToggleRow(
                     iconAsset: 'assets/images/fontisto_bell.svg',
                     label: 'คำขอ Roommate',
                     value: _roommateRequest,
                     onChanged: (v) => setState(() => _roommateRequest = v),
                  ),
                  const SizedBox(height: 10),
                  _buildToggleRow(
                    icon: Icons.swap_horiz_outlined,
                    label: 'คำขอเปลี่ยนห้องพัก',
                    value: _changeRoomRequest,
                    onChanged: (v) => setState(() => _changeRoomRequest = v),
                  ),
                  const SizedBox(height: 10),
                  _buildToggleRow(
                    icon: Icons.build_outlined,
                    label: 'แจ้งซ่อม',
                    value: _repairRequest,
                    onChanged: (v) => setState(() => _repairRequest = v),
                  ),
                ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'การแจ้งเตือน',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    IconData? icon,
    String? iconAsset,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    Widget iconWidget = icon != null
        ? Icon(icon, size: 24, color: const Color(0xFF4F8FDB))
        : SvgPicture.asset(
            iconAsset!,
            width: 24,
            height: 24,
          );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 15,
                color: Color(0xFF000000),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF4F8FDB),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }
}
