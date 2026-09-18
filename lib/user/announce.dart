import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnnounceScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final ValueChanged<String>? onNavigateToDetails;
  final VoidCallback? onNavigateToProfile;
  final List<Map<String, String>> announcements;
  final bool isAdmin;

  const AnnounceScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToRentalFee,
    this.onNavigateToChat,
    this.onNavigateToDetails,
    this.onNavigateToProfile,
    this.announcements = const [],
    this.isAdmin = false,
  });

  @override
  State<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends State<AnnounceScreen> {
  int _selectedIndex = 3;

  List<Map<String, String>> get _displayAnnouncements =>
      widget.announcements.isNotEmpty
          ? widget.announcements
          : [
              {'image': 'assets/images/announcement_1.png'},
              {'image': 'assets/images/announcement_2.png'},
            ];

  String get _detailButtonText => 'รายละเอียด';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: _displayAnnouncements.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnnouncementCard(item['image']!),
                  )).toList(),
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ---- Header ----
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: const Center(
        child: Text(
          'ประกาศ',
          style: TextStyle(
            fontFamily: 'Prompt',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  // ---- Announcement Card ----
  Widget _buildAnnouncementCard(String imagePath) {
    return GestureDetector(
      onTap: () => widget.onNavigateToDetails?.call(imagePath),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Announcement image
              Image.asset(
                imagePath,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        size: 48, color: Color(0xFFCCCCCC)),
                  ),
                ),
              ),
              // Detail/Edit button
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => widget.onNavigateToDetails?.call(imagePath),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F8FDB).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _detailButtonText,
                      style: const TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Bottom Navigation ----
  Widget _buildBottomNav() {
    return widget.isAdmin ? _buildAdminBottomNav() : _buildTenantBottomNav();
  }

  // ---- Tenant Bottom Nav (5 icons) ----
  Widget _buildTenantBottomNav() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 280,
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
              left: 11.67 + _selectedIndex * 53.17,
              top: 4,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEFFAF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildTenantNavItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTenantNavItems() {
    final items = <IconData?>[
      null, // index 0 icon_home.svg
      null, // index 1 icon_bill.svg
      null, // index 2 icon_message.svg
      null, // index 3 icon_announcement.svg
      null, // index 4 icon_user.svg
    ];

    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/icon_bill.svg',
      2: 'assets/images/icon_message.svg',
      3: 'assets/images/icon_announcement.svg',
      4: 'assets/images/icon_user.svg',
    };

    return List.generate(items.length, (i) {
      final isActive = i == _selectedIndex;
      return GestureDetector(
        onTap: () {
          if (i == 0 && widget.onNavigateToHome != null) {
            widget.onNavigateToHome!();
          } else if (i == 1 && widget.onNavigateToRentalFee != null) {
            widget.onNavigateToRentalFee!();
          } else if (i == 2 && widget.onNavigateToChat != null) {
            widget.onNavigateToChat!();
          } else if (i == 4 && widget.onNavigateToProfile != null) {
            widget.onNavigateToProfile!();
          } else {
            setState(() => _selectedIndex = i);
          }
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: items[i] == null
                ? SvgPicture.asset(
                    svgPaths[i]!,
                    width: 26,
                    height: 26,
                    colorFilter: ColorFilter.mode(
                      isActive ? const Color(0xFF4F8FDB) : Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(
                    items[i],
                    color: isActive ? const Color(0xFF4F8FDB) : Colors.white,
                    size: 22,
                  ),
          ),
        ),
      );
    });
  }

  // ---- Admin Bottom Nav (6 icons) ----
  Widget _buildAdminBottomNav() {
    const navWidth = 320.0;
    const circleSize = 40.0;
    const itemCount = 6;
    const activeIndex = 4;
    final slot = navWidth / itemCount;

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
          // Soft yellow indicator circle (fixed at index 4)
          Positioned(
            left: slot * activeIndex + (slot - circleSize) / 2,
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
            children: _buildAdminNavItems(slot),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdminNavItems(double slot) {
    // announcement tab is at index 4
    const activeIndex = 4;
    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/persons.svg',
      2: 'assets/images/icon_bill.svg',
      4: 'assets/images/icon_announcement.svg',
      5: 'assets/images/icon_user.svg',
    };
    final materialIcons = <int, IconData>{3: Icons.build_outlined};

    return List.generate(6, (i) {
      final isActive = i == activeIndex;
      final iconColor = isActive ? const Color(0xFF4F8FDB) : Colors.white;

      final Widget iconWidget = svgPaths.containsKey(i)
          ? SvgPicture.asset(
              svgPaths[i]!,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          : Icon(materialIcons[i], size: 22, color: iconColor);

      return GestureDetector(
        onTap: () {
          if (i == 0 && widget.onNavigateToHome != null) {
            widget.onNavigateToHome!();
          } else if (i == 2 && widget.onNavigateToRentalFee != null) {
            widget.onNavigateToRentalFee!();
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
