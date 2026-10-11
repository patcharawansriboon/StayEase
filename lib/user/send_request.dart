import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'already_approved.dart';

class SendRequestScreen extends StatefulWidget {
  /// uid ของผู้เช่าที่สมัคร (เก็บไว้ตอนสมัคร เพื่อไม่ให้พึ่ง session ปัจจุบัน)
  final String? userId;

  /// เรียกเมื่อผู้เช่าได้รับการอนุมัติ (กดปุ่ม "เข้าสู่แอป")
  final VoidCallback onApproved;

  /// เรียกเมื่อผู้เช่าได้รับการปฏิเสธ (กดปุ่ม "กลับหน้าสมัคร")
  final VoidCallback onRejected;

  const SendRequestScreen({
    super.key,
    this.userId,
    required this.onApproved,
    required this.onRejected,
  });

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  String? _status;
  bool _isChecking = true;

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

  /// ดึงสถานะคำขอของผู้เช่าคนนี้ (pending / approved / rejected)
  Future<void> _checkStatus() async {
    final uid = widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      print('⚠️ send_request: ไม่พบ uid ของผู้เช่า');
      _stopPolling();
      return;
    }

    try {
      // ดู record pending ล่าสุดของ user นี้ก่อน
      // ถ้าไม่มี pending → ดู record ล่าสุดทั้งหมด
      final pendingRow = await Supabase.instance.client
          .from('dormitory_members')
          .select('id, status')
          .eq('user_id', uid)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (pendingRow != null) {
        // ยังมี pending อยู่ → รอต่อ
        if (mounted) setState(() => _isChecking = false);
        return;
      }

      // ไม่มี pending → ดู record ล่าสุด
      final latestRow = await Supabase.instance.client
          .from('dormitory_members')
          .select('id, status')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final status = latestRow?['status']?.toString();

      if (!mounted) return;

      if (status == 'approved' || status == 'rejected') {
        _stopPolling();
        setState(() {
          _status = status;
          _isChecking = false;
        });
        return;
      }

      if (mounted) setState(() => _isChecking = false);
    } catch (e) {
      print('❌ check request status error: $e');
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    // แอดมินอนุมัติ/ปฏิเสธแล้ว → เปลี่ยนหน้าอัตโนมัติ
    if (status == 'approved') {
      return AlreadyApprovedScreen(
        result: ApprovalResult.approved,
        onPressed: widget.onApproved,
      );
    }
    if (status == 'rejected') {
      return AlreadyApprovedScreen(
        result: ApprovalResult.rejected,
        onPressed: widget.onRejected,
      );
    }

    // ยังรออยู่ → ค้างที่หน้านี้
    return Column(
      children: [
        // ---- Illustration ----
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SvgPicture.asset(
                'assets/images/time.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // ---- กรอบสีน้ำเงิน ----
        // ใช้ minHeight แทนความสูงตายตัว กันข้อความยาวแล้วล้นกรอบ
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 322),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFBCDEFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ส่งคำขอเรียบร้อยแล้ว',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFEFFAF),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'หลังจากกรอกข้อมูลเพื่อส่งคำขอเข้าหอพัก\nระบบส่งคำขอกรุณารอแอดมินตรวจสอบและอนุมัติ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF5B93D4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isChecking ? 'กำลังตรวจสอบสถานะ...' : 'รอการอนุมัติ',
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
