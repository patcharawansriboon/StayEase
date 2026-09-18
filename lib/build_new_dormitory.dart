import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Step 2
  final _floorCountController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final _roomNumberFormatController = TextEditingController();
  int? _maxTenants; // จำนวนผู้เช่าสูงสุดต่อห้อง
  String? _roomArrangement; // 'empty' | 'occupied'

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _floorCountController.dispose();
    _totalRoomsController.dispose();
    _roomNumberFormatController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      final data = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'floorCount': int.tryParse(_floorCountController.text) ?? 1,
        'totalRooms': int.tryParse(_totalRoomsController.text) ?? 0,
        'roomNumberFormat': _roomNumberFormatController.text,
        'maxTenants': _maxTenants ?? 1,
        'roomArrangement': _roomArrangement ?? 'empty',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
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
        _buildInput(_nameController,
            hint: 'กรุณากรอกชื่อที่พัก', icon: Icons.home_outlined),
        const SizedBox(height: 16),
        _buildLabel('ที่อยู่หอพัก'),
        _buildInput(_addressController,
            hint: 'กรุณากรอกที่อยู่ของที่พัก',
            icon: Icons.location_on_outlined),
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
        ),
        const SizedBox(height: 16),
        _buildLabelRequired('จำนวนห้องพักทั้งหมด'),
        _buildInput(
          _totalRoomsController,
          hint: 'กรุณากรอกจำนวนห้องพักทั้งหมด',
          icon: Icons.meeting_room_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        _buildLabelRequired('รูปแบบเลขห้อง'),
        _buildInput(
          _roomNumberFormatController,
          hint: 'กรุณากรอกรูปแบบเลขห้อง',
          icon: Icons.tag,
        ),
        const SizedBox(height: 16),
        _buildLabelRequired('จำนวนผู้เช่าสูงสุดต่อห้อง'),
        _buildMaxTenantsDropdown(),
        const SizedBox(height: 16),
        _buildLabelRequired('รูปแบบการจัดห้อง'),
        const SizedBox(height: 4),
        _buildRadioOption(
          value: 'empty',
          title: 'ห้องว่าง ',
          hint: '(พร้อมให้เช่า)',
        ),
        _buildRadioOption(
          value: 'occupied',
          title: 'มีผู้เช่า ',
          hint: '(บางห้องมีผู้เช่าอยู่แล้ว)',
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_outline,
                  size: 18, color: Color(0xFF999999)),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _maxTenants,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF999999)),
                hint: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'กรุณากรอกจำนวนผู้เช่า',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 15,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  color: Color(0xFF000000),
                ),
                items: List.generate(6, (i) => i + 1)
                    .map((n) => DropdownMenuItem<int>(
                          value: n,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('$n คน'),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _maxTenants = v),
              ),
            ),
          ),
        ],
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
                  fontFamily: 'Prompt',
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
              Icon(Icons.lightbulb_outline,
                  size: 18, color: Color(0xFF4181CB)),
              SizedBox(width: 6),
              Text(
                'หมายเหตุ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4181CB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'ระบบจะสร้างห้องตามรูปแบบเลขห้องที่คุณกำหนด และคุณสามารถแก้ไขรายละเอียดห้องแต่ละห้องได้ในภายหลัง',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 12,
              color: Color(0xFF666666),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step 3: ยืนยัน ----
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ตรวจสอบข้อมูล'),
        const SizedBox(height: 12),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildSectionTitle('ข้อมูลหอพัก'),
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
    final phone =
        _phoneController.text.isNotEmpty ? _phoneController.text : '098-000-0000';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปหอพัก (placeholder)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ชื่อหอพัก',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                const Divider(height: 16, color: Color(0xFFF0F0F0)),
                _buildSummaryLine(
                    Icons.location_on_outlined, 'ที่อยู่หอพัก', address),
                const SizedBox(height: 8),
                _buildSummaryLine(
                    Icons.phone_outlined, 'เบอร์โทรศัพท์', phone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4181CB)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
        color: const Color(0xFFE6F6E9),
        borderRadius: BorderRadius.circular(12),
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
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ตรวจสอบข้อมูลให้เรียบร้อยก่อนสร้างหอพัก',
                  style: TextStyle(
                    fontFamily: 'Prompt',
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
        fontFamily: 'Prompt',
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
                backgroundColor: const Color(0xFF5B93D4),
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
                            fontFamily: 'Prompt',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'ถัดไป',
                      style: TextStyle(
                        fontFamily: 'Prompt',
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
                  fontFamily: 'Prompt',
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
                  SizedBox(
                    width: stepWidth,
                    child: _buildStep(3, 'ยืนยัน'),
                  ),
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
                fontFamily: 'Prompt',
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
            fontFamily: 'Prompt',
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
          fontFamily: 'Prompt',
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
            fontFamily: 'Prompt',
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
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF999999)),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 15,
                color: Color(0xFF000000),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  color: Color(0xFFAAAAAA),
                ),
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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
                'สร้างหอพักใหม่',
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
