import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToBill;
  final VoidCallback? onNavigateToBillHistory;

  const PaymentHistoryScreen({
    super.key,
    this.onBack,
    this.onNavigateToHome,
    this.onNavigateToRentalFee,
    this.onNavigateToBill,
    this.onNavigateToBillHistory,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int _selectedIndex = 1;
  bool _showDropdown = false;

  void _toggleDropdown() => setState(() => _showDropdown = !_showDropdown);
  void _closeDropdown() => setState(() => _showDropdown = false);

  final List<Map<String, String>> _history = [
    {
      'month': 'กรกฎาคม 2569',
      'amount': '5,090',
      'date': 'ชำระเมื่อ  5 สิงหาคม 2569',
    },
    {
      'month': 'มิถุนายน 2569',
      'amount': '5,090',
      'date': 'ชำระเมื่อ  5 สิงหาคม 2569',
    },
  ];

  @override
  Widget build(BuildContext context) {
return Scaffold(
      backgroundColor: Colors.white,
      body:GestureDetector(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    ..._history.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildHistoryCard(item),
                        )),
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
      child: Row(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'ประวัติ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(13.5),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: GestureDetector(
              onTap: _toggleDropdown,
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
        ],
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
          _HistoryDropdownItem(
            icon: Icons.receipt_long_outlined,
            label: 'บิลของฉัน',
            onTap: () {
              _closeDropdown();
              widget.onNavigateToRentalFee?.call();
            },
          ),
          const Divider(
              height: 1, indent: 20, endIndent: 20, color: Color(0xFFF0F0F0)),
          // ประวัติการชำระ
          _HistoryDropdownItem(
            icon: Icons.history,
            label: 'ประวัติการชำระ',
            onTap: () {
              _closeDropdown();
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

  // ---- History Card ----
  Widget _buildHistoryCard(Map<String, String> item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Blue top section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              color: const Color(0xFF4F8FDB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet icon + month + amount
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['month']!,
                            style: const TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item['amount']!,
                                style: const TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFEFFAF),
                                ),
                              ),
                              const SizedBox(width: 6),
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
                  const SizedBox(height: 10),
                  // Status row
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7ED321),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ชำระแล้ว',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                          width: 1,
                          height: 14,
                          color: const Color(0xFFD9D9D9)),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_outlined,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        item['date']!,
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // White bottom section
            // White bottom section
            GestureDetector(
              onTap: () => widget.onNavigateToBillHistory?.call(),
              child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.white,
              child: Row(
                children: const [
                  Icon(Icons.qr_code_2, size: 20, color: Color(0xFF000000)),
                  SizedBox(width: 8),
                  Text(
                    'QR Code PromptPay',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 12,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
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
                children: _buildNavItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/icon_bill.svg',
      2: 'assets/images/icon_message.svg',
      3: 'assets/images/icon_announcement.svg',
      4: 'assets/images/icon_user.svg',
    };

    return List.generate(5, (i) {
      final isActive = i == _selectedIndex;
      final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
      return GestureDetector(
        onTap: () {
          if (i == 0 && widget.onNavigateToHome != null) {
            widget.onNavigateToHome!();
          } else if (i == 1 && widget.onNavigateToRentalFee != null) {
            widget.onNavigateToRentalFee!();
          } else {
            setState(() => _selectedIndex = i);
          }
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SvgPicture.asset(
              svgPaths[i]!,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      );
    });
  }
}

class _HistoryDropdownItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HistoryDropdownItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HistoryDropdownItem> createState() => _HistoryDropdownItemState();
}

class _HistoryDropdownItemState extends State<_HistoryDropdownItem> {
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
