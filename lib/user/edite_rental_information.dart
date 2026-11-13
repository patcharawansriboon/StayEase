import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_sizes.dart';
import '../widgets/keyboard_safe_scroll.dart';

class EditeRentalInformationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<Map<String, String>>? onSave;
  final VoidCallback? onNavigateToMap;
  final String avatarUrl;
  final ValueChanged<String>? onAvatarChanged;
  final String userName;
  final String userPhone;
  final Map<String, String> rentalInfo;

  const EditeRentalInformationScreen({
    super.key,
    this.onBack,
    this.onSave,
    this.onNavigateToMap,
    this.avatarUrl = '',
    this.onAvatarChanged,
    this.userName = 'พัชราวรรณ  ศรีบุญ',
    this.userPhone = '099-0000000',
    this.rentalInfo = const {},
  });

  @override
  State<EditeRentalInformationScreen> createState() =>
      _EditeRentalInformationScreenState();
}

class _EditeRentalInformationScreenState
    extends State<EditeRentalInformationScreen> {
  final _nameController = TextEditingController(text: 'พัชราวรรณ  ศรีบุญ');
  final _idCardController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _genderController = TextEditingController();
  final _buildingController = TextEditingController(text: 'A');
  final _roomController = TextEditingController(text: 'A301');
  final _floorController = TextEditingController(text: '3');
  final _checkInController = TextEditingController(text: '1 มกราคม 2569');
  final _checkOutController = TextEditingController(text: '31 ธันวาคม 2569');
  final _rentController = TextEditingController(text: '4,500');
  final _depositController = TextEditingController(text: '10,000');
  final _phoneController = TextEditingController(text: '099-0000000');
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final FocusNode _idCardFocusNode = FocusNode();
  bool _idCardError = false;
  Uint8List? _profileImageBytes;

  final List<Map<String, dynamic>> _attachments = []; // {file, title}
  final List<String> _removedDocumentUrls =
      []; // url ของเอกสารที่ถูกลบ (รอลบไฟล์ตอนบันทึก)

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
      // ignore: avoid_print
      print('❌ delete document file error: $e');
    }
  }

  /// กดลบเอกสารแนบ (ยังไม่ลบไฟล์จริงจนกว่าจะกดบันทึก)
  Future<void> _deleteAttachment(int index) async {
    final att = _attachments[index];
    final title = (att['title'] as String?) ?? 'เอกสาร';
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
          'ต้องการลบ "$title" ใช่หรือไม่?',
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

    final url = (att['url'] as String?) ?? '';
    setState(() {
      _attachments.removeAt(index);
      if (url.isNotEmpty) _removedDocumentUrls.add(url);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() => _profileImageBytes = bytes);
      try {
        final db = Supabase.instance.client;
        final uid = db.auth.currentUser?.id;
        if (uid != null) {
          final ext = picked.path.split('.').last;
          final path =
              'avatars/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await db.storage
              .from('dormitory-images')
              .uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
          final url = db.storage.from('dormitory-images').getPublicUrl(path);
          await db.from('tenants').update({'avatar_url': url}).eq('id', uid);
          await db
              .from('roommate_invites')
              .update({'avatar_url': url})
              .eq('id', uid);
          widget.onAvatarChanged?.call(url);
        }
      } catch (e) {
        debugPrint('avatar upload error: $e');
      }
    }
  }

  Future<void> _pickAndAddFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    final titleController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ชื่อหัวข้อเอกสาร',
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Noto Sans Thai', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'กรุณากรอกชื่อหัวข้อ',
            hintStyle: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              color: Color(0xFFAAAAAA),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4F8FDB)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
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
              backgroundColor: const Color(0xFF4F8FDB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'เพิ่ม',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _attachments.add({
          'file': File(picked.path),
          'bytes': bytes,
          'fileName': picked.name,
          'title': titleController.text.isNotEmpty
              ? titleController.text
              : picked.name,
          'url': '', // ยังไม่อัปโหลด
        });
      });
    }
  }

  // อัปโหลดเอกสารที่ยังไม่มี url ขึ้น Supabase Storage
  // คืนข้อความ "ชื่อ|url" บรรทัดละ 1 รายการ
  Future<String> _uploadDocuments() async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id ?? 'anon';

    // ลบไฟล์เอกสารที่ผู้ใช้กดลบออกจาก Storage
    for (final url in _removedDocumentUrls) {
      await _deleteFileFromStorage(url);
    }
    _removedDocumentUrls.clear();

    final lines = <String>[];
    for (final att in _attachments) {
      final title = (att['title'] as String?) ?? 'เอกสาร';
      var url = (att['url'] as String?) ?? '';
      final bytes = att['bytes'];
      // ถ้ายังไม่มี url และมีไฟล์ใหม่ → อัปโหลด
      if (url.isEmpty && bytes != null) {
        try {
          final fileName = (att['fileName'] as String?) ?? 'doc.png';
          final ext = fileName.contains('.') ? fileName.split('.').last : 'png';
          final path =
              'documents/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await db.storage
              .from('dormitory-images')
              .uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
          url = db.storage.from('dormitory-images').getPublicUrl(path);
        } catch (e) {
          // ignore: avoid_print
          print('❌ upload document error: $e');
        }
      }
      lines.add(url.isEmpty ? title : '$title|$url');
    }
    return lines.join('\n');
  }

  Widget _buildUploadButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachments.isNotEmpty) ...[
          ..._attachments.asMap().entries.map((entry) {
            final index = entry.key;
            final att = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/icon_document.svg',
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        att['title'] as String,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
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
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'อัปโหลดแล้ว',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ปุ่มลบเอกสาร
                        GestureDetector(
                          onTap: () => _deleteAttachment(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 15,
                              color: Color(0xFFE53935),
                            ),
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
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    color: Color(0xFF4F8FDB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

  int _selectedDay = 26;
  int _selectedMonth = 2;
  int _selectedYear = 2547;

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
                  // Handle bar
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
                  // ปุ่มตกลงมุมขวาบน
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
                        // Day
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
                        // Month
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
                        // Year
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

  final List<String> _genders = ['หญิง', 'ชาย'];
  int _selectedGender = 0;

  void _showGenderPicker() {
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
              height: 210,
              child: Column(
                children: [
                  // Handle bar
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
                  // ปุ่มตกลงมุมขวาบน
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _genderController.text = _genders[_selectedGender];
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
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: _selectedGender,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) =>
                          setModalState(() => _selectedGender = i),
                      children: _genders.map((g) => _pickerItem(g)).toList(),
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

  @override
  void initState() {
    super.initState();
    final info = widget.rentalInfo;
    _nameController.text = (info['name'] ?? '').isNotEmpty
        ? info['name']!
        : widget.userName;
    _phoneController.text = (info['phone'] ?? '').isNotEmpty
        ? info['phone']!
        : widget.userPhone;
    if ((info['idCard'] ?? '').isNotEmpty) {
      _idCardController.text = info['idCard']!;
    }
    if ((info['birthdate'] ?? '').isNotEmpty) {
      _birthdateController.text = info['birthdate']!;
    }
    if ((info['gender'] ?? '').isNotEmpty) {
      _genderController.text = info['gender']!;
    }
    if ((info['address'] ?? '').isNotEmpty) {
      _addressController.text = info['address']!;
    }
    if ((info['emergencyContact'] ?? '').isNotEmpty) {
      _emergencyContactController.text = info['emergencyContact']!;
    }
    if ((info['emergencyPhone'] ?? '').isNotEmpty) {
      _emergencyPhoneController.text = info['emergencyPhone']!;
    }
    // โหลดเอกสารเดิม (รูปแบบ "ชื่อ|url" บรรทัดละ 1 รายการ)
    final rawDocs = info['documents'] ?? '';
    if (rawDocs.isNotEmpty) {
      for (final line in rawDocs.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        _attachments.add({
          'title': parts[0].trim(),
          'url': parts.length > 1 ? parts[1].trim() : '',
          // ไม่มี bytes = เป็นเอกสารเดิมที่อัปโหลดแล้ว
        });
      }
    }
    _idCardFocusNode.addListener(() {
      if (!_idCardFocusNode.hasFocus) {
        final digits = _idCardController.text.replaceAll(RegExp(r'[^0-9]'), '');
        setState(() {
          _idCardError = digits.isNotEmpty && digits.length != 13;
        });
      }
    });
  }

  @override
  void didUpdateWidget(EditeRentalInformationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName && widget.userName.isNotEmpty) {
      _nameController.text = widget.userName;
    }
    if (oldWidget.userPhone != widget.userPhone &&
        widget.userPhone.isNotEmpty) {
      _phoneController.text = widget.userPhone;
    }
  }

  @override
  void dispose() {
    _idCardFocusNode.dispose();
    _nameController.dispose();
    _idCardController.dispose();
    _birthdateController.dispose();
    _genderController.dispose();
    _buildingController.dispose();
    _roomController.dispose();
    _floorController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: KeyboardSafeScroll(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                content: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF4F8FDB),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImageBytes != null
                                ? Image.memory(
                                    _profileImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : (widget.avatarUrl.isNotEmpty
                                      ? Image.network(
                                          widget.avatarUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.person_outline,
                                          size: 32,
                                          color: Color(0xFF4F8FDB),
                                        )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F8FDB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ข้อมูลส่วนตัว
                    _buildSection(
                      svgIcon: 'assets/images/user_rental.svg',
                      title: 'ข้อมูลส่วนตัว',
                      children: [
                        _buildLabel('ชื่อ - นามสกุล'),
                        _buildReadOnly(
                          _nameController.text,
                          suffixIcon: Icons.lock_outline,
                        ),
                        _buildLabel('เลขบัตรประชาชน'),
                        _buildInput(
                          _idCardController,
                          hint: 'กรุณากรอกเลขบัตรประชาชน',
                          keyboardType: TextInputType.number,
                          focusNode: _idCardFocusNode,
                          boxed: _idCardError,
                          boxedRadius: 6,
                          hasError: _idCardError,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _IdCardFormatter(),
                          ],
                        ),
                        if (_idCardError)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'กรุณากรอกเลขให้ครบ',
                              style: TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 12,
                                color: Color(0xFFFF0000),
                              ),
                            ),
                          ),
                        _buildLabel('วันเกิด'),
                        GestureDetector(
                          onTap: () => _showDatePicker(_birthdateController),
                          child: AbsorbPointer(
                            child: _buildInput(
                              _birthdateController,
                              hint: 'วว/ดด/ปปปป',
                              suffixIcon: Icons.calendar_month_outlined,
                            ),
                          ),
                        ),
                        _buildLabel('เพศ'),
                        GestureDetector(
                          onTap: _showGenderPicker,
                          child: AbsorbPointer(
                            child: _buildInput(
                              _genderController,
                              hint: 'เพศ',
                              suffixIcon: Icons.keyboard_arrow_down,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ข้อมูลการเช่า
                    _buildSection(
                      svgIcon: 'assets/images/home_rental.svg',
                      title: 'ข้อมูลการเช่า',
                      subtitle: '(แก้ไขโดยแอดมิน)',
                      isEditable: false,
                      children: [
                        _buildLabel('อาคาร'),
                        _buildReadOnly(_buildingController.text),
                        _buildLabel('ห้อง'),
                        _buildReadOnly(_roomController.text),
                        _buildLabel('ชั้น'),
                        _buildReadOnly(_floorController.text),
                        _buildLabel('วันที่เข้าพัก'),
                        _buildReadOnly(
                          _checkInController.text,
                          suffixIcon: Icons.calendar_month_outlined,
                        ),
                        _buildLabel('วันที่สิ้นสุดสัญญา'),
                        _buildReadOnly(
                          _checkOutController.text,
                          suffixIcon: Icons.calendar_month_outlined,
                        ),
                        _buildLabel('ค่าเช่าห้อง'),
                        _buildReadOnly(_rentController.text),
                        _buildLabel('เงินประกัน'),
                        _buildReadOnly(_depositController.text),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ข้อมูลติดต่อ
                    _buildSection(
                      svgIcon: 'assets/images/phone_rental.svg',
                      title: 'ข้อมูลติดต่อ',
                      children: [
                        _buildLabel('เบอร์โทร'),
                        _buildReadOnly(
                          _phoneController.text,
                          suffixIcon: Icons.lock_outline,
                        ),
                        _buildLabel('ที่อยู่'),
                        GestureDetector(
                          onTap: widget.onNavigateToMap,
                          child: AbsorbPointer(
                            child: _buildInput(
                              _addressController,
                              hint: 'กรุณากรอกที่อยู่',
                              suffixIcon: Icons.chevron_right,
                            ),
                          ),
                        ),
                        _buildLabel('ผู้ติดต่อฉุกเฉิน'),
                        _buildInput(
                          _emergencyContactController,
                          hint: 'กรุณากรอกข้อมูล',
                        ),
                        _buildLabel('เบอร์โทรฉุกเฉิน'),
                        _buildInput(
                          _emergencyPhoneController,
                          hint: 'กรุณากรอกเบอร์โทร',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // เอกสารแนบ
                    _buildSection(
                      svgIcon: 'assets/images/note_rental.svg',
                      title: 'เอกสารแนบ',
                      children: [_buildUploadButton()],
                    ),
                  ],
                ),
                bottom: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _showSaveDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F8FDB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'คุณต้องการยกเลิกการแก้ไขใช่ไหม?',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          Navigator.pop(context);
                          widget.onBack?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F8FDB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                        onPressed: () async {
                          Navigator.pop(context);
                          // อัปโหลดเอกสารขึ้น Storage ก่อน แล้วได้ string "ชื่อ|url"
                          final documents = await _uploadDocuments();
                          widget.onSave?.call({
                            'name': _nameController.text,
                            'idCard': _idCardController.text,
                            'birthdate': _birthdateController.text,
                            'gender': _genderController.text,
                            'phone': _phoneController.text,
                            'address': _addressController.text,
                            'emergencyContact':
                                _emergencyContactController.text,
                            'emergencyPhone': _emergencyPhoneController.text,
                            'documents': documents,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F8FDB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showBackDialog,
            child: const Icon(Icons.chevron_left, size: kBackIconSize),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'แก้ไขรายละเอียด',
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

  Widget _buildSection({
    IconData? icon,
    String? svgIcon,
    required String title,
    String? subtitle,
    bool isEditable = true,
    IconData? trailingIcon,
    String? trailingSvg,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (svgIcon != null)
                SvgPicture.asset(svgIcon, width: 26, height: 26)
              else
                Icon(icon, size: 18, color: const Color(0xFF4F8FDB)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F8FDB),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ],
              const Spacer(),
              if (trailingSvg != null)
                SvgPicture.asset(trailingSvg, width: 22, height: 22)
              else if (trailingIcon != null)
                Icon(trailingIcon, size: 18, color: const Color(0xFF4F8FDB)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {double topPadding = 12}) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 4),
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

  Widget _buildInput(
    TextEditingController controller, {
    String? hint,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool boxed = false,
    double boxedRadius = 8,
    FocusNode? focusNode,
    bool hasError = false,
    bool readOnly = false,
    double bottomPadding = 4,
  }) {
    final borderColor = hasError
        ? const Color(0xFFFF0000)
        : const Color(0xFFE0E0E0);
    final focusColor = hasError
        ? const Color(0xFFFF0000)
        : const Color(0xFF4F8FDB);
    if (boxed) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(boxedRadius),
          border: Border.all(color: borderColor),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: readOnly ? const Color(0xFF888888) : const Color(0xFF000000),
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD9D9D9),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(boxedRadius),
              borderSide: BorderSide(color: focusColor),
            ),
            suffixIcon: suffixIcon != null
                ? (suffixIcon == Icons.calendar_month_outlined
                      ? GestureDetector(
                          onTap: () => _showDatePicker(controller),
                          child: Icon(
                            suffixIcon,
                            size: 18,
                            color: const Color(0xFFAAAAAA),
                          ),
                        )
                      : Icon(
                          suffixIcon,
                          size: 18,
                          color: const Color(0xFFAAAAAA),
                        ))
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
          ),
        ),
      );
    }
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontFamily: 'Noto Sans Thai',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: readOnly ? const Color(0xFF888888) : const Color(0xFF000000),
      ),
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFD9D9D9),
        ),
        contentPadding: EdgeInsets.only(top: 0, bottom: bottomPadding),
        isDense: true,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: focusColor),
        ),
        suffixIcon: suffixIcon != null
            ? (suffixIcon == Icons.calendar_month_outlined
                  ? GestureDetector(
                      onTap: () => _showDatePicker(controller),
                      child: Icon(
                        suffixIcon,
                        size: 18,
                        color: const Color(0xFFAAAAAA),
                      ),
                    )
                  : Icon(suffixIcon, size: 18, color: const Color(0xFFAAAAAA)))
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
      ),
    );
  }

  Widget _buildReadOnly(String value, {IconData? suffixIcon}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
          ),
          if (suffixIcon != null)
            Icon(suffixIcon, size: 18, color: const Color(0xFFAAAAAA)),
        ],
      ),
    );
  }
}

class _IdCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // เก็บเฉพาะตัวเลข สูงสุด 13 ตัว
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }

    // format: X-XXXX-XXXXX-XX-X
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 0 || i == 4 || i == 9 || i == 11) {
        if (i != digits.length - 1) buffer.write('-');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
