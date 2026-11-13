import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edite_dormitory_settings.dart';

import 'widgets/app_sizes.dart';
class DormitorySettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DormitorySettingsScreen({super.key, this.onBack});

  @override
  State<DormitorySettingsScreen> createState() => DormitorySettingsScreenState();
}

// state class public เพื่อให้ main.dart เรียก reload() ผ่าน GlobalKey ได้
class DormitorySettingsScreenState extends State<DormitorySettingsScreen> {
  bool _isLoading = true;
  bool _editing = false;

  String _dormName = '';
  String _dormAddress = '';
  String _dormPhone = '';
  String _electricPrice = '0.00';
  String _waterPrice = '0.00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDormitoryData());
  }

  /// เรียกจาก main.dart ผ่าน GlobalKey ทุกครั้งที่ navigate มาหน้านี้
  void reload() {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _loadDormitoryData();
  }

  Future<void> _loadDormitoryData() async {
    final db = Supabase.instance.client;
    // retry เผื่อ auth session ยังไม่พร้อม (เหมือน dashboard.dart)
    String? uid = db.auth.currentUser?.id;
    if (uid == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      uid = db.auth.currentUser?.id;
    }
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final rows = await db
          .from('dormitories')
          .select('name, address, phone, electricity_rate, water_rate')
          .eq('created_by', uid)
          .limit(1);

      if (!mounted) return;

      if ((rows as List).isNotEmpty) {
        final row = rows.first as Map<String, dynamic>;

        // phone เก็บเป็น int ใน DB → ต้องคืนเลข 0 นำหน้า
        String phone = row['phone']?.toString() ?? '';
        if (phone.length == 9 && !phone.startsWith('0')) phone = '0$phone';

        final electric = row['electricity_rate'];
        final water = row['water_rate'];

        setState(() {
          _dormName = (row['name'] as String?) ?? '';
          _dormAddress = (row['address'] as String?) ?? '';
          _dormPhone = phone;
          _electricPrice = electric != null
              ? (electric is num
                      ? electric.toDouble()
                      : double.tryParse(electric.toString()) ?? 0)
                  .toStringAsFixed(2)
              : '0.00';
          _waterPrice = water != null
              ? (water is num
                      ? water.toDouble()
                      : double.tryParse(water.toString()) ?? 0)
                  .toStringAsFixed(2)
              : '0.00';
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('_loadDormitoryData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveRates(String electric, String water) async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await db.from('dormitories').update({
        'electricity_rate': double.tryParse(electric.replaceAll(',', '.')) ?? 0,
        'water_rate': double.tryParse(water.replaceAll(',', '.')) ?? 0,
      }).eq('created_by', uid);
    } catch (e) {
      debugPrint('_saveRates error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return EditeDormitorySettingsScreen(
        onBack: () => setState(() => _editing = false),
        initialElectric: _electricPrice,
        initialWater: _waterPrice,
        onSave: (e, w) async {
          await _saveRates(e, w);
          setState(() {
            _electricPrice = double.tryParse(e.replaceAll(',', '.')) != null
                ? double.parse(e.replaceAll(',', '.')).toStringAsFixed(2)
                : e;
            _waterPrice = double.tryParse(w.replaceAll(',', '.')) != null
                ? double.parse(w.replaceAll(',', '.')).toStringAsFixed(2)
                : w;
            _editing = false;
          });
        },
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(context),
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDormCard(),
                  const SizedBox(height: 16),
                  _buildMeterCard(),
                  const SizedBox(height: 16),
                  _buildWaterCard(),
                ],
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
            onTap: widget.onBack,
            child: const Icon(
              Icons.chevron_left,
              size: kBackIconSize,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Text(
              'หอพัก',
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
              children: [
                Text(
                  _dormName.isNotEmpty ? _dormName : '-',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dormAddress.isNotEmpty ? _dormAddress : '-',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dormPhone.isNotEmpty ? _dormPhone : '-',
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
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
               IconButton(
                 icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                 onPressed: () => setState(() => _editing = true),
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
               const Spacer(),
               SizedBox(
                width: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                   child: Text(
                    _electricPrice,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'บาท/หน่วย',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                ),
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
               IconButton(
                 icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                 onPressed: () => setState(() => _editing = true),
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
               const Spacer(),
               SizedBox(
                width: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                   child: Text(
                    _waterPrice,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'บาท/หน่วย',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
