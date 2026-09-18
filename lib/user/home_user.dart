import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeUserScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToPayment;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToRepairDetail;
  final ValueChanged<String>? onNavigateToAnnounceDetails;
  final VoidCallback? onNavigateToProfile;
  final bool isRoommate;
  final String userName;
  final String userPhone;
  final String roomNumber;
  final Map<String, dynamic> currentBill;
  final List<Map<String, String>> announcements;

  const HomeUserScreen({
    super.key,
    this.onNavigateToRentalFee,
    this.onNavigateToBill,
    this.onNavigateToPayment,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onNavigateToRepairDetail,
    this.onNavigateToAnnounceDetails,
    this.onNavigateToProfile,
    this.isRoommate = false,
    this.userName = 'พัชราวรรณ  ศรีบุญ',
    this.userPhone = '099-9999999',
    this.roomNumber = 'A303',
    this.currentBill = const {},
    this.announcements = const [],
  });

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(HomeUserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // รีเซ็ต indicator กลับที่ home เมื่อ navigate กลับมาหน้านี้
    if (_selectedIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('ค่าเช่าเดือนนี้'),
                    const SizedBox(height: 10),
                    _buildRentCard(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('แจ้งซ่อม'),
                    const SizedBox(height: 10),
                    _buildRepairCard(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('ประกาศล่าสุด'),
                    const SizedBox(height: 10),
                    _buildAnnouncementRow(),
                    const SizedBox(height: 24),
                  ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          // Avatar
          ClipOval(
            child: Image.asset(
              'assets/images/user_avatar.png',
              width: 45,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 45,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: const Icon(Icons.person, size: 28, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 11),

          // Name & Room
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName.isNotEmpty ? widget.userName : 'พัชราวรรณ  ศรีบุญ',
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ห้อง ${widget.roomNumber}',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),

          // Bell icon
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF4F8FDB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Section Label ----
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  // ---- Rent Card ----
  Widget _buildRentCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Blue background
            Container(
              height: 140,
              color: const Color(0xFF4F8FDB),
            ),
            // Wave / bottom decoration
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 43,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: wallet + amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Wallet icon box
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/icon_wallet.svg',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentBill['month'] ?? 'กรกฎาคม 2569',
                            style: const TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.currentBill['total'] != null
                                    ? '${widget.currentBill['total']}'
                                    : '5,090',
                                style: const TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFEFFAF),
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 2),
                                child: Text(
                                  'บาท',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 13,
                                    color: Color(0xFFFEFFAF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Status row
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFF57B39)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.currentBill['status_label'] ?? 'รอชำระ',
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 16, color: const Color(0xFFD9D9D9)),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_outlined,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'ครบกำหนด  ${widget.currentBill['due_date'] ?? '5 สิงหาคม 2569'}',
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: widget.onNavigateToBill,
                        child: Container(
                          width: 70,
                          height: 23,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF4F8FDB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'รายละเอียด',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 10,
                                color: Color(0xFF4F8FDB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pay button (ซ่อนเมื่อเป็น roommate)
                      if (!widget.isRoommate) ...[
                        const SizedBox(width: 30),
                        GestureDetector(
                          onTap: widget.onNavigateToPayment,
                          child: Container(
                            width: 70,
                            height: 23,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F8FDB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'ชำระเงิน',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Repair Card ----
  Widget _buildRepairCard() {
    return Container(
      width: double.infinity,
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Divider line at 77px from top
          Positioned(
            top: 77,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFFD9D9D9)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + title + room
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Color(0xFFF57B39)],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'กำลังดำเนินการ',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 12,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เครื่องปรับอากาศไม่เย็น',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ห้อง A303',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        color: Color(0xFF70766E),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Date + detail button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_month_outlined,
                            size: 13, color: Color(0xFF70766E)),
                        SizedBox(width: 6),
                        Text(
                          '28 ก.ค 2569',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 12,
                            color: Color(0xFF70766E),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '09:30',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 12,
                            color: Color(0xFF70766E),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 75,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8FDB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: widget.onNavigateToRepairDetail,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'รายละเอียด',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right,
                                size: 10, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Announcement Row ----
  Widget _buildAnnouncementRow() {
    return Row(
      children: [
        Expanded(
          child: _buildAnnouncementCard('assets/images/announcement_1.png'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnnouncementCard('assets/images/announcement_2.png'),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(String imagePath) {
    return GestureDetector(
      onTap: () => widget.onNavigateToAnnounceDetails?.call(imagePath),
      child: Container(
        height: 121,
        width: 162,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF5F5F5),
              child: const Center(
                child: Icon(Icons.image_outlined,
                    size: 40, color: Color(0xFFCCCCCC)),
              ),
            ),
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
              left: 11.6667 + _selectedIndex * 53.1667,
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
            // Icons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildBottomNavItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBottomNavItems() {
    final items = <IconData?>[
      null, // index 0 ใช้ icon_home.svg
      null, // index 1 ใช้ icon_bill.svg
      null, // index 2 ใช้ icon_message.svg
      null, // index 3 ใช้ icon_announcement.svg
      null, // index 4 ใช้ icon_user.svg
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
      final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
      return GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = i);
          if (i == 1 && widget.onNavigateToRentalFee != null) {
            widget.onNavigateToRentalFee!();
          } else if (i == 2 && widget.onNavigateToChat != null) {
            widget.onNavigateToChat!();
          } else if (i == 3 && widget.onNavigateToAnnounce != null) {
            widget.onNavigateToAnnounce!();
          } else if (i == 4 && widget.onNavigateToProfile != null) {
            widget.onNavigateToProfile!();
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
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(
                    items[i],
                    color: color,
                    size: 22,
                  ),
          ),
        ),
      );
    });
  }
}
