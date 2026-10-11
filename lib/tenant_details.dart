import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterTenantScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onNavigateToChangeStatus;
  final Map<String, String>? tenantData;
  final String? memberId;
  final String? currentStatus;
  final VoidCallback? onRefresh;

  const MasterTenantScreen({
    super.key,
    this.onBack,
    this.onEdit,
    this.onDelete,
    this.onNavigateToChangeStatus,
    this.tenantData,
    this.memberId,
    this.currentStatus,
    this.onRefresh,
  });

  @override
  State<MasterTenantScreen> createState() => _MasterTenantScreenState();
}

class _MasterTenantScreenState extends State<MasterTenantScreen> {
  Map<String, dynamic>? _rentalInfo;
  Map<String, String>? _personalInfo;
  bool _loading = true;
  bool _loadingPersonal = true;

  @override
  void initState() {
    super.initState();
    _fetchRentalInfo();
    _fetchPersonalInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() {
      widget.onRefresh?.call();
    });
  }

  Future<void> _fetchRentalInfo() async {
    if (widget.memberId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('tenant_rentals')
          .select()
          .eq('member_id', widget.memberId!)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _rentalInfo = data;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchPersonalInfo() async {
    if (widget.memberId == null) {
      setState(() => _loadingPersonal = false);
      return;
    }
    setState(() => _loadingPersonal = true);
    try {
      // 1. ดึง user_id (auth user ID) จาก dormitory_members โดยใช้ memberId (dormitory_members.id)
      final memberRow = await Supabase.instance.client
          .from('dormitory_members')
          .select('user_id')
          .eq('id', widget.memberId!)
          .maybeSingle();

      final authUserId = memberRow?['user_id']?.toString();
      if (authUserId == null || authUserId.isEmpty) {
        if (mounted) setState(() => _loadingPersonal = false);
        return;
      }

      // 2. ดึงข้อมูลส่วนตัวจาก tenant_rentals โดยใช้ auth user ID
      final personalData = await Supabase.instance.client
          .from('tenant_rentals')
          .select('id_card, birthdate, gender, address, emergency_contact, emergency_phone')
          .eq('member_id', authUserId)
          .maybeSingle();

      if (personalData != null && mounted) {
        setState(() {
          _personalInfo = {
            'idCard': personalData['id_card']?.toString() ?? '',
            'birthdate': personalData['birthdate']?.toString() ?? '',
            'gender': personalData['gender']?.toString() ?? '',
            'address': personalData['address']?.toString() ?? '',
            'emergencyContact': personalData['emergency_contact']?.toString() ?? '',
            'emergencyPhone': personalData['emergency_phone']?.toString() ?? '',
          };
          _loadingPersonal = false;
        });
      } else {
        if (mounted) setState(() => _loadingPersonal = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPersonal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      _buildProfile(),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'ข้อมูลส่วนตัว',
                        rows: [
                          ['ชื่อ-นามสกุล', widget.tenantData?['name'] ?? 'พัชราวรรณ  ศรีบุญ'],
                          ['เบอร์มือถือ', widget.tenantData?['phone'] ?? '099-999999'],
                          ['ห้อง', widget.tenantData?['room'] ?? 'A303'],
                          ['สถานะ', widget.currentStatus ?? 'กำลังเช่า'],
                          if (_personalInfo?['idCard']?.isNotEmpty == true)
                            ['เลขบัตรประชาชน', _personalInfo!['idCard']!],
                          if (_personalInfo?['birthdate']?.isNotEmpty == true)
                            ['วันเกิด', _personalInfo!['birthdate']!],
                          if (_personalInfo?['gender']?.isNotEmpty == true)
                            ['เพศ', _personalInfo!['gender']!],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRentalSection(),
                      const SizedBox(height: 12),
                      _buildSection(
                        title: 'ข้อมูลการติดต่อ',
                        rows: [
                          ['เบอร์มือถือ', widget.tenantData?['phone'] ?? '098-989-0000'],
                          ['ที่อยู่', _personalInfo?['address']?.isNotEmpty == true ? _personalInfo!['address']! : (widget.tenantData?['address'] ?? '098-989-0000')],
                          ['ผู้ติดต่อฉุกเฉิน', _personalInfo?['emergencyContact']?.isNotEmpty == true ? _personalInfo!['emergencyContact']! : (widget.tenantData?['name'] ?? 'พัชราวรรณ  ศรีบุญ')],
                          ['เบอร์ติดต่อฉุกเฉิน', _personalInfo?['emergencyPhone']?.isNotEmpty == true ? _personalInfo!['emergencyPhone']! : (widget.tenantData?['phone'] ?? '098-989-0000')],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentSection(),
                    ],
                  ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildRentalSection() {
    if (_loading) {
      return _buildCard(
        title: 'ข้อมูลการเช่า',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF999999)),
            ),
          ),
        ),
      );
    }

    final building = _rentalInfo?['building']?.toString() ?? '';
    final room = _rentalInfo?['room_number']?.toString() ?? '';
    final floor = _rentalInfo?['floor']?.toString() ?? '';
    final checkIn = _rentalInfo?['check_in_date']?.toString() ?? '';
    final checkOut = _rentalInfo?['check_out_date']?.toString() ?? '';
    final rent = _rentalInfo?['rent']?.toString() ?? '';
    final deposit = _rentalInfo?['deposit']?.toString() ?? '';

    final rows = <List<String>>[
      ['อาคาร', building],
      ['ห้อง', room],
      ['ชั้น', floor],
      ['วันที่เข้าพัก', checkIn],
      ['วันที่สิ้นสุด', checkOut],
      ['ค่าเช่าห้อง', rent],
      ['เงินประกัน', deposit],
    ].where((r) => r[1].isNotEmpty).toList();

    if (rows.isEmpty) {
      return _buildCard(
        title: 'ข้อมูลการเช่า',
        child: const Text(
          'ยังไม่มีข้อมูลการเช่า',
          style: TextStyle(
            fontFamily: 'Prompt',
            fontSize: 13,
            color: Color(0xFF999999),
          ),
        ),
      );
    }

    return _buildSection(title: 'ข้อมูลการเช่า', rows: rows);
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4181CB),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final name = widget.tenantData?['name'] ?? 'พัชราวรรณ  ศรีบุญ';
    final role = widget.tenantData?['role'] ?? 'ผู้เช่าหลัก';
    final phone = widget.tenantData?['phone'] ?? '098-000-0000';
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: const AssetImage('assets/images/user_avatar.png'),
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 11,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<List<String>> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4181CB),
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        r[0],
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r[1],
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เอกสารแนบ',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4181CB),
            ),
          ),
          const SizedBox(height: 12),
          _buildDocRow('สำเนาบัตรประชาชน'),
          const SizedBox(height: 10),
          _buildDocRow('สัญญาเช่า'),
        ],
      ),
    );
  }

  Widget _buildDocRow(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/images/icon_document.svg',
              width: 24, height: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: widget.onEdit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4F8FDB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'แก้ไขข้อมูล',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    color: Color(0xFF4F8FDB),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF16C6C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ลบผู้เช่า',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
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
                'รายละเอียดผู้เช่า',
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
