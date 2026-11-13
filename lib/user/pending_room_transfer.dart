import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../widgets/sign_up_background.dart';

/// ประเภทคำขอที่กำลังรออนุมัติ
/// - [upgrade] = Roommate ยกระดับเป็นผู้เช่าหลัก (คำขอย้ายห้อง)
/// - [roommateJoin] = เข้าร่วมห้องด้วยรหัสเชิญ (คำขอเป็น Roommate)
/// - [leave] = ผู้เช่าหลักขอออกจากหอพัก
enum PendingRequestType { upgrade, roommateJoin, leave }

class PendingRoomTransferScreen extends StatefulWidget {
  final VoidCallback? onApproved;
  final VoidCallback? onRejected;
  final VoidCallback? onBack;
  final PendingRequestType requestType;

  const PendingRoomTransferScreen({
    super.key,
    this.onApproved,
    this.onRejected,
    this.onBack,
    this.requestType = PendingRequestType.upgrade,
  });

  @override
  State<PendingRoomTransferScreen> createState() =>
      _PendingRoomTransferScreenState();
}

class _PendingRoomTransferScreenState extends State<PendingRoomTransferScreen> {
  static const _pollInterval = Duration(seconds: 5);
  Timer? _timer;
  String _status = 'pending'; // pending | approved | rejected

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(_pollInterval, (_) => _checkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      // poll record ล่าสุดของ user (ดึง member_type มาด้วยเพื่อแยกผลลัพธ์
      // ของคำขอ upgrade — ดูหมายเหตุด้านล่าง)
      final row = await Supabase.instance.client
          .from('dormitory_members')
          .select('status, member_type')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final rawStatus = row?['status']?.toString() ?? 'pending';
      final memberType = row?['member_type']?.toString() ?? '';

      // แปลงเป็นผลลัพธ์ที่หน้าจอใช้ (pending | approved | rejected)
      //
      // กรณี upgrade เมื่อแอดมิน "ปฏิเสธ" โค้ดฝั่งแอดมินจะคืนแถวกลับเป็น
      // Roommate ห้องเดิม → status='approved' + member_type='roommate'
      // (ไม่ใช่ 'rejected' เพราะผู้ใช้ยังเป็นสมาชิกห้องเดิมอยู่จริง)
      // จึงต้องถือว่าเป็น "ปฏิเสธ" สำหรับหน้าจอนี้ ส่วนอนุมัติจะเป็น
      // status='approved' + member_type='tenant'
      String resolved;
      if (rawStatus == 'left') {
        // ถูกนำออกจากห้อง/หอพักแล้ว
        // - คำขอออกจากหอพัก → อนุมัติสำเร็จ
        // - คำขออื่น (เช่น เข้าร่วมห้อง) → ถูกนำออกจากห้อง = ไม่ได้รับอนุมัติ
        resolved = (widget.requestType == PendingRequestType.leave)
            ? 'approved'
            : 'rejected';
      } else if (widget.requestType == PendingRequestType.leave) {
        // คำขอออกจากหอพัก
        // - member_type = 'tenant' → คืนสถานะเดิม (ถูกปฏิเสธ) = ยังเป็นผู้เช่าหลัก
        if (rawStatus == 'pending') {
          resolved = 'pending';
        } else {
          resolved = 'rejected';
        }
      } else if (rawStatus == 'rejected') {
        resolved = 'rejected';
      } else if (rawStatus == 'approved') {
        if (widget.requestType == PendingRequestType.roommateJoin) {
          // คำขอเข้าร่วมห้อง: อนุมัติแล้วยังเป็น Roommate (member_type = roommate)
          resolved = (memberType == 'roommate') ? 'approved' : 'rejected';
        } else {
          // คำขอ upgrade: อนุมัติแล้วต้องเป็นผู้เช่าหลัก (member_type = tenant)
          resolved = (memberType == 'tenant') ? 'approved' : 'rejected';
        }
      } else {
        resolved = 'pending';
      }

      if (!mounted) return;
      if (resolved != _status) {
        setState(() => _status = resolved);
        // ถึงสถานะสุดท้ายแล้ว → หยุด poll (ไม่ redirect ทันที)
        if (resolved == 'approved' || resolved == 'rejected') {
          _timer?.cancel();
        }
      }
    } catch (_) {}
  }

  // ── ข้อความตามประเภทคำขอ ──
  String get _pendingTitle {
    switch (widget.requestType) {
      case PendingRequestType.roommateJoin:
        return 'ส่งคำขอเข้าร่วมห้องเรียบร้อย';
      case PendingRequestType.leave:
        return 'ส่งคำขอออกจากหอพักเรียบร้อย';
      case PendingRequestType.upgrade:
        return 'ส่งคำขอย้ายห้องเรียบร้อย';
    }
  }

  String get _pendingSubtitle {
    switch (widget.requestType) {
      case PendingRequestType.roommateJoin:
        return 'กรุณารอให้แอดมินตรวจสอบและอนุมัติ\nคุณจะเข้าร่วมห้องได้เมื่อแอดมินอนุมัติ';
      case PendingRequestType.leave:
        return 'กรุณารอให้แอดมินตรวจสอบและอนุมัติ\nคุณจะออกจากหอพักเมื่อแอดมินอนุมัติ';
      case PendingRequestType.upgrade:
        return 'หลังจากกรอกข้อมูลเพื่อส่งคำขอ\nกรุณารอแอดมินตรวจสอบและอนุมัติ';
    }
  }

  String get _approvedTitle {
    switch (widget.requestType) {
      case PendingRequestType.roommateJoin:
        return 'อนุมัติคำขอเข้าร่วมห้องเรียบร้อย';
      case PendingRequestType.leave:
        return 'อนุมัติคำขอออกจากหอพักเรียบร้อย';
      case PendingRequestType.upgrade:
        return 'อนุมัติคำขอย้ายห้องเรียบร้อย';
    }
  }

  String get _approvedSubtitle {
    switch (widget.requestType) {
      case PendingRequestType.roommateJoin:
        return 'คุณสามารถเข้าร่วมห้องพักได้แล้ว\nในฐานะ Roommate ของห้องนั้น';
      case PendingRequestType.leave:
        return 'คุณออกจากหอพักเรียบร้อยแล้ว\nRoommate ในห้องของคุณถูกนำออกจากห้องด้วย';
      case PendingRequestType.upgrade:
        return 'คุณสามารถเข้าใช้งานแอป\nโดยการเป็นผู้เช่าหลักได้แล้ว';
    }
  }

  String get _rejectedTitle {
    switch (widget.requestType) {
      case PendingRequestType.roommateJoin:
        return 'ปฏิเสธคำขอเข้าร่วมห้อง';
      case PendingRequestType.leave:
        return 'ปฏิเสธคำขอออกจากหอพัก';
      case PendingRequestType.upgrade:
        return 'ปฏิเสธคำขอย้ายห้อง';
    }
  }

  String get _backButtonLabel {
    switch (widget.requestType) {
      case PendingRequestType.roommateJoin:
      case PendingRequestType.leave:
        return 'กลับหน้าหลัก';
      case PendingRequestType.upgrade:
        return 'กลับหน้าตั้งค่า';
    }
  }

  @override
  Widget build(BuildContext context) {
    // เมื่ออนุมัติแล้ว → แสดงหน้า success พร้อมปุ่ม "เริ่มใช้งาน"
    if (_status == 'approved') {
      return _buildApprovedView();
    }
    // เมื่อปฏิเสธ → แสดงหน้า rejected พร้อมปุ่ม "กลับหน้าตั้งค่า"
    if (_status == 'rejected') {
      return _buildRejectedView();
    }
    // ยังรออยู่ → แสดงหน้ารออนุมัติ
    return Scaffold(
      backgroundColor: Colors.white,
      body: _withBackground(
        SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Illustration
                SvgPicture.asset(
                  'assets/images/pending.svg',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  _pendingTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _pendingSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      color: Color(0xFF888888),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Status indicator
                _buildStatusRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// พื้นหลังเดียวกับหน้า already_approved: ขาวล้วน + วงกลมขอบคลื่น 2 วง
  Widget _withBackground(Widget child) {
    return SignUpBackground(
      minimal: true,
      solidColor: Colors.white,
      child: child,
    );
  }

  // ---- หน้า success หลังอนุมัติ ----
  Widget _buildApprovedView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _withBackground(
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Success illustration
                      Image.asset(
                        'assets/images/pass.png',
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _approvedTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _approvedSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Color(0xFF888888),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ปุ่มเริ่มใช้งาน
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.onApproved,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8FDB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'เริ่มใช้งาน',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 16,
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

  // ---- หน้า rejected หลังปฏิเสธ ----
  Widget _buildRejectedView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _withBackground(
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Rejected illustration
                      SvgPicture.asset(
                        'assets/images/reject.svg',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _rejectedTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'แอดมินไม่อนุมัติคำขอของคุณ\nสามารถยื่นคำขอใหม่ได้อีกครั้ง',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Color(0xFF888888),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ปุ่มกลับหน้าตั้งค่า
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.onRejected,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0303),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _backButtonLabel,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 16,
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

  Widget _buildStatusRow() {
    final isApproved = _status == 'approved';
    final isRejected = _status == 'rejected';

    Color dotColor;
    String label;

    if (isApproved) {
      dotColor = const Color(0xFF4CAF50);
      label = 'อนุมัติแล้ว';
    } else if (isRejected) {
      dotColor = const Color(0xFFE05C5C);
      label = 'ไม่ได้รับอนุมัติ';
    } else {
      dotColor = const Color(0xFFBBBBBB);
      label = 'รออนุมัติ';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // animated dot for pending
        if (!isApproved && !isRejected)
          _PulsingDot(color: dotColor)
        else
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 15,
            color: dotColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// วงกลมกระพริบสำหรับสถานะ pending
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
