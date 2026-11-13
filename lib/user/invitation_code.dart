import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/room_members_service.dart';
import 'dart:math';

import '../widgets/app_sizes.dart';
class InvitationCodeScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const InvitationCodeScreen({super.key, this.onBack});

  @override
  State<InvitationCodeScreen> createState() => InvitationCodeScreenState();
}

class InvitationCodeScreenState extends State<InvitationCodeScreen> {
  String? _code;
  String _roomNumber = '-';
  String _dormName = '-';
  bool _isLoading = true;
  bool _isGenerating = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  /// เรียกจากภายนอกเมื่อกลับมาที่หน้านี้
  /// จำเป็นเพราะหน้านี้อยู่ใน IndexedStack → initState ทำงานครั้งเดียวตอนแอปเริ่ม
  /// ถ้าตอนนั้นยังไม่ได้ล็อกอิน หน้าจอจะค้างที่ error และไม่โหลดใหม่เอง
  void reload() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isGenerating = false;
      _error = '';
      _code = null;
    });
    _loadCode();
  }

  /// หาหอพัก/ห้องของผู้เช่าหลักคนนี้ (จาก dormitory_members ที่อนุมัติแล้ว)
  /// คืน null ถ้าไม่ได้เป็นสมาชิกที่อนุมัติ
  Future<Map<String, dynamic>?> _loadOwnMembership() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return null;

    final row = await Supabase.instance.client
        .from('dormitory_members')
        // หมายเหตุ: dormitories() ไม่มีคอลัมน์ dormitory_id (อยู่ที่ dormitory_members)
        // เลือกที่นี่นอกวงเล็บแล้ว
        .select('id, dormitory_id, room_id, dormitories!dormitory_members_dormitory_id_fkey(dorm_name, dorm_code)')
        .eq('user_id', uid)
        .eq('status', 'approved')
        .limit(1)
        .maybeSingle();

    return row;
  }

  /// โหลดรหัสเชิญที่มีอยู่แล้วของผู้เช่าหลักคนนี้ (ถ้ายังไม่มีจะสร้างใหม่)
  Future<void> _loadCode() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'ยังไม่ได้เข้าสู่ระบบ กรุณาล็อกอินใหม่';
        });
        return;
      }

      final membership = await _loadOwnMembership();
      if (membership == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'ไม่พบข้อมูลการเข้าพักของคุณ';
        });
        return;
      }

      final dorm = membership['dormitories'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _roomNumber = (dorm?['dorm_code'] ?? '-').toString();
        _dormName = (dorm?['dorm_name'] ?? '-').toString();
      });
      final existing = await Supabase.instance.client
          .from('invitation_codes')
          .select('code')
          .eq('created_by', uid)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _code = existing?['code']?.toString();
        _isLoading = false;
      });

      // ยังไม่มีรหัส → สร้างให้อัตโนมัติครั้งแรก
      // สำคัญ: replaceExisting: false เพื่อไม่ลบรหัสเดิมทิ้ง
      // ถ้าผู้ใช้คัดลอกรหัสให้ Roommate ไปแล้ว รหัสนั้นต้องยังใช้ได้
      if (existing == null) {
        await _generateCode(replaceExisting: false);
      }
    } catch (e) {
      print('❌ Load invitation code error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'โหลดรหัสเชิญไม่สำเร็จ';
      });
    }
  }

  /// สร้างรหัสใหม่แบบสุ่ม 6 ตัว แล้วบันทึกลง Supabase
  /// [replaceExisting] true = ผู้ใช้กด "สร้างใหม่" (ลบรหัสเก่าทิ้งได้)
  /// false = โหลดครั้งแรกที่ยังไม่มีรหัส (ห้ามลบรหัสเดิม)
  Future<void> _generateCode({bool replaceExisting = true}) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final membership = await _loadOwnMembership();
    final dormitoryId = membership?['dormitory_id']?.toString();
    if (dormitoryId == null) {
      if (!mounted) return;
      setState(() => _error = 'ไม่พบข้อมูลการเข้าพักของคุณ');
      return;
    }

    // หาห้องของผู้เช่าหลัก (ยังไม่มีก็จัดห้องว่างให้อัตโนมัติ)
    // Roommate จะได้ห้องเดียวกันตามรหัสนี้
    final roomId = await RoomMembersService().ensureRoomForMember(
      membership!['id'].toString(),
    );
    if (roomId != null) {
      final room = await Supabase.instance.client
          .from('rooms')
          .select('room_number')
          .eq('id', roomId)
          .maybeSingle();
      if (!mounted) return;
      setState(() => _roomNumber = room?['room_number']?.toString() ?? _roomNumber);
    }

    if (!mounted) return;
    setState(() => _isGenerating = true);

    try {
      // ถ้าไม่ได้ตั้งใจสร้างใหม่ และมีรหัสอยู่แล้ว → ไม่ต้องทำอะไร
      if (!replaceExisting) {
        final still = await Supabase.instance.client
            .from('invitation_codes')
            .select('code')
            .eq('created_by', uid)
            .limit(1)
            .maybeSingle();
        if (still != null) {
          if (!mounted) return;
          setState(() {
            _code = still['code']?.toString();
            _isGenerating = false;
          });
          return;
        }
      }

      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rand = Random.secure();
      String newCode = '';
      // สุ่มใหม่ถ้าชนกับรหัสที่มีอยู่แล้ว
      var isUnique = false;
      while (!isUnique) {
        newCode =
            List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
        final clash = await Supabase.instance.client
            .from('invitation_codes')
            .select('code')
            .eq('code', newCode)
            .maybeSingle();
        isUnique = clash == null;
      }

      // ลบรหัสเก่าเฉพาะตอนผู้ใช้กด "สร้างใหม่"
      if (replaceExisting) {
        await Supabase.instance.client
            .from('invitation_codes')
            .delete()
            .eq('created_by', uid);
      }

      await Supabase.instance.client.from('invitation_codes').insert({
        'code': newCode,
        'created_by': uid,
        'dormitory_id': dormitoryId,
        'room_id': roomId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'expires_at':
            DateTime.now().toUtc().add(const Duration(days: 7)).toIso8601String(),
      });

      // ยืนยันว่ารหัสถูกบันทึกจริง ก่อนแสดงให้ผู้ใช้คัดลอก
      // (ถ้าไม่เช็ด อาจแสดงรหัสที่บันทึกไม่สำเร็จ ทำให้ Roommate หารหัสไม่เจอ)
      final saved = await Supabase.instance.client
          .from('invitation_codes')
          .select('code')
          .eq('code', newCode)
          .maybeSingle();

      if (!mounted) return;
      if (saved == null) {
        setState(() {
          _isGenerating = false;
          _error = 'สร้างรหัสเชิญไม่สำเร็จ กรุณาลองอีกครั้ง';
        });
        return;
      }

      setState(() {
        _code = newCode;
        _isGenerating = false;
        _error = '';
      });
    } catch (e) {
      print('❌ Generate invitation code error: $e');
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _error = 'สร้างรหัสเชิญไม่สำเร็จ กรุณาลองอีกครั้ง';
      });
    }
  }

  void _copyCode() {
    final code = _code;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกรหัสแล้ว'),
        duration: Duration(seconds: 1),
      ),
    );
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    // Illustration
                    SvgPicture.asset(
                      'assets/images/invitation_code.svg',
                      width: 280,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'สร้างรหัสเชิญเพื่อให้ผู้พักอาศัยเข้าร่วมห้องของคุณ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        children: [
                          TextSpan(text: 'รหัสเชิญจะผูกกับ$_dormName ห้อง '),
                          TextSpan(
                            text: _roomNumber,
                            style: const TextStyle(color: Color(0xFF4F8FDB)),
                          ),
                          const TextSpan(text: ' โดยอัตโนมัติ'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Code box
Container(
                       width: double.infinity,
                       height: 90,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(
                           color: const Color(0xFFD9D9D9),
                           width: 1,
                         ),
                       ),
                      child: Stack(
                        children: [
                          Center(
                            child: _isLoading || _isGenerating
                                ? const CircularProgressIndicator()
                                : Text(
                                    _code ?? '-',
                                    style: const TextStyle(
                                      fontFamily: 'Noto Sans Thai',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 2,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                          ),
                          if (_code != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: _copyCode,
                                child: const Icon(
                                  Icons.copy_outlined,
                                  size: 20,
                                  color: Color(0xFF4F8FDB),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
            ),

            // สร้างใหม่ button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isGenerating)
                      ? null
                      : () => _generateCode(replaceExisting: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8FDB),
                    disabledBackgroundColor:
                        const Color(0xFF4F8FDB).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'สร้างใหม่',
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
                'สร้างรหัสเชิญ Roommate',
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
