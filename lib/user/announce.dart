import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnnounceScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final ValueChanged<String>? onNavigateToDetails;
  final VoidCallback? onNavigateToProfile;

  const AnnounceScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToRentalFee,
    this.onNavigateToChat,
    this.onNavigateToDetails,
    this.onNavigateToProfile,
  });

  @override
  State<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends State<AnnounceScreen> {
  int _selectedIndex = 3;

  final List<Map<String, String>> _announcements = [
    {
      'image': 'assets/images/announcement_1.png',
    },
    {
      'image': 'assets/images/announcement_2.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.35, 0.6, 1.0],
            colors: [
              Color(0xFFEAF2FB),
              Color(0xFFBFD9F2),
              Color(0xFFCFE0F0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: _announcements.map((item) => Padding(
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
              // รายละเอียด button
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => widget.onNavigateToDetails?.call(imagePath),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78A2D2).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'รายละเอียด',
                      style: TextStyle(
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
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 280,
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
                children: _buildNavItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
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
                      isActive ? const Color(0xFF78A2D2) : Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(
                    items[i],
                    color: isActive ? const Color(0xFF78A2D2) : Colors.white,
                    size: 22,
                  ),
          ),
        ),
      );
    });
  }
}
