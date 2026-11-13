import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() =>
      _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _dormInfo;
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _repairs = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadAll(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _loadProfile(uid),
        _loadDormInfo(uid),
        _loadAnnouncements(),
        _loadBills(uid),
        _loadRepairs(uid),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _dormInfo = results[1] as Map<String, dynamic>?;
        _announcements = results[2] as List<Map<String, dynamic>>;
        _bills = results[3] as List<Map<String, dynamic>>;
        _repairs = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _loadProfile(String uid) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('id, full_name, phone, role')
          .eq('id', uid)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadDormInfo(String uid) async {
    try {
      final row = await _supabase
          .from('dormitory_members')
          .select('status, dormitories!dormitory_members_dormitory_id_fkey(id, dorm_code, dorm_name)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      final dorm = row['dormitories'] as Map<String, dynamic>?;
      return {
        'status': row['status'],
        'dorm_name': dorm?['dorm_name'],
        'dorm_code': dorm?['dorm_code'],
        'dormitory_id': dorm?['id'],
      };
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAnnouncements() async {
    try {
      final dormId = _dormInfo?['dormitory_id'] as String?;
      if (dormId == null) return [];
      final rows = await _supabase
          .from('announcements')
          .select('id, title, content, image_url, created_at')
          .eq('dormitory_id', dormId)
          .order('created_at', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => {
                'id': r['id'],
                'title': r['title'] ?? '',
                'content': r['content'] ?? '',
                'image': r['image_url'] ?? '',
                'date': _formatDate(r['created_at']),
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadBills(String uid) async {
    try {
      final rows = await _supabase
          .from('bills')
          .select('id, month, rent, electricity, water, penalty, total, due_date, status')
          .eq('tenant_id', uid)
          .order('due_date', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => {
                'id': r['id'],
                'month': r['month'] ?? '',
                'rent': r['rent'] ?? 0,
                'electricity': r['electricity'] ?? 0,
                'water': r['water'] ?? 0,
                'penalty': r['penalty'] ?? 0,
                'total': r['total'] ?? 0,
                'due_date': r['due_date'] ?? '',
                'status': r['status'] ?? 'pending',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadRepairs(String uid) async {
    try {
      final rows = await _supabase
          .from('repairs')
          .select('id, room_number, category, description, created_at, status')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => {
                'id': r['id'],
                'room': r['room_number'] ?? '',
                'title': r['category'] ?? '',
                'description': r['description'] ?? '',
                'date': _formatDate(r['created_at']),
                'status': r['status'] ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const thMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
          'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
      final by = dt.year + 543;
      return '${dt.day} ${thMonths[dt.month]} ${by.toString().substring(2)}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF4F8FDB))),
      );
    }

    final name = _profile?['full_name'] ?? 'ผู้เช่า';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(name),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_announcements.isNotEmpty) _buildAnnouncementSection(),
                  if (_bills.isNotEmpty) _buildBillSection(),
                  if (_repairs.isNotEmpty) _buildRepairSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('assets/images/user_avatar.png'),
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สวัสดี $name',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                Text(
                  'หอพัก ${_dormInfo?['dorm_code'] ?? '-'}',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📢 ประกาศ',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        ..._announcements.map((a) => _buildCard(
              '📢 ${a['title']}',
              a['content'],
              a['date'],
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBillSection() {
    final latest = _bills.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💰 ค่าเช่าห้อง / บิล',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        _buildBillCard(
          latest['month'] ?? 'ไม่ทราบ',
          '${latest['total'] ?? 0} บาท',
          'ครบกำหนด ${latest['due_date'] ?? '-'}',
          latest['status'] == 'paid' ? 'ชำระแล้ว' : 'ค้างชำระ',
        ),
        if (_bills.length > 1) ...[
          const SizedBox(height: 8),
          Text(
            'ดูบิลย้อนหลัง ${_bills.length - 1} รายการ',
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 12,
              color: Color(0xFF4181CB),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRepairSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔧 แจ้งซ่อม',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        ..._repairs.map((r) => _buildCard(
              '🔧 ${r['room']} - ${r['title']}',
              r['description'],
              '${r['date']} · ${r['status']}',
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCard(String title, String subtitle, String date) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontFamily: 'Noto Sans Thai', fontSize: 14, fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          )),
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai', fontSize: 12, color: Color(0xFF555555),
            )),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(
            fontFamily: 'Noto Sans Thai', fontSize: 11, color: Color(0xFF999999),
          )),
        ],
      ),
    );
  }

  Widget _buildBillCard(String month, String amount, String due, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📅 $month', style: const TextStyle(
            fontFamily: 'Noto Sans Thai', fontSize: 14, fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          )),
          const SizedBox(height: 6),
          Text(amount, style: const TextStyle(
            fontFamily: 'Noto Sans Thai', fontSize: 20, fontWeight: FontWeight.w700,
            color: Color(0xFF4181CB),
          )),
          const SizedBox(height: 4),
          Text(due, style: const TextStyle(
            fontFamily: 'Noto Sans Thai', fontSize: 12, color: Color(0xFF888888),
          )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: status == 'ชำระแล้ว'
                  ? const Color(0xFFE9F7EC)
                  : const Color(0xFFFCE9E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(
              fontFamily: 'Noto Sans Thai', fontSize: 11,
              color: status == 'ชำระแล้ว'
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFCC0000),
            )),
          ),
        ],
      ),
    );
  }
}
