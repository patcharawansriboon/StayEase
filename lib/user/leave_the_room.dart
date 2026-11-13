import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_sizes.dart';
class LeaveTheRoomScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onConfirmLeave;

  /// เรียกหลังส่งคำขอออกจากหอพักสำเร็จ (ผู้เช่าหลัก) → ไปหน้ารอแอดมินอนุมัติ
  final VoidCallback? onRequestLeave;

  /// true = ผู้ใช้เป็น Roommate, false = ผู้เช่าหลัก
  /// ใช้แยก logic การ cleanup เมื่อออกจากหอพัก
  final bool isRoommate;

  const LeaveTheRoomScreen({
    super.key,
    this.onBack,
    this.onConfirmLeave,
    this.onRequestLeave,
    this.isRoommate = false,
  });

  @override
  State<LeaveTheRoomScreen> createState() => _LeaveTheRoomScreenState();
}

class _LeaveTheRoomScreenState extends State<LeaveTheRoomScreen> {
  bool _isLoading = false;
  String _error = '';

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  Future<void> _handleLeave() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        if (widget.isRoommate) {
          // ── Roommate ออกจากหอพัก (ออกทันที ไม่ต้องรอแอดมิน) ──
          // ลบ dormitory_members ของ user นี้ (account ยังคงอยู่ใน auth.users)
          await Supabase.instance.client
              .from('dormitory_members')
              .delete()
              .eq('user_id', uid);

          // อัปเดต roommate_invites → left
          await Supabase.instance.client
              .from('roommate_invites')
              .update({'status': 'left', 'is_verified': false})
              .eq('id', uid);
        } else {
          // ── ผู้เช่าหลัก ออกจากหอพัก ──
          // ถ้ามีคำขอออกจากหอพักอยู่แล้ว → ไม่ต้องส่งซ้ำ
          final pendingLeave = await Supabase.instance.client
              .from('dormitory_members')
              .select('id')
              .eq('user_id', uid)
              .eq('member_type', 'leave')
              .eq('status', 'pending')
              .limit(1)
              .maybeSingle();

          if (pendingLeave != null) {
            _setError('คุณมีคำขอออกจากหอพักอยู่แล้ว กรุณารอการอนุมัติ');
            return;
          }

          // ส่งคำขอให้แอดมินอนุมัติก่อน (member_type = 'leave', status = 'pending')
          // ใช้แถวเดิมของผู้เช่าหลักเป็นคำขอ แล้ว snapshot ค่าเดิมไว้
          // เผื่อแอดมิน "ปฏิเสธ" → คืนสถานะผู้เช่าหลักเดิมกลับมา
          final member = await Supabase.instance.client
              .from('dormitory_members')
              .select('id, member_type, status, dormitory_id, room_id')
              .eq('user_id', uid)
              .eq('status', 'approved')
              .limit(1)
              .maybeSingle();

          if (member == null) {
            _setError('ไม่พบข้อมูลการเข้าพักของคุณในหอพัก');
            return;
          }

          await Supabase.instance.client
              .from('dormitory_members')
              .update({
                'status': 'pending',
                'member_type': 'leave',
                'prev_member_type':
                    member['member_type']?.toString() ?? 'tenant',
                'prev_dormitory_id': member['dormitory_id'],
                'prev_room_id': member['room_id'],
                'created_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', member['id']);
          print('✅ Leave request sent (member ${member['id']})');
        }
      }
    } catch (e) {
      print('❌ leave dorm error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'ส่งคำขอไม่สำเร็จ กรุณาลองอีกครั้ง';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (widget.isRoommate) {
      widget.onConfirmLeave?.call();
    } else {
      widget.onRequestLeave?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildHeader(),
            const Spacer(),
            SvgPicture.asset(
              'assets/images/door.svg',
              width: 240,
              height: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'คุณต้องการออกจากหอพักใช่หรือไม่?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isRoommate
                        ? 'หลังออกจากหอพักคุณจะไม่สามารถเข้าถึงข้อมูล\nของหอพักนี้ได้อีก'
                        : 'เมื่อกดยืนยัน ระบบจะส่งคำขอให้แอดมินอนุมัติก่อน\nเมื่ออนุมัติแล้วคุณจะออกจากหอพักทันที',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 15,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 13,
                        color: Color(0xFFFF0303),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // ออกจากหอพัก
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0303),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ออกจากหอพัก',
                              style: TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ยกเลิก
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F8FDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 16,
                          color: Color(0xFF4F8FDB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ออกจากหอพัก',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: kPageTitleFontSize,
              fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
