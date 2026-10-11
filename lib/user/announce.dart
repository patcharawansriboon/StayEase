import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/mock_service.dart';

class AnnounceScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final ValueChanged<String>? onNavigateToDetails;
  final VoidCallback? onNavigateToProfile;
  final List<Map<String, String>> announcements;
  final bool isAdmin;
  final bool hasRoom;
  final VoidCallback? onAddAnnouncement;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToReportRepair;

  const AnnounceScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToRentalFee,
    this.onNavigateToChat,
    this.onNavigateToDetails,
    this.onNavigateToProfile,
    this.announcements = const [],
    this.isAdmin = false,
    this.hasRoom = true,
    this.onAddAnnouncement,
    this.onNavigateToTenant,
    this.onNavigateToReportRepair,
  });

  @override
  State<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends State<AnnounceScreen> {
  int _selectedIndex = 3;
  final _mockService = MockService();

  List<Map<String, String>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  /// เรียกจากภายนอกเมื่อกลับมาที่หน้านี้
  void reload() {
    if (!mounted) return;
    setState(() => _loading = true);
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      // ดึงเฉพาะประกาศที่เผยแพร่ (ไม่มีระบบฉบับร่างแล้ว)
      String? status = 'published';
      String? dormId;
      if (widget.isAdmin) {
        dormId = await _mockService.getAdminDormitoryId();
      }

      final rows = await _mockService.getAnnouncements(
        dormitoryId: dormId,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _announcements = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _announcements = [];
        _loading = false;
      });
    }
  }

  List<Map<String, String>> get _displayAnnouncements => _announcements;

  String get _detailButtonText => 'รายละเอียด';  @override
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
              child: (!widget.isAdmin && !widget.hasRoom)
                  ? _buildNoRoomEmptyState()
                  : _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _displayAnnouncements.isEmpty
                          ? _buildEmptyAnnouncements()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Column(
                                children: _displayAnnouncements
                                    .map((item) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _buildAnnouncementCard(item),
                                        ))
                                    .toList(),
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
    if (widget.isAdmin) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
        child: Row(
          children: [
            const Expanded(
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
            // ปุ่มเพิ่มประกาศ
            GestureDetector(
              onTap: widget.onAddAnnouncement,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8FDB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'เพิ่มประกาศ',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Center(
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

  // ---- Empty state เมื่อยังไม่ได้เข้าร่วมหอพัก ----
  Widget _buildNoRoomEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_outlined,
                  size: 48, color: Color(0xFF4F8FDB)),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่มีประกาศ',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'คุณยังไม่ได้เข้าร่วมห้องพักใด\nจึงยังไม่มีประกาศจากหอพัก',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.45),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Empty state เมื่อไม่มีประกาศ ----
  Widget _buildEmptyAnnouncements() {
    final msg = widget.isAdmin ? 'ยังไม่มีประกาศที่เผยแพร่' : 'ยังไม่มีประกาศ';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_outlined,
                  size: 48, color: Color(0xFF4F8FDB)),
            ),
            const SizedBox(height: 20),
            Text(
              msg,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageError() => Container(
        width: double.infinity,
        height: 160,
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFCCCCCC)),
        ),
      );

  // ---- Announcement Card ----
  Widget _buildAnnouncementCard(Map<String, String> item) {
    final imagePath = item['image'] ?? '';
    final title     = item['title'] ?? '';
    final content   = item['content'] ?? '';
    final date      = item['date'] ?? '';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปภาพ (ถ้ามี)
              if (imagePath.isNotEmpty)
                imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : Image.asset(
                        imagePath,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              // title + content + วันที่
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 11,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ],
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
          } else if (i == 1 && widget.onNavigateToTenant != null) {
            widget.onNavigateToTenant!();
          } else if (i == 2 && widget.onNavigateToRentalFee != null) {
            widget.onNavigateToRentalFee!();
          } else if (i == 3 && widget.onNavigateToReportRepair != null) {
            widget.onNavigateToReportRepair!();
          } else if (i == 5 && widget.onNavigateToProfile != null) {
            widget.onNavigateToProfile!();
          }
          // i == 4 คือหน้าปัจจุบัน (announce) ไม่ต้อง navigate
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
