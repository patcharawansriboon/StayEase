import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class PendingRoomTransferScreen extends StatefulWidget {
  final VoidCallback? onApproved;
  final VoidCallback? onRejected;
  final VoidCallback? onBack;

  const PendingRoomTransferScreen({
    super.key,
    this.onApproved,
    this.onRejected,
    this.onBack,
  });

  @override
  State<PendingRoomTransferScreen> createState() =>
      _PendingRoomTransferScreenState();
}

class _PendingRoomTransferScreenState
    extends State<PendingRoomTransferScreen> {
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
      // poll record ล่าสุดของ user (ไม่ filter member_type เพราะ
      // คนที่ออกจากห้องแล้วสมัครใหม่จะเป็น tenant ไม่ใช่ upgrade)
      final row = await Supabase.instance.client
          .from('dormitory_members')
          .select('status')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final status = row?['status']?.toString() ?? 'pending';
      if (!mounted) return;
      if (status != _status) {
        setState(() => _status = status);
        // เมื่อ approved → หยุด poll แล้วแสดงหน้า success (ไม่ redirect ทันที)
        if (status == 'approved' || status == 'rejected') {
          _timer?.cancel();
        }
      }
    } catch (_) {}
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
      body: SafeArea(
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
              const Text(
                'ส่งคำขอย้ายห้องเรียบร้อย',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'หลังจากกรอกข้อมูลเพื่อส่งคำขอ\nกรุณารอแอดมินตรวจสอบและอนุมัติ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Prompt',
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
    );
  }

  // ---- หน้า success หลังอนุมัติ ----
  Widget _buildApprovedView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Success illustration
                    SvgPicture.asset(
                      'assets/images/smile.svg',
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => const SizedBox(
                        width: 240,
                        height: 240,
                        child: Icon(Icons.celebration,
                            size: 80, color: Color(0xFF4F8FDB)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'อนุมัติคำขอย้ายห้องเรียบร้อย',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'คุณสามารถเข้าใช้งานแอป\nโดยการเป็นผู้เช่าหลักได้แล้ว',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Prompt',
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
                      fontFamily: 'Prompt',
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
    );
  }

  // ---- หน้า rejected หลังปฏิเสธ ----
  Widget _buildRejectedView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Rejected illustration
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCE9E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 64,
                        color: Color(0xFFE05C5C),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ปฏิเสธคำขอย้ายห้อง',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Prompt',
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
                          fontFamily: 'Prompt',
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
                    backgroundColor: const Color(0xFFE05C5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'กลับหน้าตั้งค่า',
                    style: TextStyle(
                      fontFamily: 'Prompt',
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
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Prompt',
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
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
