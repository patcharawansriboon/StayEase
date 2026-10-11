import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditeTenantBillScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final VoidCallback? onScanBill;
  final VoidCallback? onManualEntry;
  final String? billId;
  final Map<String, dynamic>? initialData;

  const EditeTenantBillScreen({
    super.key,
    this.onBack,
    this.onSave,
    this.onScanBill,
    this.onManualEntry,
    this.billId,
    this.initialData,
  });

  @override
  State<EditeTenantBillScreen> createState() =>
      _EditeTenantBillScreenState();
}

class _EditeTenantBillScreenState
    extends State<EditeTenantBillScreen> {
  int? _selected; // 0 = สแกนบิล, 1 = กรอกเอง

  // ข้อมูลผู้เช่าที่เลือก
  String? _selectedName;
  String? _selectedRoom;
  String? _selectedRole;
  String? _selectedUserId;

  // รายชื่อผู้เช่าทั้งหมด (จาก Supabase)
  List<Map<String, String>> _tenantList = [];
  bool _loadingTenants = false;

  @override
  void initState() {
    super.initState();
    // ตั้งค่าเริ่มต้นจาก initialData
    if (widget.initialData != null) {
      _selectedName = widget.initialData!['tenantName']?.toString() ??
          widget.initialData!['name']?.toString();
      _selectedRoom = widget.initialData!['room']?.toString();
      _selectedRole = widget.initialData!['role']?.toString();
      _selectedUserId = widget.initialData!['userId']?.toString() ??
          widget.initialData!['user_id']?.toString();
    }
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _loadingTenants = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      final rows = await Supabase.instance.client
          .from('dormitory_members')
          .select(
              'user_id, member_type, rooms(room_number, building), tenants(full_name, phone), roommate_invites(full_name, phone)')
          .eq('status', 'approved')
          .inFilter('dormitory_id',
              await _getAdminDormitoryIds(uid));

      final list = <Map<String, String>>[];
      for (final r in (rows as List)) {
        final room = r['rooms'] as Map<String, dynamic>?;
        final tenant = r['tenants'] as Map<String, dynamic>?;
        final roommate =
            r['roommate_invites'] as Map<String, dynamic>?;
        final name = tenant?['full_name']?.toString() ??
            roommate?['full_name']?.toString() ??
            '';
        final roomNum = room?['room_number']?.toString() ?? '';
        if (name.isEmpty || roomNum.isEmpty) continue;

        final memberType = r['member_type']?.toString() ?? 'tenant';
        list.add({
          'userId': r['user_id']?.toString() ?? '',
          'name': name,
          'room': roomNum,
          'role': memberType == 'roommate' ? 'Roommate' : 'ผู้เช่าหลัก',
        });
      }
      if (!mounted) return;
      setState(() => _tenantList = list);
    } catch (e) {
      print('❌ _loadTenants error: $e');
    } finally {
      if (mounted) setState(() => _loadingTenants = false);
    }
  }

  Future<List<String>> _getAdminDormitoryIds(String adminUid) async {
    final rows = await Supabase.instance.client
        .from('dormitories')
        .select('id')
        .eq('created_by', adminUid);
    return (rows as List).map((r) => r['id'].toString()).toList();
  }

  // ---- Bottom Sheet เลือกห้อง/ผู้เช่า ----
  void _showSelectTenantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (_, controller) => Column(
          children: [
            // handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'เลือกห้อง / ผู้เช่า',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            if (_loadingTenants)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator()))
            else if (_tenantList.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'ไม่พบผู้เช่าที่อนุมัติแล้ว',
                    style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        color: Color(0xFF888888)),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _tenantList.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (_, i) {
                    final t = _tenantList[i];
                    final isChosen = t['userId'] == _selectedUserId;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            const Color(0xFFEAF2FB),
                        child: Text(
                          t['name']!.isNotEmpty
                              ? t['name']![0]
                              : '?',
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 15,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                      ),
                      title: Text(
                        t['name']!,
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          fontWeight: isChosen
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      subtitle: Text(
                        'ห้อง ${t['room']}  •  ${t['role']}',
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                      trailing: isChosen
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF4F8FDB), size: 20)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedName = t['name'];
                          _selectedRoom = t['room'];
                          _selectedRole = t['role'];
                          _selectedUserId = t['userId'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- การ์ดข้อมูลผู้เช่า + ปุ่มเปลี่ยน ----
                  _buildTenantCard(),
                  const SizedBox(height: 24),

                  // ---- เลือกวิธีเพิ่มข้อมูล ----
                  const Text(
                    'เลือกวิธีเพิ่มข้อมูล',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMethodCard(
                          index: 0,
                          icon: Icons.camera_alt_outlined,
                          title: 'สแกนบิล',
                          subtitle: 'อ่านข้อมูลอัตโนมัติ',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMethodCard(
                          index: 1,
                          icon: Icons.edit_outlined,
                          title: 'กรอกเอง',
                          subtitle: 'พิมพ์ข้อมูลด้วยตัวเอง',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ---- ตัวอย่างบิลที่รองรับ ----
                  const Text(
                    'ตัวอย่างบิลที่รองรับ',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPdfSample(),
                      const SizedBox(width: 8),
                      _buildPdfSample(),
                      const SizedBox(width: 8),
                      _buildPdfSample(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---- ปุ่มดำเนินการ ----
          if (_selected != null)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8FDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selected == 0
                        ? 'สแกนบิล'
                        : 'กรอกข้อมูลเอง',
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
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

  void _onConfirm() {
    if (_selected == 0) {
      widget.onScanBill?.call();
    } else {
      widget.onManualEntry?.call();
    }
  }

  // ---- Header ----
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(Icons.chevron_left,
                size: 28, color: Color(0xFF1A1A2E)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'สร้างบิลผู้เช่า',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  // ---- การ์ดผู้เช่า + ปุ่มเปลี่ยน ----
  Widget _buildTenantCard() {
    final name = _selectedName ?? 'เลือกผู้เช่า';
    final room = _selectedRoom ?? '-';
    final role = _selectedRole ?? '-';
    final hasSelected = _selectedName != null;

    return GestureDetector(
      onTap: _showSelectTenantSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelected
                ? const Color(0xFF4F8FDB)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: hasSelected
                  ? const Color(0xFFEAF2FB)
                  : const Color(0xFFF5F5F5),
              child: hasSelected
                  ? Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 18,
                        color: Color(0xFF4F8FDB),
                      ),
                    )
                  : const Icon(Icons.person_outline,
                      size: 24, color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasSelected
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFAAAAAA),
                    ),
                  ),
                  if (hasSelected) ...[
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                        children: [
                          TextSpan(text: 'ห้อง $room'),
                          const TextSpan(
                              text: '  •  ',
                              style: TextStyle(
                                  color: Color(0xFFCCCCCC))),
                          TextSpan(text: role),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ปุ่มเปลี่ยน
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasSelected ? 'เปลี่ยน' : 'เลือก',
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 12,
                  color: Color(0xFF4F8FDB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- ปุ่มเลือกวิธี (สแกน / กรอกเอง) ----
  Widget _buildMethodCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selected == index;
    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEAF2FB)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F8FDB)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected
                  ? const Color(0xFF4F8FDB)
                  : const Color(0xFFAAAAAA),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF4F8FDB)
                    : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- PDF icon ----
  Widget _buildPdfSample() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 40, color: Color(0xFF4F8FDB)),
            Positioned(
              bottom: 10,
              child: Text(
                'PDF',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F8FDB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
