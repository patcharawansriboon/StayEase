import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final void Function(String requestId)? onNavigateToDormitoryRequest;

  const RequestScreen({
    super.key,
    this.onBack,
    this.onNavigateToDormitoryRequest,
  });

  @override
  State<RequestScreen> createState() => RequestScreenState();
}

class RequestScreenState extends State<RequestScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _dormRequests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDormRequest();
  }

  /// เรียกจากภายนอกเมื่อกลับมาที่หน้านี้ เพื่อดึงคำขอใหม่
  void refresh() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _loadDormRequest();
  }

  /// รายการคำขอทั้งหมด ให้หน้ารายละเอียดนำไปแสดง
  List<Map<String, dynamic>> get dormRequests => _dormRequests;

  Future<void> _loadDormRequest() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _dormRequests = [];
          _error = 'ยังไม่ได้เข้าสู่ระบบ กรุณาล็อกอินใหม่';
        });
        return;
      }

      // ต้องเป็น session ของผู้ดูแลหอพัก (รหัสผ่านสมัครผู้เช่าจะเข้าสู่ระบบแทน session เดิม)
      final isAdmin = await Supabase.instance.client
          .from('admins')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (isAdmin == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _dormRequests = [];
          _error = 'บัญชีนี้ไม่ใช่ผู้ดูแลหอพัก กรุณาออกจากระบบแล้วล็อกอินในสิทธิ์ผู้ดูแลอีกครั้ง';
        });
        return;
      }

      // ดึง dormitory ที่ admin คนนี้สร้าง
      final dormRows = await Supabase.instance.client
          .from('dormitories')
          .select('id')
          .eq('created_by', user.id);

      if ((dormRows as List).isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _dormRequests = [];
          _error = 'ไม่พบหอพักที่คุณสร้าง กรุณาสร้างหอพักก่อน';
        });
        return;
      }

      final dormIds =
          (dormRows as List).map((d) => d['id'].toString()).toList();

      // ดึง pending request ทุกคนของหอที่ admin ดูแล (เรียงล่าสุดก่อน)
      // รวมทั้งผู้เช่าหลัก (member_type = tenant) และ Roommate (member_type = roommate)
      final rows = await Supabase.instance.client
          .from('dormitory_members')
          .select(
              'id, user_id, status, member_type, created_at, dormitories(dorm_code)')
          .inFilter('dormitory_id', dormIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (!mounted) return;

      final userIds =
          (rows as List).map((r) => r['user_id'].toString()).toList();
      Map<String, Map<String, dynamic>> tenantMap = {};
      Map<String, Map<String, dynamic>> roommateMap = {};
      if (userIds.isNotEmpty) {
        final tenantRows = await Supabase.instance.client
            .from('tenants')
            .select('id, full_name, phone')
            .inFilter('id', userIds);
        tenantMap = {
          for (final t in (tenantRows as List)) t['id'].toString(): t,
        };

        // Roommate เก็บชื่อ/เบอร์ไว้ใน roommate_invites ไม่ใช่ tenants
        final roommateRows = await Supabase.instance.client
            .from('roommate_invites')
            .select('id, full_name, phone')
            .inFilter('id', userIds);
        roommateMap = {
          for (final r in (roommateRows as List)) r['id'].toString(): r,
        };
      }

      if (!mounted) return;

      final requests = <Map<String, dynamic>>[];
      for (final r in (rows as List)) {
        final uid = r['user_id'].toString();
        final memberType = r['member_type']?.toString() ?? 'tenant';
        final isRoommate = memberType == 'roommate';
        final isUpgrade  = memberType == 'upgrade';

        // upgrade และ roommate เก็บชื่อใน roommate_invites
        // tenant ดึงจาก tenants แต่ fallback ไป roommate_invites ถ้าไม่มีข้อมูล
        // (กรณีเคยเป็น roommate แล้ว leave → สมัครใหม่เป็น tenant)
        var person = (isRoommate || isUpgrade) ? roommateMap[uid] : tenantMap[uid];
        if (person == null || (person['full_name']?.toString() ?? '').isEmpty) {
          person = roommateMap[uid] ?? tenantMap[uid];
        }
        final dorm = r['dormitories'] as Map<String, dynamic>?;

        requests.add({
          'id': r['id'],
          'userId': uid,
          'isRoommate': isRoommate,
          'isUpgrade':  isUpgrade,
          'memberType': memberType,
          'fullName': person?['full_name'] ?? 'Unknown',
          'phone': person?['phone']?.toString() ?? '',
          'dormCode': dorm?['dorm_code'] ?? '-',
          'date': r['created_at'] ?? '',
        });
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _dormRequests = requests;
        _error = null;
      });
    } catch (e) {
      print('❌ Load dorm request error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _dormRequests = [];
        _error = 'โหลดคำขอไม่สำเร็จ: $e';
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_dormRequests.isNotEmpty)
                    ..._dormRequests.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDormRequestCard(
                          r,
                          onTap: () => widget.onNavigateToDormitoryRequest
                              ?.call(r['id'].toString()),
                        ),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'ยังไม่มีคำขอเข้าหอพัก',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDormRequestCard(
    Map<String, dynamic> data, {
    VoidCallback? onTap,
  }) {
    final isRoommate = data['isRoommate'] == true;
    final isUpgrade  = data['isUpgrade']  == true;

    final Color avatarColor = isUpgrade
        ? const Color(0xFFE6A700)
        : isRoommate
            ? const Color(0xFF7BB6E8)
            : const Color(0xFF4F8FDB);

    final String title = isUpgrade
        ? 'คำขอเปลี่ยนเป็นผู้เช่าหลัก'
        : isRoommate
            ? 'คำขอเข้าร่วมห้อง (Roommate)'
            : 'คำขอเข้าหอพัก (ผู้เช่าหลัก)';

    final String subtitle = isUpgrade
        ? '${data['fullName']} ต้องการเปลี่ยนเป็นผู้เช่าหลัก หอพัก ${data['dormCode']}'
        : isRoommate
            ? '${data['fullName']} ต้องการเข้าร่วมห้อง หอพัก ${data['dormCode']}'
            : '${data['fullName']} ต้องการเข้าพัก หอพัก ${data['dormCode']}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(data['date']),
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic value) {
    final dateStr = value?.toString() ?? '';
    if (dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return '-';
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(Icons.chevron_left,
                size: 28, color: Color(0xFF000000)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'การแจ้งเตือน',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: refresh,
            icon: const Icon(Icons.refresh,
                size: 24, color: Color(0xFF000000)),
          ),
        ],
      ),
    );
  }
}
