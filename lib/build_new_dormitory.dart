import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/app_sizes.dart';
import 'widgets/keyboard_safe_scroll.dart';

class BuildNewDormitoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final void Function(Map<String, dynamic> dormitoryData)? onSubmit;

  const BuildNewDormitoryScreen({
    super.key,
    this.onBack,
    this.onCancel,
    this.onSubmit,
  });

  @override
  State<BuildNewDormitoryScreen> createState() =>
      _BuildNewDormitoryScreenState();
}

class _BuildNewDormitoryScreenState extends State<BuildNewDormitoryScreen> {
  int _currentStep = 1;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dormCodeController = TextEditingController();
  final _electricRateController = TextEditingController();
  final _waterRateController = TextEditingController();

  // Validation states
  String? _dormCodeError;
  bool _isCheckingDormCode = false;
  String? _nameError;
  String? _addressError;
  String? _phoneError;
  String? _floorCountError;
  String? _totalRoomsError;
  String? _roomFormatError;
  String? _maxTenantsError;
  String? _roomArrangementError;
  String? _electricRateError;
  String? _waterRateError;
  List<String> _roomFormatPreview = [];

  // Step 2
  final _floorCountController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final _roomNumberFormatController = TextEditingController();
  int? _maxTenants; // จำนวนผู้เช่าสูงสุดต่อห้อง
  String? _roomArrangement; // 'empty' | 'occupied'

  @override
  void initState() {
    super.initState();
    _roomNumberFormatController.addListener(_updateRoomFormatPreview);
    _floorCountController.addListener(_updateRoomFormatPreview);
  }

  /// สร้างตัวอย่างเลขห้อง 3-5 ห้องแรก เพื่อแสดง preview ให้แอดมินเห็น
  void _updateRoomFormatPreview() {
    final format = _roomNumberFormatController.text.trim();
    if (format.isEmpty) {
      setState(() => _roomFormatPreview = []);
      return;
    }

    final floorCount = int.tryParse(_floorCountController.text.trim()) ?? 1;
    final samples = <String>[];

    for (int floor = 1; floor <= floorCount && samples.length < 5; floor++) {
      for (int i = 1; i <= 3 && samples.length < 5; i++) {
        String roomNumber;
        if (format.contains('{floor}') || format.contains('{room}')) {
          roomNumber = format
              .replaceAll('{floor}', floor.toString())
              .replaceAll('{room}', i.toString().padLeft(2, '0'));
        } else if (RegExp(r'\w+-\w+').hasMatch(format)) {
          // range format: A101-A110,A201-A210 → แสดงห้องแรกของแต่ละ segment
          final segments = format.split(',');
          for (final seg in segments) {
            if (samples.length >= 5) break;
            final parts = seg.trim().split('-');
            if (parts.length == 2) {
              final fromStr = parts[0].trim();
              final toStr = parts[1].trim();
              final prefixMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(fromStr);
              final prefix = prefixMatch?.group(1) ?? '';
              final from = int.tryParse(prefixMatch?.group(2) ?? '') ?? 1;
              final toMatch = RegExp(r'(\d+)$').firstMatch(toStr);
              final to = int.tryParse(toMatch?.group(1) ?? '') ?? from;
              for (int n = from; n <= to && samples.length < 5; n++) {
                samples.add('$prefix$n');
              }
            }
          }
          setState(() => _roomFormatPreview = samples);
          return;
        } else {
          final floorAwareMatch = RegExp(
            r'^(.*?)([1-9])(\d{2,})$',
          ).firstMatch(format);
          final floorDigitVal = int.tryParse(floorAwareMatch?.group(2) ?? '');

          if (floorAwareMatch != null && floorDigitVal == 1 && floorCount > 1) {
            final prefixStr = floorAwareMatch.group(1)!;
            final roomSuffix = floorAwareMatch.group(3)!;
            final roomPad = roomSuffix.length;
            roomNumber =
                '$prefixStr$floor${i.toString().padLeft(roomPad, '0')}';
          } else {
            final match = RegExp(r'(\d+)\s*$').firstMatch(format);
            if (match == null) {
              final roomIndex = (floor - 1) * 3 + i;
              roomNumber = '$format$roomIndex';
            } else {
              final digits = match.group(1) ?? '';
              final start = int.tryParse(digits) ?? 1;
              final roomIndex = (floor - 1) * 3 + i;
              final seq = start + roomIndex - 1;
              roomNumber =
                  '${format.substring(0, match.start)}${seq.toString().padLeft(digits.length, '0')}';
            }
          }
        }
        if (!samples.contains(roomNumber)) samples.add(roomNumber);
      }
    }

    setState(() => _roomFormatPreview = samples);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _dormCodeController.dispose();
    _floorCountController.dispose();
    _totalRoomsController.dispose();
    _roomNumberFormatController.dispose();
    _electricRateController.dispose();
    _waterRateController.dispose();
    super.dispose();
  }

