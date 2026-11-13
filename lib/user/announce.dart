import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/mock_service.dart';
import '../widgets/user_bottom_nav.dart';

class AnnounceScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final ValueChanged<Map<String, String>>? onNavigateToDetails;
  final VoidCallback? onNavigateToProfile;
  final List<Map<String, String>> announcements;
  final bool isAdmin;
  final bool hasRoom;
  final VoidCallback? onAddAnnouncement;
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToReportRepair;
  final bool showChatBadge;

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
    this.showChatBadge = false,
  });

  @override
  State<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends State<AnnounceScreen> {
  /// ตำแหน่งแท็บ "ประกาศ" (icon_announcement) ในแถบเมนูล่าง
  static const int _announceTabIndex = 3;
  final _mockService = MockService();

  List<Map<String, String>> _announcements = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, String>>>? _announceSub;

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
      // ยกเลิก subscription เก่าถ้ามี
      await _announceSub?.cancel();

      String? status = 'published';
      String? dormId;
      if (widget.isAdmin) {
        dormId = await _mockService.getAdminDormitoryId();
      }

      _announceSub = _mockService
          .announcementsStream(dormitoryId: dormId, status: status)
          .listen((rows) {
        if (!mounted) return;
        setState(() {
          _announcements = rows;
          _loading = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _announcements = [];
        _loading = false;
      });
    }
  }

  List<Map<String, String>> get _displayAnnouncements =>
      widget.announcements.isNotEmpty ? widget.announcements : _announcements;

  @override
  void dispose() {
    _announceSub?.cancel();
    super.dispose();
  }

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
              child: (!widget.isAdmin && !widget.hasRoom)
                  ? _buildNoRoomEmptyState()
              : (_loading && widget.announcements.isEmpty)
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

  // ---- Header (แอดมินและผู้เช่าใช้รูปแบบเดียวกัน แต่แอดมินมีปุ่มเพิ่มประกาศ) ----
  Widget _buildHeader() {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'ประกาศ',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        SizedBox(height: 2),
        Text(
          'ข่าวสารและข้อมูลสำคัญจากหอพัก',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 13,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/megaphone.svg',
            width: 40,
            height: 40,
            placeholderBuilder: (_) => const Icon(Icons.campaign,
                size: 36, color: Color(0xFF4F8FDB)),
          ),
          const SizedBox(width: 12),
          Expanded(child: titleColumn),
          // ปุ่มเพิ่มประกาศอยู่ที่เดิม (มุมขวาของส่วนหัว)
          if (widget.isAdmin)
            GestureDetector(
              onTap: widget.onAddAnnouncement,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8FDB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'ประกาศ',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
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
                fontFamily: 'Noto Sans Thai',
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
                fontFamily: 'Noto Sans Thai',
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
                fontFamily: 'Noto Sans Thai',
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

  // ---- Announcement Card ----
  Widget _buildAnnouncementCard(Map<String, String> item) {
    // แอดมินและผู้เช่าใช้การ์ดเดียวกัน (พื้นเหลือง)
    return _buildTenantCard(item);
  }

  // ---- การ์ดผู้เช่า: พื้นเหลือง + title + วันที่ + รูป + ลูกศร ----
  Widget _buildTenantCard(Map<String, String> item) {
    final title = item['title'] ?? '';
    final date  = item['date'] ?? '';

    return GestureDetector(
      onTap: () => widget.onNavigateToDetails?.call(item),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6), // พื้นเหลืองอ่อน
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCE9A8)),
        ),
        child: Row(
          children: [
            // ซ้าย: title + วันที่
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : 'ประกาศ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 15, color: Color(0xFF888888)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 13,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // กลาง: รูป proclaim (ไม่มีกรอบ)
            Image.asset(
              'assets/images/proclaim.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.campaign,
                  size: 60, color: Color(0xFFE6A700)),
            ),
            const SizedBox(width: 8),
            // ขวา: ปุ่มลูกศร
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFBFD9F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF4F8FDB)),
            ),
          ],
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
    // แถบเมนูล่างตัวเดียวกับทุกหน้าหลัก (วงกลมสีเหลืองอยู่ที่ไอคอนประกาศ)
    return UserBottomNav(
      selectedIndex: _announceTabIndex,
      onHome: widget.onNavigateToHome,
      onBill: widget.onNavigateToRentalFee,
      onChat: widget.onNavigateToReportRepair ?? widget.onNavigateToChat,
      onProfile: widget.onNavigateToProfile,
      showChatBadge: widget.showChatBadge,
    );
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

      Widget iconWidget = svgPaths.containsKey(i)
          ? SvgPicture.asset(
              svgPaths[i]!,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          : Icon(materialIcons[i], size: 22, color: iconColor);

      // badge จุดแดงที่ไอคอนแจ้งซ่อม (index 3) — ฝั่งแอดมินใช้ showChatBadge เป็น repair badge
      if (i == 3 && widget.showChatBadge) {
        iconWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            Positioned(
              right: -3,
              top: -3,
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
        );
      }

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
