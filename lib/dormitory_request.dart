import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DormitoryRequestScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  // ข้อมูลคำขอ (รับจาก notification list)
  final String tenantId;
  final String fullName;
  final String phone;
  final String dormCode;
  final String requestType;
  final String requestDate;

  const DormitoryRequestScreen({
    super.key,
    this.onBack,
    this.onApprove,
    this.onReject,
    this.tenantId = '',
    this.fullName = 'พัชราวรรณ  ศรีบุญ',
    this.phone = '098-9890000',
    this.dormCode = 'STAY01',
    this.requestType = 'ผู้เช่าหลัก',
    this.requestDate = '8 ก.ย. 2569 เวลา 09:25 น.',
  });

  @override
  State<DormitoryRequestScreen> createState() => _DormitoryRequestScreenState();
}

class _DormitoryRequestScreenState extends State<DormitoryRequestScreen> {
  bool _isLoading = false;

  Future<void> _handleApprove() async {
    if (widget.tenantId.isEmpty) {
      widget.onApprove?.call();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('tenants')
          .update({'status': 'กำลังเช่า', 'is_verified': true})
          .eq('id', widget.tenantId);
    } catch (_) {}
    setState(() => _isLoading = false);
    widget.onApprove?.call();
  }

  Future<void> _handleReject() async {
    if (widget.tenantId.isEmpty) {
      widget.onReject?.call();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('tenants')
          .update({'status': 'rejected'})
          .eq('id', widget.tenantId);
    } catch (_) {}
    setState(() => _isLoading = false);
    widget.onReject?.call();
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
                      ['ชื่อ-นามสกุล', widget.fullName],
                      ['เบอร์มือถือ', widget.phone],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: 'ข้อมูลการเข้าพัก',
                    rows: [
                      ['รหัสหอพัก', widget.dormCode],
                      ['ประเภท', widget.requestType],
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildProfile() {
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
            const Text(
              'พัชราวรรณ  ศรีบุญ',
              style: TextStyle(fontFamily: 'Prompt', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF4181CB), borderRadius: BorderRadius.circular(20)),
              child: const Text('ขอเข้าหอพัก', style: TextStyle(fontFamily: 'Prompt', fontSize: 11, color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text(
              'วันที่ส่ง ${widget.requestDate}',
              style: const TextStyle(fontFamily: 'Prompt', fontSize: 12, color: Color(0xFF999999)),
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

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleApprove,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF4F8FDB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'อนุมัติ',
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
                onPressed: _isLoading ? null : _handleReject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF16C6C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ปฏิเสธ',
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
                'รายละเอียดคำขอ',
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
