import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class RentalInformationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final String userName;
  final String userPhone;
  final Map<String, String> rentalInfo;
  final bool showSavedToast;
  final VoidCallback? onToastShown;

  const RentalInformationScreen({
    super.key,
    this.onBack,
    this.onEdit,
    this.userName = 'พัชราวรรณ  ศรีบุญ',
    this.userPhone = '099-0000000',
    this.rentalInfo = const {},
    this.showSavedToast = false,
    this.onToastShown,
  });

  @override
  State<RentalInformationScreen> createState() =>
      _RentalInformationScreenState();
}

class _RentalInformationScreenState extends State<RentalInformationScreen> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    if (widget.showSavedToast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showSavedToast();
        widget.onToastShown?.call();
      });
    }
  }

  void _showSavedToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 2,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: const Row(
          children: [
            Expanded(
              child: Text(
                'บันทึกเรียบร้อย',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            Icon(Icons.check, size: 22, color: Color(0xFF000000)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  String _val(String key, String fallback, String placeholder) {
    final v = widget.rentalInfo[key] ?? '';
    if (v.isNotEmpty) return v;
    return fallback.isNotEmpty ? fallback : placeholder;
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
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
                                color: const Color(0xFF4F8FDB), width: 2),
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(_profileImage!, fit: BoxFit.cover)
                                : const Icon(
                                    Icons.person_outline,
                                    size: 32,
                                    color: Color(0xFF4F8FDB),
                                  ),
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
                              child: const Icon(Icons.camera_alt,
                                  size: 11, color: Colors.white),
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
                      onEdit: widget.onEdit,
                      rows: [
                        _InfoRow('ชื่อ - นามสกุล',
                            _val('name', widget.userName, 'พัชราวรรณ  ศรีบุญ')),
                        _InfoRow(
                            'เลขบัตรประชาชน',
                            _val('idCard', '', 'กรุณากรอกเลขบัตรประชาชน'),
                            isPlaceholder: (widget.rentalInfo['idCard'] ?? '').isEmpty),
                        _InfoRow('วันเกิด',
                            _val('birthdate', '', 'กรุณากรอกวันเกิด'),
                            isPlaceholder:
                                (widget.rentalInfo['birthdate'] ?? '').isEmpty),
                        _InfoRow('เพศ', _val('gender', '', 'กรุณากรอกเพศ'),
                            isPlaceholder: (widget.rentalInfo['gender'] ?? '').isEmpty),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ข้อมูลการเช่า
                    _buildSection(
                      svgIcon: 'assets/images/home_rental.svg',
                      title: 'ข้อมูลการเช่า',
                      showEdit: false,
                      rows: [
                        _InfoRow('อาคาร', _val('building', '', 'A')),
                        _InfoRow('ห้อง', _val('room', '', 'A301')),
                        _InfoRow('ชั้น', _val('floor', '', '3')),
                        _InfoRow('วันที่เข้าพัก', _val('check_in', '', '1 มกราคม 2569')),
                        _InfoRow('สิ้นสุดสัญญา', _val('check_out', '', '31 ธันวาคม 2569')),
                        _InfoRow('ค่าเช่าห้อง', _val('rent', '', '4,500')),
                        _InfoRow('เงินประกัน', _val('deposit', '', '10,000')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ข้อมูลติดต่อ
                    _buildSection(
                      svgIcon: 'assets/images/phone_rental.svg',
                      title: 'ข้อมูลติดต่อ',
                      onEdit: widget.onEdit,
                      rows: [
                        _InfoRow('เบอร์โทร',
                            _val('phone', widget.userPhone, '099-0000000')),
                        _InfoRow('ที่อยู่',
                            _val('address', '', 'กรุณากรอกที่อยู่'),
                            isPlaceholder:
                                (widget.rentalInfo['address'] ?? '').isEmpty),
                        _InfoRow(
                            'ผู้ติดต่อฉุกเฉิน',
                            _val('emergencyContact', '', 'กรุณากรอกข้อมูล'),
                            isPlaceholder:
                                (widget.rentalInfo['emergencyContact'] ?? '').isEmpty),
                        _InfoRow(
                            'เบอร์โทรฉุกเฉิน',
                            _val('emergencyPhone', '', 'กรุณากรอกเบอร์โทร'),
                            isPlaceholder:
                                (widget.rentalInfo['emergencyPhone'] ?? '').isEmpty),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // เอกสารแนบ
                    _buildDocumentSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
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
                'ข้อมูลการเช่า',
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

  Widget _buildSection({
    IconData? icon,
    String? svgIcon,
    required String title,
    required List<_InfoRow> rows,
    bool showEdit = true,
    VoidCallback? onEdit,
  }) {
return Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: const Color(0xFFD9D9D9),
           width: 1,
         ),
       ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
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
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F8FDB),
                ),
              ),
              const Spacer(),
              if (showEdit)
                GestureDetector(
                  onTap: onEdit,
                  child: SvgPicture.asset(
                    'assets/images/pencil.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4F8FDB),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Rows
          ...rows.map((row) {
            return Column(
              children: [
                if (rows.indexOf(row) > 0)
                  const Divider(height: 1, color: Color(0xFFF5F5F5)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            row.value,
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: row.isPlaceholder
                                  ? const Color(0xFFD9D9D9)
                                  : const Color(0xFF000000),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
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
                        fontFamily: 'Prompt',
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
                      style:
                          TextStyle(fontFamily: 'Prompt', color: Colors.white),
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

  Widget _buildDocumentSection() {
    final raw = widget.rentalInfo['documents'] ?? '';
    // แต่ละบรรทัดรูปแบบ "ชื่อ|url"
    final documents = raw.isEmpty
        ? <Map<String, String>>[]
        : raw.split('\n').where((e) => e.trim().isNotEmpty).map((line) {
            final parts = line.split('|');
            return {
              'title': parts[0].trim(),
              'url': parts.length > 1 ? parts[1].trim() : '',
            };
          }).toList();

return Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: const Color(0xFFD9D9D9),
           width: 1,
         ),
       ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/images/note_rental.svg',
                  width: 26, height: 26),
              const SizedBox(width: 6),
              const Text(
                'เอกสารแนบ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F8FDB),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onEdit,
                child: SvgPicture.asset(
                  'assets/images/pencil.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF4F8FDB),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (documents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Text(
                  'เพิ่มเอกสาร',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD9D9D9),
                  ),
                ),
              ),
            )
          else
            ...documents.map((doc) {
              final title = doc['title'] ?? 'เอกสาร';
              final url = doc['url'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: url.isEmpty ? null : () => _previewDocument(title, url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 14,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                        if (url.isNotEmpty)
                          const Icon(Icons.visibility_outlined,
                              size: 18, color: Color(0xFF4F8FDB)),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isPlaceholder;

  _InfoRow(this.label, this.value, {this.isPlaceholder = false});
}
