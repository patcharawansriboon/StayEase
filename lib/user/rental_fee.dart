import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RentalFeeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToPayment;
  final VoidCallback? onNavigateToPaymentHistory;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToProfile;

  const RentalFeeScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToRentalFee,
    this.onNavigateToBill,
    this.onNavigateToPayment,
    this.onNavigateToPaymentHistory,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onNavigateToProfile,
  });

  @override
  State<RentalFeeScreen> createState() => _RentalFeeScreenState();
}

class _RentalFeeScreenState extends State<RentalFeeScreen> {
  int _selectedIndex = 1;
  bool _showDropdown = false;

  void _toggleDropdown() {
    setState(() => _showDropdown = !_showDropdown);
  }

  void _closeDropdown() {
    setState(() => _showDropdown = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _showDropdown ? _closeDropdown : null,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Container(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    _buildRentCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
            // Dropdown overlay
            if (_showDropdown)
              Positioned(
                top: 96,
                right: 16,
                child: _buildDropdownMenu(),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Header ----
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'บิลของฉัน',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(13.5),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDot(),
                      const SizedBox(width: 3),
                      _buildDot(),
                      const SizedBox(width: 3),
                      _buildDot(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
              color: const Color(0xFF78A2D2),
            ),
            // White bottom section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 43,
                color: Colors.white,
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
                          const Text(
                            'กรกฎาคม 2569',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                '5,090',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFEFFAF),
                                ),
                              ),
                              SizedBox(width: 7),
                              Padding(
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
                      const Text(
                        'รอชำระ',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                          width: 1,
                          height: 16,
                          color: const Color(0xFFD9D9D9)),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_outlined,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text(
                        'ครบกำหนด  5 สิงหาคม 2569',
                        style: TextStyle(
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
                            border: Border.all(
                                color: const Color(0xFF78A2D2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'รายละเอียด',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 10,
                                color: Color(0xFF78A2D2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: widget.onNavigateToPayment,
                        child: Container(
                          width: 70,
                          height: 23,
                          decoration: BoxDecoration(
                            color: const Color(0xFF78A2D2),
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
                  ),
                ],
              ),
            ),
          ],
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
            // Active indicator
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

  Widget _buildDropdownMenu() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // บิลของฉัน
          _DropdownItem(
            icon: Icons.receipt_long_outlined,
            label: 'บิลของฉัน',
            onTap: () {
              _closeDropdown();
              widget.onNavigateToRentalFee?.call();
            },
          ),
          // Divider
          const Divider(
              height: 1, indent: 20, endIndent: 20, color: Color(0xFFF0F0F0)),
          // ประวัติการชำระ
          _DropdownItem(
            icon: Icons.history,
            label: 'ประวัติการชำระ',
            onTap: () {
              _closeDropdown();
              widget.onNavigateToPaymentHistory?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        shape: BoxShape.circle,
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
          } else if (i == 3 && widget.onNavigateToAnnounce != null) {
            widget.onNavigateToAnnounce!();
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

class _DropdownItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _pressed ? const Color(0xFF000000) : const Color(0xFFAAAAAA);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(widget.icon, size: 28, color: color),
            const SizedBox(width: 16),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