  Future<void> _validateDormCode() async {
    final code = _dormCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _dormCodeError = 'กรุณากรอกรหัสหอพัก';
        _isCheckingDormCode = false;
      });
      return;
    }

    setState(() {
      _isCheckingDormCode = true;
      _dormCodeError = null;
    });

    try {
      final row = await Supabase.instance.client
          .from('dormitories')
          .select('id')
          .eq('dorm_code', code)
          .maybeSingle();

      if (!mounted) return;

      if (row != null) {
        setState(() {
          _dormCodeError = 'รหัสหอพักนี้มีอยู่แล้ว กรุณาเปลี่ยนรหัสใหม่';
          _isCheckingDormCode = false;
        });
      } else {
        setState(() {
          _dormCodeError = null;
          _isCheckingDormCode = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dormCodeError = null;
        _isCheckingDormCode = false;
      });
    }
  }

  bool _validateStep1() {
    bool valid = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'กรุณากรอกชื่อหอพัก'
          : null;
      if (_nameError != null) valid = false;

      _addressError = _addressController.text.trim().isEmpty
          ? 'กรุณากรอกที่อยู่หอพัก'
          : null;
      if (_addressError != null) valid = false;

      _phoneError = _phoneController.text.trim().length != 10
          ? 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก'
          : null;
      if (_phoneError != null) valid = false;
    });
    return valid;
  }

  bool _validateStep2() {
    bool valid = true;
    String? electricErr;
    String? waterErr;
    String? floorErr;
    String? totalRoomsErr;
    String? roomFormatErr;
    String? maxTenantsErr;

    floorErr =
        _floorCountController.text.trim().isEmpty ||
            int.tryParse(_floorCountController.text.trim()) == null ||
            int.tryParse(_floorCountController.text.trim()) == 0
        ? 'กรุณากรอกจำนวนชั้น'
        : null;
    if (floorErr != null) valid = false;

    totalRoomsErr =
        _totalRoomsController.text.trim().isEmpty ||
            int.tryParse(_totalRoomsController.text.trim()) == null ||
            int.tryParse(_totalRoomsController.text.trim()) == 0
        ? 'กรุณากรอกจำนวนห้องพัก'
        : null;
    if (totalRoomsErr != null) valid = false;

    roomFormatErr = _roomNumberFormatController.text.trim().isEmpty
        ? 'กรุณากรอกรูปแบบเลขห้อง'
        : null;
    if (roomFormatErr != null) valid = false;

    maxTenantsErr = _maxTenants == null ? 'กรุณาเลือกจำนวนผู้เช่า' : null;
    if (maxTenantsErr != null) valid = false;

    final electricText = _electricRateController.text.trim().replaceAll(
      ',',
      '.',
    );
    final electric = double.tryParse(electricText);
    if (electricText.isEmpty || electric == null || electric <= 0) {
      electricErr = 'กรุณากรอกอัตราค่าไฟฟ้า';
      valid = false;
    }

    final waterText = _waterRateController.text.trim().replaceAll(',', '.');
    final water = double.tryParse(waterText);
    if (waterText.isEmpty || water == null || water <= 0) {
      waterErr = 'กรุณากรอกอัตราค่าน้ำ';
      valid = false;
    }

    setState(() {
      _floorCountError = floorErr;
      _totalRoomsError = totalRoomsErr;
      _roomFormatError = roomFormatErr;
      _maxTenantsError = maxTenantsErr;
      _electricRateError = electricErr;
      _waterRateError = waterErr;
    });
    return valid;
  }

  Future<void> _onNext() async {
    if (_currentStep == 1) {
      if (!_validateStep1()) return;
      await _validateDormCode();
      if (_dormCodeError != null) return;
    }

    if (_currentStep == 2) {
      setState(() {
        _floorCountError = null;
        _totalRoomsError = null;
        _roomFormatError = null;
        _maxTenantsError = null;
        _electricRateError = null;
        _waterRateError = null;
      });
      if (!_validateStep2()) return;
    }

    if (_currentStep == 3) {
      if (!_validateStep1()) return;
      await _validateDormCode();
      if (_dormCodeError != null) return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      final data = {
        'dorm_code': _dormCodeController.text.trim().toUpperCase(),
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'floorCount': int.tryParse(_floorCountController.text) ?? 1,
        'totalRooms': int.tryParse(_totalRoomsController.text) ?? 0,
        'roomNumberFormat': _roomNumberFormatController.text,
        'maxTenants': _maxTenants ?? 1,
        'electricRate':
            double.tryParse(
              _electricRateController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
        'waterRate':
            double.tryParse(
              _waterRateController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
      };
      widget.onSubmit?.call(data);
    }
  }

  void _onCancelOrBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      widget.onCancel?.call();
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
            child: KeyboardSafeScroll(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),
                ],
              ),
              bottom: _buildBottomButtons(),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step 1: ข้อมูลหอพัก ----
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ข้อมูลหอพัก'),
        const SizedBox(height: 16),
        _buildLabel('ชื่อหอพัก'),
        _buildInput(
          _nameController,
          hint: 'กรุณากรอกชื่อที่พัก',
          icon: Icons.home_outlined,
          errorText: _nameError,
        ),
        const SizedBox(height: 16),
        _buildLabel('ที่อยู่หอพัก'),
        _buildInput(
          _addressController,
          hint: 'กรุณากรอกที่อยู่ของที่พัก',
          icon: Icons.location_on_outlined,
          errorText: _addressError,
        ),
        const SizedBox(height: 16),
        _buildLabelRequired('เบอร์โทรศัพท์ติดต่อหอพัก'),
        _buildInput(
          _phoneController,
          hint: 'กรุณากรอกเบอร์โทรศัพท์',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          errorText: _phoneError,
        ),
        const SizedBox(height: 16),
        _buildLabelRequired('รหัสหอพัก'),
        _buildInput(
          _dormCodeController,
          hint: 'เช่น STAY01',
          icon: Icons.confirmation_number_outlined,
          errorText: _dormCodeError,
          onEditingComplete: _validateDormCode,
        ),
      ],
    );
  }

  // ---- Step 2: ตั้งค่าหอพัก ----
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ตั้งค่าหอพัก'),
        const SizedBox(height: 16),
        _buildLabelRequired('จำนวนชั้น'),
        _buildInput(
          _floorCountController,
          hint: 'กรุณากรอกจำนวนชั้น',
          icon: Icons.apartment_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _floorCountError,
        ),
        const SizedBox(height: 16),
        _buildLabelRequired('จำนวนห้องพักทั้งหมด'),
        _buildInput(
          _totalRoomsController,
          hint: 'กรุณากรอกจำนวนห้องพักทั้งหมด',
          icon: Icons.meeting_room_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _totalRoomsError,
        ),
        const SizedBox(height: 16),
        _buildLabelRequired('รูปแบบเลขห้อง'),
        _buildInput(
          _roomNumberFormatController,
          hint: 'เช่น A101, 101, {floor}{room}',
          icon: Icons.tag,
          errorText: _roomFormatError,
        ),
        if (_roomFormatPreview.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.preview_outlined,
                    size: 16,
                    color: Color(0xFF4181CB),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ตัวอย่างห้อง: ${_roomFormatPreview.join(', ')}...',
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Color(0xFF4181CB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        _buildLabelRequired('จำนวนผู้เช่าสูงสุดต่อห้อง'),
        _buildMaxTenantsDropdown(),
        if (_maxTenantsError != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(
              _maxTenantsError!,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        const SizedBox(height: 16),
        _buildSectionTitle('อัตราค่ามิเตอร์ไฟฟ้าและน้ำ'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x4DFFE27F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFE27F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelRequired('ค่าไฟฟ้า'),
              const SizedBox(height: 6),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _electricRateError != null
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 4),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x80B7D6F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.electric_bolt_outlined,
                          size: 18,
                          color: Color(0xFF4181CB),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _electricRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 15,
                          color: Color(0xFF000000),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'เช่น 7.00',
                          hintStyle: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 15,
                            color: Color(0xFFAAAAAA),
                          ),
                          isCollapsed: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text(
                        'บาท/หน่วย',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_electricRateError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    _electricRateError!,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 12,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x4DB7D6F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4F8FDB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelRequired('ค่าน้ำ'),
              const SizedBox(height: 6),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _waterRateError != null
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 4),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x80B7D6F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.water_drop_outlined,
                          size: 18,
                          color: Color(0xFF4181CB),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _waterRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 15,
                          color: Color(0xFF000000),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'เช่น 18.00',
                          hintStyle: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 15,
                            color: Color(0xFFAAAAAA),
                          ),
                          isCollapsed: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text(
                        'บาท/หน่วย',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_waterRateError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    _waterRateError!,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 12,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildNoteBox(),
      ],
    );
  }

  Widget _buildMaxTenantsDropdown() {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x80B7D6F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Color(0xFF4181CB),
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _maxTenants,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF999999),
                  ),
                  hint: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'กรุณากรอกจำนวนผู้เช่า',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 15,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    color: Color(0xFF000000),
                  ),
                  items: List.generate(3, (i) => i + 1)
                      .map(
                        (n) => DropdownMenuItem<int>(
                          value: n,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('$n คน'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _maxTenants = v),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String title,
    required String hint,
  }) {
    final selected = _roomArrangement == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _roomArrangement = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4181CB)
                      : const Color(0xFFBBBBBB),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4181CB),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 14,
                  color: Color(0xFF000000),
                ),
                children: [
                  TextSpan(text: title),
                  TextSpan(
                    text: hint,
                    style: const TextStyle(color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF4181CB)),
              SizedBox(width: 6),
              Text(
                'หมายเหตุ',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4181CB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'รูปแบบที่รองรับ:\n'
            '• A101-A110,A201-A210  →  A101…A110, A201…A210 (range แต่ละชั้น)\n'
            '• A101  →  A101…A110, A201…A210 (อักษร+ชั้น+ลำดับ)\n'
            '• 101   →  101, 102, 103 ... (ตัวเลขล้วน)\n'
            '• {floor}{room}  →  101, 102, 201, 202 (กำหนด floor เอง)\n\n'
            'เคล็ดลับ: กรอกรูปแบบในช่องด้านบนแล้วดูตัวอย่างห้องได้ทันที',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 12,
              color: Color(0xFF666666),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step 3: ยืนยัน ----
  Widget _buildStep3() {
    final electricText = _electricRateController.text.trim().replaceAll(
      ',',
      '.',
    );
    final waterText = _waterRateController.text.trim().replaceAll(',', '.');
    final floorCount = _floorCountController.text.isNotEmpty
        ? '${_floorCountController.text} ชั้น'
        : '-';
    final totalRooms = _totalRoomsController.text.isNotEmpty
        ? '${_totalRoomsController.text} ห้อง'
        : '-';
    final roomFormat = _roomNumberFormatController.text.isNotEmpty
        ? _roomNumberFormatController.text
        : '-';
    final maxTenants = _maxTenants != null ? '$_maxTenants คน' : '-';
    final electricRate = electricText.isNotEmpty
        ? '$electricText บาท/หน่วย'
        : '-';
    final waterRate = waterText.isNotEmpty ? '$waterText บาท/หน่วย' : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x4DB7D6F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4F8FDB)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: const [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 18,
                      color: Color(0xFF4181CB),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ตรวจสอบข้อมูล',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4181CB),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('จำนวนชั้น', floorCount),
                      _buildDetailRow('จำนวนห้องพักทั้งหมด', totalRooms),
                      _buildDetailRow('รูปแบบเลขห้อง', roomFormat),
                      _buildDetailRow('จำนวนผู้เช่าสูงสุดต่อห้อง', maxTenants),
                      _buildDetailRow('ค่าไฟฟ้า', electricRate),
                      _buildDetailRow('ค่าน้ำ', waterRate, isLast: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFB7D6F5),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'StayEase Residence';
    final address = _addressController.text.isNotEmpty
        ? _addressController.text
        : '123 ถนนตัวอย่าง แขวงตัวอย่าง';
    final phone = _phoneController.text.isNotEmpty
        ? _phoneController.text
        : '098-000-0000';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x4DB7D6F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F8FDB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: const [
                Icon(Icons.apartment, size: 18, color: Color(0xFF4181CB)),
                SizedBox(width: 6),
                Text(
                  'ชื่อหอพัก',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4181CB),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFB7D6F5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSummaryLine(
                              Icons.location_on_outlined,
                              'ที่อยู่',
                              address,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFB7D6F5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryLine(
                              Icons.phone_outlined,
                              'โทรศัพท์',
                              phone,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4181CB)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 14,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x334CBB17),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 22, color: Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'พร้อมเริ่มจัดการหอพักแล้ว',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CBB17),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ตรวจสอบข้อมูลให้เรียบร้อยก่อนสร้างหอพัก',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF66996A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Noto Sans Thai',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4181CB),
      ),
    );
  }

  // ---- Bottom Buttons ----
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          if (_currentStep == 3) ...[
            _buildReadyBox(),
            const SizedBox(height: 12),
          ],
          SizedBox(
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
              child: _currentStep == 3
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apartment, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'สร้างหอพัก',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'ถัดไป',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _onCancelOrBack,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCFE0F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _currentStep > 1 ? 'ย้อนกลับ' : 'ยกเลิก',
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 16,
                  color: Color(0xFF4181CB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step Indicator ----
  Widget _buildStepIndicator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth - 16;
        final stepWidth = totalWidth / 3;
        final circleCenterX = stepWidth / 2;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            children: [
              Positioned(
                top: 14,
                left: circleCenterX,
                right: circleCenterX,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: 1 < _currentStep
                            ? const Color(0xFF4181CB)
                            : const Color(0xFFD9D9D9),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: 2 < _currentStep
                            ? const Color(0xFF4181CB)
                            : const Color(0xFFD9D9D9),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: stepWidth,
                    child: _buildStep(1, 'ข้อมูลหอพัก'),
                  ),
                  SizedBox(
                    width: stepWidth,
                    child: _buildStep(2, 'ตั้งค่าห้องพัก'),
                  ),
                  SizedBox(width: stepWidth, child: _buildStep(3, 'ยืนยัน')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep(int number, String label) {
    final active = number <= _currentStep;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF4181CB) : const Color(0xFFD9D9D9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 13,
            color: number == _currentStep
                ? const Color(0xFF4181CB)
                : const Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 15,
          color: Color(0xFF000000),
        ),
      ),
    );
  }

  Widget _buildLabelRequired(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 15,
            color: Color(0xFF000000),
          ),
          children: [
            TextSpan(text: text),
            const TextSpan(
              text: '  *',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller, {
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    VoidCallback? onEditingComplete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0x80B7D6F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: const Color(0xFF4181CB)),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onEditingComplete: onEditingComplete,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    color: Color(0xFF000000),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 15,
                      color: Color(0xFFAAAAAA),
                    ),
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
      ],
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
                'สร้างหอพักใหม่',
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
