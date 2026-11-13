import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/app_sizes.dart';
import 'widgets/keyboard_safe_scroll.dart';

class EditeTenantScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final void Function(String status)? onStatusSaved;
  final String? currentStatus;
  final String? memberId;
  final VoidCallback? onRentalSaved;

  const EditeTenantScreen({
    super.key,
    this.onBack,
    this.onSave,
    this.onStatusSaved,
    this.currentStatus,
    this.memberId,
    this.onRentalSaved,
  });

  @override
  State<EditeTenantScreen> createState() => EditeTenantScreenState();
}

class EditeTenantScreenState extends State<EditeTenantScreen> {
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _floorController = TextEditingController();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();

  String _status = 'กำลังเช่า';

  // auth user id ของผู้เช่า (แปลงจาก memberId = dormitory_members.id)
  String? _tenantUserId;

  // ข้อมูลส่วนตัว (ผู้เช่ากรอก) — readonly ฝั่งแอดมิน
  String _pName = '';
  String _pPhone = '';
  String _pIdCard = '';
  String _pBirthdate = '';
  String _pGender = '';
  // เอกสารแนบ (ชื่อไฟล์ + url) ที่ผู้เช่าอัปโหลด
  List<Map<String, String>> _documents = [];
  // url ของเอกสารที่ถูกกดลบ (รอลบไฟล์จริง + บันทึกตอนกดบันทึก)
  final List<String> _removedDocumentUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.currentStatus != null) {
      _status = widget.currentStatus!;
    }
    _loadExistingRental();
  }

  @override
  void didUpdateWidget(covariant EditeTenantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // เปลี่ยนผู้เช่าที่เลือก → ต้องโหลดข้อมูลเดิมมาใหม่ (ไม่ใช้ค่าค้างของคนก่อน)
    if (oldWidget.memberId != widget.memberId) {
      _tenantUserId = null;
      _loadExistingRental();
    }
  }

  /// โหลดข้อมูลการเช่าเดิมใหม่ (เรียกจากภายนอกเมื่อกลับมาหน้านี้)
  void refresh() {
    _loadExistingRental();
  }

  // แปลง memberId → user_id แล้วดึงข้อมูลการเช่าเดิมมาเติมในฟอร์ม
  Future<void> _loadExistingRental() async {
    if (widget.memberId == null) return;
    final db = Supabase.instance.client;
    try {
      // 1) memberId (dormitory_members.id) → user_id (auth)
      final memberRow = await db
          .from('dormitory_members')
          .select('user_id')
          .eq('id', widget.memberId!)
          .maybeSingle();
      final userId = memberRow?['user_id']?.toString();
      if (userId == null || userId.isEmpty) return;
      _tenantUserId = userId;

      // 2) ดึงข้อมูลการเช่า + ข้อมูลส่วนตัว + เอกสาร จาก tenant_rentals
      final rental = await db
          .from('tenant_rentals')
          .select(
            'building, room_number, floor, check_in_date, check_out_date, rent, deposit, id_card, birthdate, gender, address, emergency_contact, emergency_phone, documents',
          )
          .eq('member_id', userId)
          .maybeSingle();

      // 3) ชื่อ-นามสกุล + เบอร์ จากตาราง tenants (Roommate → roommate_invites)
      var tenant = await db
          .from('tenants')
          .select('full_name, phone')
          .eq('id', userId)
          .maybeSingle();
      if (tenant == null) {
        tenant = await db
            .from('roommate_invites')
            .select('full_name, phone')
            .eq('id', userId)
            .maybeSingle();
      }

      if (!mounted) return;
      setState(() {
        if (rental != null) {
          _buildingController.text = rental['building']?.toString() ?? '';
          _roomController.text = rental['room_number']?.toString() ?? '';
          _floorController.text = rental['floor']?.toString() ?? '';
          _checkInController.text = rental['check_in_date']?.toString() ?? '';
          _checkOutController.text = rental['check_out_date']?.toString() ?? '';
          _rentController.text = rental['rent']?.toString() ?? '';
          _depositController.text = rental['deposit']?.toString() ?? '';

          _pIdCard = rental['id_card']?.toString() ?? '';
          _pBirthdate = rental['birthdate']?.toString() ?? '';
          _pGender = rental['gender']?.toString() ?? '';
          _documents = _parseDocuments(rental['documents']?.toString() ?? '');
        }
        _pName = tenant?['full_name']?.toString() ?? '';
        _pPhone = tenant?['phone']?.toString() ?? '';
      });
    } catch (e) {
      print('❌ _loadExistingRental error: $e');
    }
  }

  // แปลงข้อความเอกสาร "ชื่อ|url" บรรทัดละ 1 รายการ → list
  List<Map<String, String>> _parseDocuments(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw.split('\n').where((e) => e.trim().isNotEmpty).map((line) {
      final parts = line.split('|');
      return {
        'title': parts[0].trim(),
        'url': parts.length > 1 ? parts[1].trim() : '',
      };
    }).toList();
  }

  // รวมรายการเอกสารกลับเป็นข้อความ "ชื่อ|url" บรรทัดละ 1 รายการ
  String _documentsToString() {
    return _documents
        .map((d) {
          final title = d['title'] ?? 'เอกสาร';
          final url = d['url'] ?? '';
          return url.isEmpty ? title : '$title|$url';
        })
        .join('\n');
  }

  /// ลบไฟล์เอกสารออกจาก Supabase Storage
  Future<void> _deleteFileFromStorage(String url) async {
    if (url.isEmpty) return;
    const marker = 'dormitory-images/';
    final idx = url.indexOf(marker);
    if (idx == -1) return;
    final path = url.substring(idx + marker.length);
    if (path.isEmpty) return;
    try {
      await Supabase.instance.client.storage.from('dormitory-images').remove([
        path,
      ]);
    } catch (e) {
      print('❌ delete document file error: $e');
    }
  }

  /// กดลบเอกสารแนบของผู้เช่า (รอลบไฟล์จริง + บันทึกตอนกดบันทึก)
  Future<void> _deleteDocument(int index) async {
    final doc = _documents[index];
    final title = doc['title'] ?? 'เอกสาร';
    final url = doc['url'] ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ลบเอกสารแนบ',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'ต้องการลบ "$title" ของผู้เช่าใช่หรือไม่?',
          style: const TextStyle(fontFamily: 'Noto Sans Thai', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                color: Color(0xFFAAAAAA),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0303),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'ลบ',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _documents.removeAt(index);
      if (url.isNotEmpty) _removedDocumentUrls.add(url);
    });
  }

  final List<String> _months = [
    'ม.ค',
    'ก.พ',
    'มี.ค',
    'เม.ย',
    'พ.ค',
    'มิ.ย',
    'ก.ค',
    'ส.ค',
    'ก.ย',
    'ต.ค',
    'พ.ย',
    'ธ.ค',
  ];

  final List<String> _monthsFull = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  int _selectedDay = 1;
  int _selectedMonth = 0;
  int _selectedYear = 2568;

  void _showDatePicker(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: 280,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            controller.text =
                                '$_selectedDay ${_monthsFull[_selectedMonth]} $_selectedYear';
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Color(0xFF4F8FDB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedDay - 1,
                            ),
                            itemExtent: 40,
                            looping: true,
                            onSelectedItemChanged: (i) => setModalState(
                              () => _selectedDay = (i % 31) + 1,
                            ),
                            children: List.generate(
                              31,
                              (i) => _pickerItem('${i + 1}'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedMonth,
                            ),
                            itemExtent: 40,
                            looping: true,
                            onSelectedItemChanged: (i) =>
                                setModalState(() => _selectedMonth = i % 12),
                            children: _months
                                .map((m) => _pickerItem(m))
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedYear - 2540,
                            ),
                            itemExtent: 40,
                            looping: true,
                            onSelectedItemChanged: (i) => setModalState(
                              () => _selectedYear = (i % 30) + 2540,
                            ),
                            children: List.generate(
                              30,
                              (i) => _pickerItem('${i + 2540}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _pickerItem(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 16,
          color: Color(0xFF000000),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _roomController.dispose();
    _floorController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: KeyboardSafeScroll(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfile(),
                  const SizedBox(height: 16),
                  _buildPersonalSection(),
                  const SizedBox(height: 12),
                  _buildRentalSection(),
                  const SizedBox(height: 12),
                  _buildDocumentSection(),
                ],
              ),
              bottom: _buildBottomButton(),
            ),
          ),
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
                fontFamily: 'Noto Sans Thai',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ผู้เช่าหลัก',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 11,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- ข้อมูลส่วนตัว (readonly เทา) — ดึงจริงจากข้อมูลที่ผู้เช่ากรอก ----
  Widget _buildPersonalSection() {
    String show(String v) => v.isNotEmpty ? v : '-';
    return _buildCard(
      title: 'ข้อมูลส่วนตัว',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadOnlyField('ชื่อ-นามสกุล', show(_pName)),
          _buildReadOnlyField('เบอร์มือถือ', show(_pPhone)),
          _buildReadOnlyField('เลขบัตรประชาชน', show(_pIdCard)),
          _buildReadOnlyField('วันเกิด', show(_pBirthdate)),
          _buildReadOnlyField('เพศ', show(_pGender)),
        ],
      ),
    );
  }

  // ---- ข้อมูลการเช่า ----
  Widget _buildRentalSection() {
    return _buildCard(
      title: 'ข้อมูลการเช่า',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('สถานะ'),
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFD9D9D9))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildLabel('อาคาร'),
          _buildUnderlineInput(_buildingController, 'กรุณากรอกอาคารที่พัก'),
          const SizedBox(height: 12),
          _buildLabel('ห้องพัก'),
          _buildUnderlineInput(_roomController, 'กรุณากรอกเลขห้อง'),
          const SizedBox(height: 12),
          _buildLabel('ชั้น'),
          _buildUnderlineInput(_floorController, 'กรุณากรอกเลขชั้น'),
          const SizedBox(height: 12),
          _buildLabel('วันที่เข้าพัก'),
          GestureDetector(
            onTap: () => _showDatePicker(_checkInController),
            child: AbsorbPointer(
              child: _buildUnderlineInput(
                _checkInController,
                'กรุณากรอกวันที่เริ่มสัญญา',
                suffixIcon: GestureDetector(
                  onTap: () => _showDatePicker(_checkInController),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLabel('วันที่สิ้นสุด'),
          GestureDetector(
            onTap: () => _showDatePicker(_checkOutController),
            child: AbsorbPointer(
              child: _buildUnderlineInput(
                _checkOutController,
                'กรุณากรอกวันที่หมดสัญญา',
                suffixIcon: GestureDetector(
                  onTap: () => _showDatePicker(_checkOutController),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelWithUnit('ค่าเช่า', '(บาท/เดือน)'),
                    _buildUnderlineInput(
                      _rentController,
                      '0000.00 บาท',
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelWithUnit('เงินประกัน', '(บาท)'),
                    _buildUnderlineInput(
                      _depositController,
                      '0000.00 บาท',
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- เอกสารแนบ (แสดงจริงจากที่ผู้เช่าอัปโหลด) ----
  Widget _buildDocumentSection() {
    return _buildCard(
      title: 'เอกสารแนบ',
      child: _documents.isEmpty
          ? const Text(
              'ยังไม่มีเอกสารแนบ',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 13,
                color: Color(0xFF999999),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _documents.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _buildDocRow(
                    _documents[i]['title'] ?? 'เอกสาร',
                    _documents[i]['url'] ?? '',
                    i,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildDocRow(String title, String url, int index) {
    return GestureDetector(
      onTap: url.isEmpty ? null : () => _previewDocument(title, url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/icon_document.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 14,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            if (url.isNotEmpty)
              const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Color(0xFF4F8FDB),
              ),
            const SizedBox(width: 8),
            // ปุ่มลบเอกสารแนบของผู้เช่า
            GestureDetector(
              onTap: () => _deleteDocument(index),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // แสดงรูปเอกสารแบบเต็มจอ
  void _previewDocument(String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'ไม่สามารถแสดงไฟล์นี้ได้',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        color: Colors.white,
                      ),
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
              fontFamily: 'Noto Sans Thai',
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 14,
          color: Color(0xFF000000),
        ),
      ),
    );
  }

  Widget _buildLabelWithUnit(String text, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            color: Color(0xFF000000),
          ),
          children: [
            TextSpan(text: '$text '),
            TextSpan(
              text: unit,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderlineInput(
    TextEditingController controller,
    String hint, {
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.left,
  }) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      style: const TextStyle(
        fontFamily: 'Noto Sans Thai',
        fontSize: 14,
        color: Color(0xFF000000),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 14,
          color: Color(0xFFCCCCCC),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4F8FDB)),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _showSaveDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B93D4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'บันทึก',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveRentalInfo() async {
    final db = Supabase.instance.client;
    // ใช้ user_id เป็น member_id (มาตรฐานเดียวกับฝั่งผู้เช่า)
    // ถ้ายังไม่มี _tenantUserId ให้แปลงจาก memberId ก่อน
    var userId = _tenantUserId;
    if (userId == null && widget.memberId != null) {
      final memberRow = await db
          .from('dormitory_members')
          .select('user_id')
          .eq('id', widget.memberId!)
          .maybeSingle();
      userId = memberRow?['user_id']?.toString();
    }
    if (userId == null || userId.isEmpty) return;

    try {
      await db.from('tenant_rentals').upsert({
        'member_id': userId,
        'building': _buildingController.text,
        'room_number': _roomController.text,
        'floor': _floorController.text,
        'check_in_date': _checkInController.text,
        'check_out_date': _checkOutController.text,
        'rent': _rentController.text,
        'deposit': _depositController.text,
        'documents': _documentsToString(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // ลบไฟล์เอกสารที่ถูกกดลบออกจาก Storage
      for (final url in _removedDocumentUrls) {
        await _deleteFileFromStorage(url);
      }
      _removedDocumentUrls.clear();
    } catch (e) {
      print('❌ _saveRentalInfo error: $e');
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 60),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'คุณต้องการบันทึกข้อมูลใช่ไหม?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4F8FDB)),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.memberId != null) {
                            _saveRentalInfo().then((_) {
                              widget.onRentalSaved?.call();
                            });
                          } else {
                            widget.onRentalSaved?.call();
                          }
                          Navigator.pop(context);
                          widget.onStatusSaved?.call(_status);
                          widget.onSave?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F8FDB),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
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
                'รายละเอียดผู้เช่า',
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
