import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/room_members_service.dart';

import '../widgets/app_sizes.dart';
class RoomMembersScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToInvitationCode;
  final bool isRoommate;

  const RoomMembersScreen({
    super.key,
    this.onBack,
    this.onNavigateToInvitationCode,
    this.isRoommate = false,
  });

  @override
  State<RoomMembersScreen> createState() => RoomMembersScreenState();
}

class RoomMembersScreenState extends State<RoomMembersScreen> {
  final _service = RoomMembersService();

  bool _isLoading = true;
  String _error = '';
  String _roomNumber = '-';
  String _building = '-';
  String _floor = '-';
  int _maxTenants = 0;
  List<Map<String, String>> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// เรียกจากภายนอกเมื่อกลับมาที่หน้านี้
  /// (หน้านี้อยู่ใน IndexedStack → initState ทำงานครั้งเดียว)
  void reload() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.loadMyRoom();
      if (!mounted) return;

      final room = data['room'] as Map<String, dynamic>?;
      final members = (data['members'] as List)
          .map((m) => Map<String, String>.from(m as Map))
          .toList();

      setState(() {
        _roomNumber = room?['room_number']?.toString() ?? '-';
        _building   = room?['building']?.toString() ?? '-';
        _floor      = room?['floor']?.toString() ?? '-';
        _maxTenants = (room?['max_tenants'] as num?)?.toInt() ?? 0;
        _members    = members;
        _isLoading  = false;
        _error      = room == null ? 'ยังไม่ได้รับการจัดห้องพัก' : '';
      });
    } catch (e) {
      print('❌ Load room members error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'โหลดข้อมูลสมาชิกไม่สำเร็จ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRoomInfoCard(),
                        const SizedBox(height: 12),

                        // รหัสเชิญ button (เฉพาะผู้เช่าหลักเท่านั้น)
                        if (!widget.isRoommate)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: widget.onNavigateToInvitationCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F8FDB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'รหัสเชิญ',
                                    style: TextStyle(
                                      fontFamily: 'Noto Sans Thai',
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildMembersCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    final capacity = _maxTenants > 0 ? '$_maxTenants' : '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home,
              color: Color(0xFFFF8C00),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ห้อง $_roomNumber',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'หอพัก StayEase • อาคาร $_building ชั้น $_floor',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_members.length}/$capacity',
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 13,
                color: Color(0xFF4F8FDB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard() {
    if (_error.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        ),
        child: Center(
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สมาชิกในห้อง',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          if (_members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'ยังไม่มีสมาชิกในห้องนี้',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < _members.length; i++) ...[
              if (i > 0)
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
              _buildMemberBlock(_members[i]),
            ],
        ],
      ),
    );
  }

  /// แสดง 1 สมาชิก: บรรทัดบอกบทบาท แล้วตามด้วยชื่อ + เบอร์
  Widget _buildMemberBlock(Map<String, String> member) {
    final isMe = member['isMe'] == '1';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              member['role'] ?? 'Roommate',
              style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 12,
                  color: Color(0xFF888888)),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ฉัน',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 10,
                    color: Color(0xFF4F8FDB),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _buildMemberRow(
          name: member['name'] ?? '-',
          phone: member['phone'] ?? '-',
          imageAsset: 'assets/images/user_avatar.png',
        ),
      ],
    );
  }

  Widget _buildMemberRow({
    required String name,
    required String phone,
    required String imageAsset,
  }) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            imageAsset,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 44,
              height: 44,
              color: const Color(0xFFD9D9D9),
              child: const Icon(Icons.person_outline,
                  size: 24, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phone,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
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
                'สมาชิกในห้อง',
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
