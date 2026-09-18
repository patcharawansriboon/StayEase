import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditeTenantScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  const EditeTenantScreen({
    super.key,
    this.onBack,
    this.onSave,
  });

  @override
  State<EditeTenantScreen> createState() => _EditeTenantScreenState();
}

class _EditeTenantScreenState extends State<EditeTenantScreen> {
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _floorController = TextEditingController();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();

  final List<String> _months = [
    'ม.ค', 'ก.พ', 'มี.ค', 'เม.ย', 'พ.ค', 'มิ.ย',
    'ก.ค', 'ส.ค', 'ก.ย', 'ต.ค', 'พ.ย', 'ธ.ค'
  ];

  final List<String> _monthsFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
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
                            onSelectedItemChanged: (i) =>
                                setModalState(() => _selectedDay = (i % 31) + 1),
                            children: List.generate(31,
                                (i) => _pickerItem('${i + 1}')),
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
                            children: _months
                                .map((m) => _pickerItem(m))
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: _selectedYear - 2540),
                            itemExtent: 40,
                            looping: true,
                            onSelectedItemChanged: (i) =>
                                setModalState(() => _selectedYear = (i % 30) + 2540),
                            children: List.generate(
                                30,
                                (i) => _pickerItem('${i + 2540}')),
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
                  _buildPersonalSection(),
                  const SizedBox(height: 12),
                  _buildRentalSection(),
                  const SizedBox(height: 12),
                  _buildDocumentSection(),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
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
          ],
        ),
      ],
    );
  }

  // ---- ข้อมูลส่วนตัว (readonly เทา) ----
  Widget _buildPersonalSection() {
    return _buildCard(
      title: 'ข้อมูลส่วนตัว',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadOnlyField('ชื่อ-นามสกุล', 'พัชราวรรณ  ศรีบุญ'),
          _buildReadOnlyField('เบอร์มือถือ', '098-9890000'),
          _buildReadOnlyField('เลขบัตรประชาชน', '1-2-009-00000-000'),
          _buildReadOnlyField('วันเกิด', '26 กันยายน 2547'),
          _buildReadOnlyField('เพศ', 'หญิง'),
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
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFD9D9D9)),
                ),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      'กำลังเช่า',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: Color(0xFF999999)),
                ],
              ),
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
              child: _buildUnderlineInput(_checkInController, 'กรุณากรอกวันที่เริ่มสัญญา',
                  suffixIcon: GestureDetector(
                    onTap: () => _showDatePicker(_checkInController),
                    child: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF999999)),
                  )),
            ),
          ),
          const SizedBox(height: 12),
          _buildLabel('วันที่สิ้นสุด'),
          GestureDetector(
            onTap: () => _showDatePicker(_checkOutController),
            child: AbsorbPointer(
              child: _buildUnderlineInput(_checkOutController, 'กรุณากรอกวันที่หมดสัญญา',
                  suffixIcon: GestureDetector(
                    onTap: () => _showDatePicker(_checkOutController),
                    child: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF999999)),
                  )),
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
                    _buildUnderlineInput(_rentController, '0000.00 บาท',
                        textAlign: TextAlign.right),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelWithUnit('เงินประกัน', '(บาท)'),
                    _buildUnderlineInput(_depositController, '0000.00 บาท',
                        textAlign: TextAlign.right),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- เอกสารแนบ ----
  Widget _buildDocumentSection() {
    return _buildCard(
      title: 'เอกสารแนบ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Prompt',
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
            fontFamily: 'Prompt',
            fontSize: 14,
            color: Color(0xFF000000),
          ),
          children: [
            TextSpan(text: '$text '),
            TextSpan(
              text: unit,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
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
              fontFamily: 'Prompt',
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
                fontFamily: 'Prompt',
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
        fontFamily: 'Prompt',
        fontSize: 14,
        color: Color(0xFF000000),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Prompt',
          fontSize: 14,
          color: Color(0xFFCCCCCC),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        suffixIcon: suffixIcon,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 24, minHeight: 24),
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
              fontFamily: 'Prompt',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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
                    fontFamily: 'Prompt',
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
                            fontFamily: 'Prompt',
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
                          Navigator.pop(context);
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
                            fontFamily: 'Prompt',
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
