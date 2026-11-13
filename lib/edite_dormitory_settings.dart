import 'package:flutter/material.dart';

import 'widgets/app_sizes.dart';
import 'widgets/keyboard_safe_scroll.dart';

class EditeDormitorySettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String initialElectric;
  final String initialWater;
  final void Function(String electric, String water)? onSave;

  const EditeDormitorySettingsScreen({
    super.key,
    this.onBack,
    this.initialElectric = '00.00',
    this.initialWater = '00.00',
    this.onSave,
  });

  @override
  State<EditeDormitorySettingsScreen> createState() =>
      _EditeDormitorySettingsScreenState();
}

class _EditeDormitorySettingsScreenState
    extends State<EditeDormitorySettingsScreen> {
  late final _electricController = TextEditingController(
    text: widget.initialElectric,
  );
  late final _waterController = TextEditingController(
    text: widget.initialWater,
  );

  @override
  void dispose() {
    _electricController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: KeyboardSafeScroll(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMeterCard(),
                  const SizedBox(height: 16),
                  _buildWaterCard(),
                ],
              ),
              bottom: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      widget.onSave?.call(
                        _electricController.text,
                        _waterController.text,
                      );
                    },
                    child: const Text(
                      'บันทึก',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ยืนยัน'),
                  content: const Text('ต้องการย้อนกลับหรือไม่?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('ยกเลิก'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('ยืนยัน'),
                    ),
                  ],
                ),
              );
              if (ok == true) widget.onBack?.call();
            },
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Text(
              'ตั้งค่าหอพัก',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: kPageTitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7D6F5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.apartment, color: Color(0xFF4A90D9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'StayEase',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'จ.จันทบุรี',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '089-9900000',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE27F).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE27F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Color(0xFFB8860B)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'มิเตอร์ไฟฟ้า',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'ราคา/หน่วย',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _electricController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'บาท/หน่วย',
                style: TextStyle(fontFamily: 'Noto Sans Thai', fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB7D6F5).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F8FDB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: Color(0xFF4F8FDB)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'มิเตอร์น้ำ',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'ราคา/หน่วย',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _waterController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'บาท/หน่วย',
                style: TextStyle(fontFamily: 'Noto Sans Thai', fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
