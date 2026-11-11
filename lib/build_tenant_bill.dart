import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scan.dart';
import 'sample_bill.dart';

class BuildTenantBillScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final void Function(Map<String, dynamic> billData)? onNext;
  final String? billId;
  final Map<String, dynamic>? initialData;

  const BuildTenantBillScreen({
    super.key,
    this.onBack,
    this.onSave,
    this.onNext,
    this.billId,
    this.initialData,
  });

  @override
  State<BuildTenantBillScreen> createState() =>
      _BuildTenantBillScreenState();
}

class _BuildTenantBillScreenState
    extends State<BuildTenantBillScreen> {
  final _roomFeeController = TextEditingController();

  // ข้อมูลผู้เช่าที่เลือก
  String? _selectedName;
  String? _selectedRoom;
  String? _selectedRole;
  String? _selectedUserId;

  List<Map<String, String>> _tenantList = [];
  bool _loadingTenants = false;

  // tenant_id ที่สร้างบิลรอบเดือนปัจจุบันไปแล้ว
  Set<String> _billedTenantIds = {};

  // เลขมิเตอร์ปัจจุบันที่สแกน/กรอกได้
  String? _electricMeter;
  String? _waterMeter;

  // เลขมิเตอร์เดิม (ครั้งก่อน) — ถ้ายังไม่มีให้ใช้ 00000
  String _electricPrev = '00000';
  String _waterPrev = '00000';

  // อัตราค่าบริการ (บาท/หน่วย)
  double _electricRate = 12;
  double _waterRate = 12;

  // รูป QR code โอนเงิน
  Uint8List? _qrBytes;
  String? _qrFileName;

  // ยอดค่าไฟ = (ปัจจุบัน - เดิม) * อัตรา
  double _meterTotal(String? current, String previous, double rate) {
    if (current == null || current.isEmpty) return 0;
    final curr = int.tryParse(current) ?? 0;
    final prev = int.tryParse(previous) ?? 0;
    final units = (curr - prev) < 0 ? 0 : (curr - prev);
    return units * rate;
  }

  double get _electricTotal =>
      _meterTotal(_electricMeter, _electricPrev, _electricRate);
  double get _waterTotal => _meterTotal(_waterMeter, _waterPrev, _waterRate);
  double get _roomFee => double.tryParse(_roomFeeController.text) ?? 0;
  double get _grandTotal => _electricTotal + _waterTotal + _roomFee;

  // กรอกครบทั้งไฟ/น้ำ/ค่าห้องหรือยัง
  bool get _isComplete =>
      (_electricMeter != null && _electricMeter!.isNotEmpty) &&
      (_waterMeter != null && _waterMeter!.isNotEmpty) &&
      _roomFeeController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // อัปเดตยอดรวมเมื่อแก้ค่าห้อง
    _roomFeeController.addListener(() => setState(() {}));
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

  @override
  void dispose() {
    _roomFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    setState(() => _loadingTenants = true);
    try {
      final db = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid == null) return;

      final dormIds = await _getAdminDormitoryIds(uid);
      if (dormIds.isEmpty) {
        if (mounted) setState(() => _tenantList = []);
        return;
      }

      // 1) ผู้เช่าหลักที่อนุมัติแล้วในหอพักของแอดมิน (ไม่รวม roommate)
      // หมายเหตุ: ไม่ embed tenants เพราะไม่มี FK โดยตรง
      //          (user_id อ้าง auth.users) → ต้อง lookup แยกแล้ว map เอง
      final members = await db
          .from('dormitory_members')
          .select('user_id, member_type, room_id')
          .eq('status', 'approved')
          .eq('member_type', 'tenant')
          .inFilter('dormitory_id', dormIds);

      final memberRows = (members as List).cast<Map<String, dynamic>>();
      if (memberRows.isEmpty) {
        if (mounted) setState(() => _tenantList = []);
        return;
      }

      final userIds = memberRows
          .map((m) => m['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final roomIds = memberRows
          .map((m) => m['room_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      // 2) ดึงชื่อจาก tenants และเลขห้องจาก rooms
      final tenantRows = userIds.isEmpty
          ? []
          : await db
              .from('tenants')
              .select('id, full_name, phone')
              .inFilter('id', userIds);
      final roomRows = roomIds.isEmpty
          ? []
          : await db
              .from('rooms')
              .select('id, room_number')
              .inFilter('id', roomIds);

      // สร้าง map สำหรับ lookup
      final tenantMap = <String, Map<String, dynamic>>{};
      for (final t in (tenantRows as List)) {
        tenantMap[t['id'].toString()] = t as Map<String, dynamic>;
      }
      final roomMap = <String, String>{};
      for (final r in (roomRows as List)) {
        roomMap[r['id'].toString()] = r['room_number']?.toString() ?? '';
      }

      // 3) ประกอบรายการ (เฉพาะผู้เช่าหลัก)
      final list = <Map<String, String>>[];
      for (final m in memberRows) {
        final userId = m['user_id']?.toString() ?? '';
        final roomId = m['room_id']?.toString() ?? '';
        final tenant = tenantMap[userId];
        final name = tenant?['full_name']?.toString() ?? '';
        final roomNum = roomMap[roomId] ?? '';
        if (name.isEmpty || roomNum.isEmpty) continue;

        list.add({
          'userId': userId,
          'name': name,
          'room': roomNum,
          'role': 'ผู้เช่าหลัก',
        });
      }

      // เรียงตามห้อง
      list.sort((a, b) => (a['room'] ?? '').compareTo(b['room'] ?? ''));

      if (!mounted) return;
      setState(() => _tenantList = list);
      // โหลดสถานะว่าใครสร้างบิลรอบนี้แล้ว
      await _loadBilledTenants(uid);
    } catch (e) {
      print('❌ _loadTenants error: $e');
    } finally {
      if (mounted) setState(() => _loadingTenants = false);
    }
  }

  // รอบบิลเดือนปัจจุบัน เช่น "สิงหาคม 2569" (ให้ตรงกับที่ sample_bill บันทึก)
  String get _currentBillMonth {
    final now = DateTime.now();
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return '${months[(now.month - 1) % 12]} ${now.year + 543}';
  }

  // โหลด tenant_id ที่มีบิลรอบเดือนปัจจุบันแล้ว
  Future<void> _loadBilledTenants(String adminUid) async {
    try {
      final dormIds = await _getAdminDormitoryIds(adminUid);
      if (dormIds.isEmpty) return;
      final rows = await Supabase.instance.client
          .from('bills')
          .select('tenant_id, month')
          .inFilter('dormitory_id', dormIds)
          .eq('month', _currentBillMonth);
      final ids = <String>{};
      for (final r in (rows as List)) {
        final id = r['tenant_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
      if (!mounted) return;
      setState(() => _billedTenantIds = ids);
    } catch (e) {
      print('❌ _loadBilledTenants error: $e');
    }
  }

  Future<List<String>> _getAdminDormitoryIds(String adminUid) async {
    final rows = await Supabase.instance.client
        .from('dormitories')
        .select('id')
        .eq('created_by', adminUid);
    return (rows as List).map((r) => r['id'].toString()).toList();
  }

  // ป้ายสถานะบิล: สร้างแล้ว (เขียว) / ยังไม่ได้สร้าง (ส้ม)
  Widget _buildBillStatusBadge(String tenantId) {
    final created = _billedTenantIds.contains(tenantId);
    final bg = created ? const Color(0xFFE9F7EC) : const Color(0xFFFFF3E0);
    final fg = created ? const Color(0xFF2E9E4F) : const Color(0xFFE6900B);
    final label = created ? 'สร้างแล้ว' : 'ยังไม่ได้สร้าง';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Prompt',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // ---- Bottom Sheet เลือกห้อง/ผู้เช่า ----
  void _showSelectTenantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (_, controller) => Column(
          children: [
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
                  child: Center(child: CircularProgressIndicator()))
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFEAF2FB),
                        child: Text(
                          t['name']!.isNotEmpty ? t['name']![0] : '?',
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBillStatusBadge(t['userId'] ?? ''),
                          if (isChosen) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle,
                                color: Color(0xFF4F8FDB), size: 20),
                          ],
                        ],
                      ),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- การ์ดเลือกผู้เช่า ----
                  _buildTenantCard(),
                  const SizedBox(height: 20),

                  // ---- หัวข้อ บันทึกเลขมิเตอร์ ----
                  _buildSectionTitle(),
                  const SizedBox(height: 14),

                  // ---- มิเตอร์ไฟฟ้า (พื้นฟ้า) ----
                  _buildMeterCard(
                    icon: Icons.flash_on,
                    iconBg: const Color(0xFFBFD9F2),
                    iconColor: const Color(0xFFF9A825),
                    title: 'มิเตอร์ไฟฟ้า',
                    cardBg: const Color(0xFFEAF2FB),
                    borderColor: const Color(0xFF4F8FDB),
                    buttonColor: const Color(0xFF4F8FDB),
                    illustration: 'assets/images/electric_meter.png',
                    illustrationFallback: SvgPicture.asset(
                      'assets/images/electricity.svg',
                      width: 80,
                      height: 80,
                    ),
                    unitLabel: 'หน่วย',
                    previousValue: _electricPrev,
                    rate: _electricRate,
                    currentValue: _electricMeter,
                    totalBg: const Color(0xFFDCEAFB),
                    totalColor: const Color(0xFF4F8FDB),
                    onScanTap: () => _scanMeter(
                      title: 'สแกนมิเตอร์ไฟฟ้า',
                      onResult: (v) {
                        setState(() => _electricMeter = v);
                        _promptPrevIfEmpty(
                          title: 'กรอกเลขมิเตอร์ไฟฟ้า',
                          previous: _electricPrev,
                          current: v,
                          onResult: (prev, curr) => setState(() {
                            _electricPrev = prev;
                            _electricMeter = curr;
                          }),
                        );
                      },
                    ),
                    onManualTap: () => _enterMeterManually(
                      title: 'กรอกเลขมิเตอร์ไฟฟ้า',
                      previous: _electricPrev,
                      current: _electricMeter,
                      onResult: (prev, curr) => setState(() {
                        _electricPrev = prev;
                        _electricMeter = curr;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- มิเตอร์น้ำ (พื้นเหลือง) ----
                  _buildMeterCard(
                    icon: Icons.water_drop,
                    iconBg: const Color(0xFFFCE9A8),
                    iconColor: const Color(0xFF4F8FDB),
                    title: 'มิเตอร์น้ำ',
                    cardBg: const Color(0xFFFFF8E5),
                    borderColor: const Color(0xFFFFD54F),
                    buttonColor: const Color(0xFFE6A700),
                    illustration: 'assets/images/water_meter.png',
                    illustrationFallback: SvgPicture.asset(
                      'assets/images/miter_water.svg',
                      width: 80,
                      height: 80,
                    ),
                    unitLabel: 'หน่วย',
                    previousValue: _waterPrev,
                    rate: _waterRate,
                    currentValue: _waterMeter,
                    totalBg: const Color(0xFFFCEFC7),
                    totalColor: const Color(0xFFC98A00),
                    onScanTap: () => _scanMeter(
                      title: 'สแกนมิเตอร์น้ำ',
                      onResult: (v) {
                        setState(() => _waterMeter = v);
                        _promptPrevIfEmpty(
                          title: 'กรอกเลขมิเตอร์น้ำ',
                          previous: _waterPrev,
                          current: v,
                          onResult: (prev, curr) => setState(() {
                            _waterPrev = prev;
                            _waterMeter = curr;
                          }),
                        );
                      },
                    ),
                    onManualTap: () => _enterMeterManually(
                      title: 'กรอกเลขมิเตอร์น้ำ',
                      previous: _waterPrev,
                      current: _waterMeter,
                      onResult: (prev, curr) => setState(() {
                        _waterPrev = prev;
                        _waterMeter = curr;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- ค่าห้อง ----
                  _buildRoomFeeCard(),

                  // ---- ยอดรวมสุทธิ + ปุ่มถัดไป (เมื่อกรอกครบ) ----
                  if (_isComplete) ...[
                    const SizedBox(height: 20),
                    _buildGrandTotalCard(),
                    const SizedBox(height: 16),
                    _buildQrUploadCard(),
                    const SizedBox(height: 24),
                    _buildNextButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- การ์ดยอดรวมสุทธิ ----
  Widget _buildGrandTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFBFD9F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ยอดรวมสุทธิ',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Text(
            '${_fmtMoney(_grandTotal)} บาท',
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  // ---- การ์ดอัปโหลด QR code โอนเงิน ----
  Widget _buildQrUploadCard() {
    final hasQr = _qrBytes != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2,
                  size: 20, color: Color(0xFF4F8FDB)),
              const SizedBox(width: 8),
              const Text(
                'QR code โอนเงิน',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasQr)
            // ยังไม่มีรูป → ปุ่มอัปโหลด (กรอบประ)
            GestureDetector(
              onTap: _pickQrImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFB7D6F5),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 34, color: Color(0xFF4F8FDB)),
                    SizedBox(height: 8),
                    Text(
                      'อัปโหลดรูป QR code',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4F8FDB),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'รองรับไฟล์รูปภาพ',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // มีรูปแล้ว → แสดง preview + ปุ่มเปลี่ยน/ลบ
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _qrBytes!,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                if (_qrFileName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _qrFileName!,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickQrImage,
                        icon: const Icon(Icons.refresh,
                            size: 18, color: Color(0xFF4F8FDB)),
                        label: const Text(
                          'เปลี่ยนรูป',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4F8FDB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _qrBytes = null;
                          _qrFileName = null;
                        }),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFFD32F2F)),
                        label: const Text(
                          'ลบรูป',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 13,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD32F2F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  // เลือกรูป QR จากคลังรูปภาพ
  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _qrBytes = bytes;
      _qrFileName = picked.name;
    });
  }

  // ---- ปุ่มถัดไป ----
  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F8FDB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          'ถัดไป',
          style: TextStyle(
            fontFamily: 'Prompt',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // รวบรวมข้อมูลบิลแล้วส่งต่อ
  void _onNext() {
    final data = <String, dynamic>{
      'tenantName': _selectedName,
      'room': _selectedRoom,
      'userId': _selectedUserId,
      'electricPrev': _electricPrev,
      'electricCurrent': _electricMeter,
      'electricRate': _electricRate,
      'electricTotal': _electricTotal,
      'waterPrev': _waterPrev,
      'waterCurrent': _waterMeter,
      'waterRate': _waterRate,
      'waterTotal': _waterTotal,
      'roomFee': _roomFee,
      'grandTotal': _grandTotal,
      'qrBytes': _qrBytes,
      'qrFileName': _qrFileName,
    };
    if (widget.onNext != null) {
      widget.onNext!(data);
      return;
    }
    // ไปหน้าตัวอย่างบิล
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SampleBillScreen(
          billData: data,
          // "แก้ไข" → กลับมาหน้านี้
          onEdit: () => Navigator.pop(ctx),
          // "ส่ง" → บันทึก/ส่งบิล (ยังไม่ได้ wire บันทึกจริง)
          onSend: (bill) {
            Navigator.pop(ctx);
            widget.onSave?.call();
          },
        ),
      ),
    );
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

  // ---- การ์ดเลือกผู้เช่า ----
  Widget _buildTenantCard() {
    final name = _selectedName ?? 'เลือกผู้เช่า';
    final room = _selectedRoom ?? '';
    final role = _selectedRole ?? '';
    final hasSelected = _selectedName != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Row(
        children: [
          // ไอคอนคน
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE6F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSelected ? Icons.person : Icons.person_outline,
              size: 24,
              color: const Color(0xFF4F8FDB),
            ),
          ),
          const SizedBox(width: 12),
          // ชื่อ + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSelected
                      ? 'ห้อง $room  •  $role'
                      : 'กรุณาเลือกผู้เช่าที่ต้องการสร้างบิล',
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
          // ปุ่มเลือกผู้เช่า
          GestureDetector(
            onTap: _showSelectTenantSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F8FDB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasSelected ? 'เปลี่ยน' : 'เลือกผู้เช่า',
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- หัวข้อ บันทึกเลขมิเตอร์ ----
  Widget _buildSectionTitle() {
    return Row(
      children: [
        SvgPicture.asset('assets/images/miter.svg',
            width: 48, height: 48),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'บันทึกเลขมิเตอร์',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: 1),
            Text(
              'เลือกวิธีบันทึกแยกตามประเภทมิเตอร์ได้',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- การ์ดมิเตอร์ (ไฟฟ้า/น้ำ) ----
  Widget _buildMeterCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Color cardBg,
    required Color borderColor,
    required String illustration,
    required Widget illustrationFallback,
    required Color buttonColor,
    required String unitLabel,
    required String previousValue,
    required double rate,
    required Color totalBg,
    required Color totalColor,
    String? currentValue,
    VoidCallback? onScanTap,
    VoidCallback? onManualTap,
  }) {
    final hasReading = currentValue != null && currentValue.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถวบน: ไอคอน + title + รูป illustration
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              // รูป illustration มิเตอร์
              Image.asset(
                illustration,
                width: 64,
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => illustrationFallback,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ยังไม่มีเลข → แสดงปุ่มสแกน/กรอกเอง
          // มีเลขแล้ว → แสดงรายละเอียดการคำนวณ
          if (!hasReading)
            Row(
              children: [
                Expanded(
                  child: _buildMeterButton(
                    svgPath: 'assets/images/scan.svg',
                    label: 'สแกนมิเตอร์',
                    color: buttonColor,
                    onTap: onScanTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMeterButton(
                    icon: Icons.edit_outlined,
                    label: 'กรอกเอง',
                    color: buttonColor,
                    onTap: onManualTap,
                  ),
                ),
              ],
            )
          else
            _buildMeterBreakdown(
              previousValue: previousValue,
              currentValue: currentValue,
              rate: rate,
              unitLabel: unitLabel,
              totalBg: totalBg,
              totalColor: totalColor,
              buttonColor: buttonColor,
              onScanTap: onScanTap,
              onManualTap: onManualTap,
            ),
        ],
      ),
    );
  }

  // ---- เปิดหน้าสแกนมิเตอร์ แล้วรับค่ากลับ ----
  Future<void> _scanMeter({
    required String title,
    required ValueChanged<String> onResult,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanScreen(
          meterTitle: title,
          onConfirm: (value) {
            onResult(value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // ถ้าเลขเดิมยังไม่มี (ว่าง/0/00000) ให้เปิดป๊อปอัปกรอกเลขเดิมก่อน
  void _promptPrevIfEmpty({
    required String title,
    required String previous,
    required String current,
    required void Function(String previous, String current) onResult,
  }) {
    final prevInt = int.tryParse(previous) ?? 0;
    if (prevInt != 0) return; // มีเลขเดิมแล้ว ไม่ต้องถาม
    // รอให้หน้า scan ปิดก่อนค่อยเปิด dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterMeterManually(
        title: title,
        previous: previous,
        current: current,
        onResult: onResult,
      );
    });
  }

  // ---- กรอกเลขมิเตอร์เอง (ป๊อปอัป) ----
  // มีช่อง "เลขเดิม" + "เลขปัจจุบัน" — ให้แอดมินกรอกเลขเดิมก่อนถ้ายังไม่มี
  Future<void> _enterMeterManually({
    required String title,
    required String previous,
    required String? current,
    required void Function(String previous, String current) onResult,
  }) async {
    final prevController = TextEditingController(text: previous);
    final currController = TextEditingController(text: current ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogField(
                label: 'เลขเดิม',
                controller: prevController,
                autofocus: false,
              ),
              const SizedBox(height: 14),
              _dialogField(
                label: 'เลขปัจจุบัน',
                controller: currController,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'ยกเลิก',
                style:
                    TextStyle(fontFamily: 'Prompt', color: Color(0xFF888888)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F8FDB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'บันทึก',
                style: TextStyle(fontFamily: 'Prompt', color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (saved == true && currController.text.isNotEmpty) {
      final prev = prevController.text.isEmpty ? '00000' : prevController.text;
      onResult(prev, currController.text);
    }
  }

  // ช่องกรอกเลขในป๊อปอัป (มี label)
  Widget _dialogField({
    required String label,
    required TextEditingController controller,
    required bool autofocus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 13,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: autofocus,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 18,
            letterSpacing: 4,
            color: Color(0xFF1A1A2E),
          ),
          decoration: InputDecoration(
            hintText: 'กรอกเลขมิเตอร์',
            hintStyle: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              letterSpacing: 0,
              color: Color(0xFFAAAAAA),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4F8FDB)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ---- รายละเอียดการคำนวณมิเตอร์ (เลขเดิม/ปัจจุบัน/หน่วย/อัตรา/รวม) ----
  Widget _buildMeterBreakdown({
    required String previousValue,
    required String currentValue,
    required double rate,
    required String unitLabel,
    required Color totalBg,
    required Color totalColor,
    required Color buttonColor,
    VoidCallback? onScanTap,
    VoidCallback? onManualTap,
  }) {
    final prev = int.tryParse(previousValue) ?? 0;
    final curr = int.tryParse(currentValue) ?? 0;
    final units = (curr - prev) < 0 ? 0 : (curr - prev);
    final total = units * rate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _breakdownRow('เลขเดิม', previousValue),
              const SizedBox(height: 10),
              _breakdownRow('เลขปัจจุบัน', currentValue),
              const SizedBox(height: 10),
              _breakdownRow('หน่วยที่ใช้', '$units  $unitLabel'),
              const SizedBox(height: 10),
              _breakdownRow(
                  'อัตรา', '${_fmtNum(rate)} บาท/$unitLabel'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // แถบ "รวม"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: totalBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รวม',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                '${_fmtMoney(total)} บาท',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: totalColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ปุ่มสแกนใหม่ / แก้ไข
        Row(
          children: [
            Expanded(
              child: _buildMeterButton(
                svgPath: 'assets/images/scan.svg',
                label: 'สแกนใหม่',
                color: buttonColor,
                onTap: onScanTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMeterButton(
                icon: Icons.edit_outlined,
                label: 'แก้ไขเลข',
                color: buttonColor,
                onTap: onManualTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 14,
            color: Color(0xFF555555),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  // จัดรูปแบบตัวเลขอัตรา (ตัด .0 ถ้าเป็นจำนวนเต็ม)
  String _fmtNum(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  // จัดรูปแบบเงิน เช่น 5680 -> 5,680.00
  String _fmtMoney(double n) {
    final parts = n.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$buf.${parts[1]}';
  }

  Widget _buildMeterButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
    IconData? icon,
    String? svgPath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- การ์ดค่าห้อง ----
  Widget _buildRoomFeeCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7D6F5), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Text(
            'ค่าห้อง',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              color: Color(0xFF000000),
            ),
          ),
          const Spacer(),
          // Input field
          SizedBox(
            width: 110,
            height: 40,
            child: TextField(
              controller: _roomFeeController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 15,
                color: Color(0xFF000000),
              ),
              decoration: InputDecoration(
                hintText: '0000.00',
                hintStyle: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  color: Color(0xFFCCCCCC),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFD9D9D9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFD9D9D9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF4F8FDB)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'บาท',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }
}
