import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// แถบเมนูล่างสำหรับหน้าหลักของผู้ใช้/ผู้เช่า (5 ไอคอน)
/// ใช้ตัวเดียวกันทุกหน้า (หน้าหลัก, ค่าเช่า, แจ้งซ่อม, ประกาศ) เพื่อให้หน้าตาเหมือนกัน
///
/// index 0: หน้าหลัก (icon_home)
/// index 1: ค่าเช่า/บิล (icon_bill)
/// index 2: แจ้งซ่อม/แชท (icon_message)
/// index 3: ประกาศ (icon_announcement)
/// index 4: โปรไฟล์ (icon_user)
///
/// วงกลมสีเหลือง (indicator) จะอยู่ที่ไอคอนตาม [selectedIndex]
class UserBottomNav extends StatelessWidget {
  const UserBottomNav({
    super.key,
    required this.selectedIndex,
    this.onSelected,
    this.onHome,
    this.onBill,
    this.onChat,
    this.onAnnounce,
    this.onProfile,
    this.showChatBadge = false,
  });

  /// index ของไอคอนที่ active (วงกลมสีเหลืองอยู่ตรงนี้)
  final int selectedIndex;

  /// แสดงจุดแดงที่ไอคอนแชท (index 2) เมื่อมีข้อความ/สถานะใหม่
  final bool showChatBadge;

  /// เรียกทุกครั้งที่ผู้ใช้แตะไอคอน ก่อน callback ของไอคอนนั้น
  final ValueChanged<int>? onSelected;

  final VoidCallback? onHome;
  final VoidCallback? onBill;
  final VoidCallback? onChat;
  final VoidCallback? onAnnounce;
  final VoidCallback? onProfile;

  static const double navWidth = 280;
  static const double navHeight = 52;
  static const double circleSize = 44;
  static const double itemSize = 44;
  static const double iconSize = 26;
  static const double indicatorLeft = 11.6667;
  static const double indicatorStep = 53.1667;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: navWidth,
        height: navHeight,
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
            // Active indicator circle
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: indicatorLeft + selectedIndex * indicatorStep,
              top: 4,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEFFAF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Icons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItems() {
    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/icon_bill.svg',
      2: 'assets/images/icon_message.svg',
      3: 'assets/images/icon_announcement.svg',
      4: 'assets/images/icon_user.svg',
    };

    return List.generate(svgPaths.length, (i) {
      final isActive = i == selectedIndex;
      final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
      final icon = SvgPicture.asset(
        svgPaths[i]!,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
      return GestureDetector(
        onTap: () => _handleTap(i),
        child: SizedBox(
          width: itemSize,
          height: itemSize,
          child: Center(
            // ไอคอนแชท (index 2) + จุดแดงถ้ามีข้อความใหม่
            child: (i == 2 && showChatBadge)
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      icon,
                      Positioned(
                        right: -2,
                        top: -2,
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
                  )
                : icon,
          ),
        ),
      );
    });
  }

  void _handleTap(int index) {
    onSelected?.call(index);
    switch (index) {
      case 0:
        onHome?.call();
        break;
      case 1:
        onBill?.call();
        break;
      case 2:
        onChat?.call();
        break;
      case 3:
        onAnnounce?.call();
        break;
      case 4:
        onProfile?.call();
        break;
    }
  }
}
