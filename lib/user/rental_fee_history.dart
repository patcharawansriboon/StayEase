import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/mock_service.dart';
import '../widgets/user_bottom_nav.dart';

import '../widgets/app_sizes.dart';

/// GlobalKey เพื่อให้ main.dart เรียก reload() ได้
class PaymentHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToRentalFee;
  final void Function(Map<String, dynamic> bill)? onNavigateToBill;
  final VoidCallback? onNavigateToBillHistory;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onNavigateToProfile;
  final bool showChatBadge;

  const PaymentHistoryScreen({
    super.key,
    this.onBack,
    this.onNavigateToHome,
    this.onNavigateToRentalFee,
    this.onNavigateToBill,
    this.onNavigateToBillHistory,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onNavigateToProfile,
    this.showChatBadge = false,
  });

  @override
  State<PaymentHistoryScreen> createState() => PaymentHistoryScreenState();
}

class PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// เรียกจาก main.dart ผ่าน GlobalKey ทุกครั้งที่ navigate มาหน้านี้
  void reload() {
    if (!mounted) return;
    setState(() => _loading = true);
    _load();
  }

  Future<void> _load() async {
    final data = await mockService.getBillHistory();
    if (!mounted) return;
    setState(() {
      _history = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
                    ...(_loading
                        ? [const Center(child: CircularProgressIndicator())]
                        : _history.isEmpty
                            ? [_buildEmptyState()]
                            : _history.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: () => widget.onNavigateToBill?.call(item),
                                    child: _buildHistoryCard(item),
                                  ),
                                ))),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
        ],
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
              'ประวัติ',
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

  // ---- เมนูชิปใต้หัวข้อ (บิลของฉัน / ประวัติ) ----
  Widget _buildMenuChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip(
            'บิลของฉัน',
            false,
            () => widget.onNavigateToRentalFee?.call(),
          ),
          const SizedBox(width: 8),
          _buildChip('ประวัติ', true, () {}),
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

  // ---- Empty State ----
  Widget _buildEmptyState() {
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
            'ยังไม่มีประวัติการชำระ',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ประวัติการชำระบิลจะแสดงที่นี่',
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

  // ---- History Card ----
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    return Container(
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
                      item['month']?.toString() ?? '',
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
                          item['total']?.toString() ?? '',
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(0xFFE3F0FD),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF4F8FDB),
                    size: 20,
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
                  color: Color(0xFF7ED321),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ชำระแล้ว',
                style: TextStyle(
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
                  item['paid_date']?.toString() ?? '',
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
    );
  }

  // ---- Bottom Navigation ----
  Widget _buildBottomNav() {
    // ใช้แถบเมนูล่างตัวเดียวกับหน้าหลักอื่น (ขนาด/ไอคอน/การกดเหมือนกัน)
    // หน้านี้เป็นส่วนของแท็บ "บิล/ค่าเช่า" (index 1)
    return UserBottomNav(
      selectedIndex: 1,
      onHome: widget.onNavigateToHome,
      onBill: widget.onNavigateToRentalFee,
      onChat: widget.onNavigateToChat,
      onAnnounce: widget.onNavigateToAnnounce,
      onProfile: widget.onNavigateToProfile,
      showChatBadge: widget.showChatBadge,
    );
  }
}
