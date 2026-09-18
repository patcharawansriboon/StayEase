import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BillHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToProfile;
  final List<Map<String, dynamic>> billHistory;

  const BillHistoryScreen({
    super.key,
    this.onBack,
    this.onNavigateToHome,
    this.onNavigateToRentalFee,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onNavigateToProfile,
    this.billHistory = const [],
  });

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  int _selectedIndex = 1;

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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _buildBillCard(),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard() {
    final history = widget.billHistory.isNotEmpty
        ? widget.billHistory
        : [
            {'month': 'กรกฎาคม 2569', 'rent': 4500, 'electricity': 320, 'water': 270, 'penalty': 0, 'total': 5090, 'due_date': '5 สิงหาคม 2569', 'status': 'paid'},
          ];
    final bill = history.first;
    final rent      = bill['rent']        ?? 0;
    final elec      = bill['electricity'] ?? 0;
    final water     = bill['water']       ?? 0;
    final penalty   = bill['penalty']     ?? 0;
    final total     = bill['total']       ?? 0;
    final month     = bill['month']       ?? '';
    final dueDate   = bill['due_date']    ?? '';

    return Column(
      children: [
        for (int idx = 0; idx < history.length; idx++) ...[
          if (idx > 0) const SizedBox(height: 16),
          _buildSingleBillCard(history[idx]),
        ],
      ],
    );
  }

  Widget _buildSingleBillCard(Map<String, dynamic> bill) {
    final rent    = bill['rent']        ?? 0;
    final elec    = bill['electricity'] ?? 0;
    final water   = bill['water']       ?? 0;
    final penalty = bill['penalty']     ?? 0;
    final total   = bill['total']       ?? 0;
    final month   = bill['month']       ?? '';
    final dueDate = bill['due_date']    ?? '';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF4F8FDB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            children: [
              const Text(
                'บิลประจำเดือน',
                style: TextStyle(fontFamily: 'Prompt', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFEFFAF)),
              ),
              const SizedBox(height: 4),
              Text(month, style: const TextStyle(fontFamily: 'Prompt', fontSize: 12, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildBillRow('ค่าเช่าห้อง', '$rent.00'),
                const SizedBox(height: 12),
                _buildBillRow('ค่าไฟ', '$elec.00'),
                const SizedBox(height: 12),
                _buildBillRow('ค่าน้ำ', '$water.00'),
                const SizedBox(height: 12),
                _buildBillRow('ค่าปรับ / อื่นๆ', penalty > 0 ? '$penalty.00' : '00.00'),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFD9D9D9)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('รวมทั้งหมด',
                        style: TextStyle(fontFamily: 'Prompt', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF000000))),
                    Row(
                      children: [
                        Text('$total.00',
                            style: const TextStyle(fontFamily: 'Prompt', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF000000))),
                        const SizedBox(width: 8),
                        const Text('บาท',
                            style: TextStyle(fontFamily: 'Prompt', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF000000))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 0.5, color: const Color(0xFFD9D9D9)),
                const SizedBox(height: 12),
                _buildInfoRow('ครบกำหนด', dueDate.isNotEmpty ? dueDate : '5 สิงหาคม 2569'),
                const SizedBox(height: 8),
                _buildInfoRow('ช่องทางการชำระ', 'QR Code (PromptPay)'),
                const SizedBox(height: 8),
                _buildInfoRow('Ref', '910123456789'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String amount) {
    const style = TextStyle(fontFamily: 'Prompt', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF000000));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Row(
          children: [
            Text(amount, style: style),
            const SizedBox(width: 8),
            const Text('บาท', style: style),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    const style = TextStyle(
      fontFamily: 'Prompt',
      fontSize: 10,
      color: Color(0xFF000000),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
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
