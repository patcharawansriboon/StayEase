import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class ApplicationProcessScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSubmit;
  final String userName;
  final String userPhone;

  const ApplicationProcessScreen({
    super.key,
    this.onBack,
    this.onSubmit,
    this.userName = 'พัชราวรรณ  ศรีบุญ',
    this.userPhone = '089-0000000',
  });

  @override
  State<ApplicationProcessScreen> createState() =>
      _ApplicationProcessScreenState();
}

class _ApplicationProcessScreenState extends State<ApplicationProcessScreen> {
  int _currentStep = 1;

  final _idCardController = TextEditingController();
  final _dormCodeController = TextEditingController();
  final _roomController = TextEditingController();
  final _startDateController = TextEditingController();

  final List<Map<String, dynamic>> _attachments = []; // {file: File, title: String}

  @override
  void dispose() {
    _idCardController.dispose();
    _dormCodeController.dispose();
    _roomController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      widget.onSubmit?.call();
    }
  }

  void _onBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 20),
                    _buildUpgradeCard(),
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
      ),
    );
  }

  // ---- การ์ดเหลือง ----
  Widget _buildUpgradeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/icon_crown_2.svg',
            width: 60,
            height: 60,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ยกระดับเป็นผู้เช่าหลัก',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'เพื่อรับสิทธิ์ในการจัดการห้องและใช้งาน\nฟังชันเพิ่มเติมของหอพัก',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step 1: ข้อมูลส่วนตัว ----
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ข้อมูลส่วนตัว'),
        const SizedBox(height: 12),
        _buildLabel('ชื่อ - นามสกุล'),
        _buildReadOnly(widget.userName),
        const SizedBox(height: 12),
        _buildLabel('เบอร์โทรศัพท์'),
        _buildReadOnly(widget.userPhone),
        const SizedBox(height: 12),
        _buildLabel('เลขบัตรประชาชน'),
        _buildInput(
          _idCardController,
          hint: 'กรุณากรอกเลขบัตรประชาชน',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(13),
          ],
        ),
      ],
    );
  }

  // ---- Step 2: ข้อมูลห้องพัก ----
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ข้อมูลห้องพัก'),
        const SizedBox(height: 12),
        _buildLabel('รหัสหอพัก'),
        _buildInput(_dormCodeController, hint: 'กรุณากรอกรหัสหอพัก'),
        const SizedBox(height: 12),
        _buildLabel('ห้องที่ต้องการ'),
        _buildInput(_roomController, hint: 'กรุณากรอกเลขห้องที่ต้องการ'),
        const SizedBox(height: 12),
        _buildLabel('วันที่เริ่มอยู่'),
        GestureDetector(
          onTap: _showDatePicker,
          child: AbsorbPointer(
            child: _buildInput(
              _startDateController,
              hint: 'วว/ดด/ปปปป',
              suffixIcon: Icons.calendar_month_outlined,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('เอกสารประกอบ'),
        const SizedBox(height: 12),
        _buildUploadButton(),
      ],
    );
  }

  // ---- Step 3: ยืนยัน ----
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ยืนยันข้อมูล'),
        const SizedBox(height: 12),
        _buildConfirmRow('ชื่อ - นามสกุล', widget.userName),
        _buildConfirmRow('เบอร์โทรศัพท์', widget.userPhone),
        _buildConfirmRow(
            'เลขบัตรประชาชน',
            _idCardController.text.isNotEmpty ? _idCardController.text : '-'),
        _buildConfirmRow('รหัสหอพัก',
            _dormCodeController.text.isNotEmpty ? _dormCodeController.text : '-'),
        _buildConfirmRow('ห้องที่ต้องการ',
            _roomController.text.isNotEmpty ? _roomController.text : '-'),
        _buildConfirmRow(
            'วันที่เริ่มอยู่',
            _startDateController.text.isNotEmpty
                ? _startDateController.text
                : '-'),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('เอกสารประกอบ'),
          const SizedBox(height: 12),
          ..._attachments.map((att) => _buildConfirmDocRow(att['title'] as String)),
        ],
      ],
    );
  }

  Widget _buildConfirmDocRow(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            SvgPicture.asset('assets/images/icon_document.svg',
                width: 28, height: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 14,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAddFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;

    final titleController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ชื่อหัวข้อเอกสาร',
          style: TextStyle(fontFamily: 'Prompt', fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Prompt', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'กรุณากรอกชื่อหัวข้อ',
            hintStyle: const TextStyle(fontFamily: 'Prompt', fontSize: 14, color: Color(0xFFAAAAAA)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4F8FDB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(fontFamily: 'Prompt', color: Color(0xFFAAAAAA))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F8FDB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('เพิ่ม', style: TextStyle(fontFamily: 'Prompt', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _attachments.add({
          'file': File(picked.path),
          'title': titleController.text.isNotEmpty ? titleController.text : picked.name,
        });
      });
    }
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attachments.isNotEmpty) ...[
            ..._attachments.asMap().entries.map((entry) {
              final att = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/images/icon_document.svg', width: 28, height: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          att['title'] as String,
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 14,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 13, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'อัปโหลดแล้ว',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 2),
          ],
          GestureDetector(
            onTap: _pickAndAddFile,
            child: Container(
              width: double.infinity,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/upload.svg',
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'อัปโหลดไฟล์',
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 14,
                      color: Color(0xFF4F8FDB),
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

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Prompt',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4F8FDB),
      ),
    );
  }

  // ---- Bottom Buttons ----
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: _currentStep == 1
          ? SizedBox(
              width: double.infinity,
              height: 50,
              child: _primaryButton('ถัดไป', _onNext),
            )
          : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _onBack,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F8FDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ย้อนกลับ',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
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
                    child: _primaryButton(
                      _currentStep == 3 ? 'ยืนยัน' : 'ถัดไป',
                      _onNext,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F8FDB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Prompt',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---- Date Picker ----
  final List<String> _monthsFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];
  int _selectedDay = 1;
  int _selectedMonth = 0;
  int _selectedYear = 2569;

  void _showDatePicker() {
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
                            _startDateController.text =
                                '$_selectedDay ${_monthsFull[_selectedMonth]} $_selectedYear';
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(
                            fontFamily: 'Prompt',
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
                                initialItem: _selectedDay - 1),
                            itemExtent: 40,
                            looping: true,
                            onSelectedItemChanged: (i) => setModalState(
                                () => _selectedDay = (i % 31) + 1),
                            children: List.generate(
                                31, (i) => _pickerItem('${i + 1}')),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: _selectedMonth),
                            itemExtent: 40,
                            looping: true,
                            onSelectedItemChanged: (i) =>
                                setModalState(() => _selectedMonth = i % 12),
                            children: _monthsFull
                                .map((m) => _pickerItem(m))
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: _selectedYear - 2560),
                            itemExtent: 40,
                            looping: true,
                            onSelectedItemChanged: (i) => setModalState(
                                () => _selectedYear = (i % 20) + 2560),
                            children: List.generate(
                                20, (i) => _pickerItem('${i + 2560}')),
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
          fontFamily: 'Prompt',
          fontSize: 16,
          color: Color(0xFF000000),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth - 16; // หัก padding 8 แต่ละข้าง
        // แต่ละ step กว้างเท่ากัน
        final stepWidth = totalWidth / 3;
        final circleCenterX = stepWidth / 2;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            children: [
              // เส้นระหว่าง step 1 กับ 2
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
              // วงกลมและป้ายกำกับ
              Row(
                children: [
                  SizedBox(
                    width: stepWidth,
                    child: _buildStep(1, 'ข้อมูลส่วนตัว'),
                  ),
                  SizedBox(
                    width: stepWidth,
                    child: _buildStep(2, 'ข้อมูลห้องพัก'),
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

  Widget _buildReadOnly(String value) {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontFamily: 'Prompt',
          fontSize: 15,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller, {
    String? hint,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlignVertical: TextAlignVertical.center,
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
          isCollapsed: false,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 0,
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(suffixIcon, size: 18, color: const Color(0xFFAAAAAA)),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onBack?.call(),
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'สมัครเป็นผู้เช่าหลัก',
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
