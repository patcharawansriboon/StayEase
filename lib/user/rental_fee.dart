import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/app_sizes.dart';
class RentalFeeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToPayment;
  final VoidCallback? onNavigateToPaymentHistory;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToProfile;
  final Map<String, dynamic> currentBill;
  final bool hasRoom;

  final List<Map<String, dynamic>> rentBreakdown;
  final bool showChatBadge;

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
    this.currentBill = const {},
    this.hasRoom = true,
    this.rentBreakdown = const [],
    this.showChatBadge = false,
  });

  @override
  State<RentalFeeScreen> createState() => _RentalFeeScreenState();
}

class _RentalFeeScreenState extends State<RentalFeeScreen> {
  int _selectedIndex = 1;
  bool _showDropdown = false;

  void _closeDropdown() {
    setState(() => _showDropdown = false);
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _showDropdown ? _closeDropdown : null,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: widget.hasRoom
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                       child: Column(
                         children: [
                           if (!_hasRealBill)
                             _buildNoBillEmptyState()
                           else if ((widget.currentBill['status']?.toString() ?? '') == 'paid')
                             _buildNoBillEmptyState()
                           else
                             _buildRentCard(),
                           const SizedBox(height: 24),
                        ],
                      ),
                    )
                  : _buildNoRoomEmptyState(),
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
      child: Column(
        children: [
          const Center(
            child: Text(
              'บิลของฉัน',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: kPageTitleFontSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuChips(),
        ],
      ),
    );
  }

  Widget _buildMenuChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip('บิลของฉัน', true, () => widget.onNavigateToRentalFee?.call()),
          const SizedBox(width: 8),
          _buildChip('ประวัติ', false, () => widget.onNavigateToPaymentHistory?.call()),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4181CB) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? const Color(0xFF4181CB) : const Color(0xFFDDE5EE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }

  bool get _hasRealBill {
    final id = widget.currentBill['id']?.toString();
    return id != null && id.isNotEmpty;
  }

  Widget _buildNoBillEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
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
            child: Center(
              child: SvgPicture.asset(
                'assets/images/invoice.svg',
                width: 52,
                height: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ยังไม่มีบิลค่าเช่าใหม่',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'รอแอดมินสร้างบิลรอบใหม่',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF9AA4B2),
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
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/invoice.svg',
                  width: 52,
                  height: 52,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่มีบิล',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'คุณยังไม่ได้เข้าร่วมห้องพักใด\nจึงยังไม่มีบิลค่าเช่า',
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

  // ---- Rent Card ----
  Widget _buildRentCard() {
    return GestureDetector(
      onTap: widget.onNavigateToBill,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCE9F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB7D6F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/icon_wallet.svg',
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentBill['month'] ?? 'กรกฎาคม 2569',
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.currentBill['total'] != null
                                ? '${widget.currentBill['total']}'
                                : '5,090',
                            style: const TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F8FDB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 5),
                            child: Text(
                              'บาท',
                              style: TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 15,
                                color: Color(0xFF8FB4E0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB7D6F5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Color(0xFF4F8FDB),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD54A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.currentBill['status_label'] ?? 'รอชำระ',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(width: 14),
                Container(width: 1, height: 18, color: const Color(0xFFB7CDEB)),
                const SizedBox(width: 14),
                const Icon(Icons.calendar_month_outlined,
                    size: 17, color: Color(0xFF4F8FDB)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'ครบกำหนด  ${widget.currentBill['due_date'] ?? '5 สิงหาคม 2569'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ],
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
            child: _wrapBadge(
              i,
              items[i] == null
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
        ),
      );
    });
  }

  /// ห่อไอคอนแชท (index 2) ด้วยจุดแดงถ้า showChatBadge
  Widget _wrapBadge(int index, Widget icon) {
    if (index != 2 || !widget.showChatBadge) return icon;
    return Stack(
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
              border: Border.all(color: const Color(0xFF4F8FDB), width: 1.5),
            ),
          ),
        ),
      ],
    );
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
                fontFamily: 'Noto Sans Thai',
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
