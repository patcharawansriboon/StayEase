import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MasterTenantScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MasterTenantScreen({
    super.key,
    this.onBack,
    this.onEdit,
    this.onDelete,
  });

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
                    rows: const [
                      ['ชื่อ-นามสกุล', 'พัชราวรรณ  ศรีบุญ'],
                      ['เลขบัตรประชาชน', '1-2-000-00000-000'],
                      ['วันเกิด', '26 กันยายน 2547'],
                      ['เพศ', 'หญิง'],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: 'ข้อมูลการเช่า',
                    rows: const [
                      ['อาคาร', 'A'],
                      ['ห้อง', 'A301'],
                      ['ชั้น', '3'],
                      ['วันที่เข้าพัก', '1 มกราคม 2568'],
                      ['วันที่สิ้นสุด', '1 มกราคม 2569'],
                      ['ค่าเช่าห้อง', '4,500'],
                      ['เงินประกัน', '10,000'],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: 'ข้อมูลการติดต่อ',
                    rows: const [
                      ['เบอร์มือถือ', '098-989-0000'],
                      ['ที่อยู่', '098-989-0000'],
                      ['ผู้ติดต่อฉุกเฉิน', 'พัชราวรรณ  ศรีบุญ'],
                      ['เบอร์ติดต่อฉุกเฉิน', '098-989-0000'],
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
              style: TextStyle(
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
              child: const Text(
                'ผู้เช่าหลัก',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 11,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.phone_outlined, size: 14, color: Color(0xFF999999)),
                SizedBox(width: 4),
                Text(
                  '098-000-0000',
                  style: TextStyle(
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
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF78A2D2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'แก้ไขข้อมูล',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    color: Color(0xFF78A2D2),
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
                onPressed: onDelete,
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
            onTap: onBack,
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
