import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveTheRoomScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onConfirmLeave;

  const LeaveTheRoomScreen({
    super.key,
    this.onBack,
    this.onConfirmLeave,
  });

  @override
  State<LeaveTheRoomScreen> createState() => _LeaveTheRoomScreenState();
}

class _LeaveTheRoomScreenState extends State<LeaveTheRoomScreen> {
  bool _isLoading = false;

  Future<void> _handleLeave() async {
    setState(() => _isLoading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        // ลบ dormitory_members ทั้งหมดของ user นี้
        await Supabase.instance.client
            .from('dormitory_members')
            .delete()
            .eq('user_id', uid);

        // อัปเดต roommate_invites status เป็น left
        await Supabase.instance.client
            .from('roommate_invites')
            .update({'status': 'left', 'is_verified': false})
            .eq('id', uid);
      }
    } catch (e) {
      print('❌ leave room error: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onConfirmLeave?.call();
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
            const Spacer(),
            // Message
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'คุณต้องการออกจากห้อง A301 ใช่หรือไม่?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'หลังออกจากห้องคุณจะไม่สามารถเข้าถึงข้อมูล\nของห้องนี้ได้อีก',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // ยืนยันออกจากห้อง
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF16C6C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'ยืนยันออกจากห้อง',
                              style: TextStyle(
                                fontFamily: 'Prompt',
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
                          fontFamily: 'Prompt',
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
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ออกจากห้อง',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
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
