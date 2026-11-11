import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// หน้าสแกนมิเตอร์ — ถ่ายรูปมิเตอร์ + กรอก/ยืนยันเลขมิเตอร์
class ScanScreen extends StatefulWidget {
  /// ชื่อมิเตอร์ที่สแกน เช่น "มิเตอร์ไฟฟ้า" / "มิเตอร์น้ำ"
  final String meterTitle;

  /// เรียกเมื่อยืนยันเลข — ส่งค่าเลขมิเตอร์กลับ
  final void Function(String meterValue)? onConfirm;

  const ScanScreen({
    super.key,
    this.meterTitle = 'สแกนมิเตอร์ไฟฟ้า',
    this.onConfirm,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _photoBytes; // รูปที่ถ่าย
  bool _editing = false;
  bool _reading = false; // กำลังอ่านเลขจากรูป (OCR)
  String? _ocrError; // ข้อความเมื่ออ่านไม่ได้
  final _digitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // เปิดกล้องถ่ายรูปทันทีที่เข้าหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  @override
  void dispose() {
    _digitsController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    // ถ่ายด้วยความละเอียดสูงเพื่อให้ OCR อ่านเลขได้แม่นขึ้น
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      maxWidth: 2000,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _editing = false;
      _ocrError = null;
    });

    // อ่านเลขมิเตอร์จากรูปที่ถ่าย
    await _readMeterFromImage(picked.path);
  }

  /// ใช้ ML Kit OCR อ่านข้อความจากรูป แล้วดึงเฉพาะเลขมิเตอร์
  Future<void> _readMeterFromImage(String path) async {
    setState(() => _reading = true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(path);
      final result = await recognizer.processImage(inputImage);
      final meter = _extractMeterNumber(result);
      if (!mounted) return;
      setState(() {
        if (meter != null && meter.isNotEmpty) {
          _digitsController.text = meter;
          _ocrError = null;
        } else {
          _ocrError = 'อ่านเลขมิเตอร์ไม่สำเร็จ กรุณากรอกเอง';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ocrError = 'อ่านเลขมิเตอร์ไม่สำเร็จ กรุณากรอกเอง');
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _reading = false);
    }
  }

  /// เลือกชุดตัวเลขที่น่าจะเป็นเลขมิเตอร์มากที่สุดจากผล OCR
  ///
  /// รวบรวม "ชุดตัวเลขที่ติดกัน" จากทั้งระดับบรรทัดและระดับคำ (element)
  /// แล้วให้คะแนนเลือกชุดที่น่าจะเป็นเลขมิเตอร์:
  ///  - ความยาว 3-8 หลัก
  ///  - ยิ่งยาวยิ่งได้คะแนนสูง (เลขมิเตอร์มักยาว 4-6 หลัก)
  String? _extractMeterNumber(RecognizedText result) {
    final candidates = <String>[];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        // 1) ทั้งบรรทัด: ดึงเฉพาะชุดเลขที่ติดกัน
        candidates.addAll(_digitRuns(line.text));

        // 2) ระดับคำ: เผื่อ OCR แยกเลขออกเป็นหลาย element
        //    ลองต่อ element ที่เป็นเลขล้วนเข้าด้วยกัน
        final elementRun = StringBuffer();
        for (final el in line.elements) {
          final t = el.text.replaceAll(RegExp(r'\s'), '');
          if (RegExp(r'^\d+$').hasMatch(t)) {
            elementRun.write(t);
          } else {
            if (elementRun.isNotEmpty) {
              candidates.add(elementRun.toString());
              elementRun.clear();
            }
          }
          candidates.addAll(_digitRuns(el.text));
        }
        if (elementRun.isNotEmpty) candidates.add(elementRun.toString());
      }
    }

    // คัดเฉพาะ 3-8 หลัก แล้วเลือกตัวที่ยาวที่สุด (ถ้ายาวเท่ากันเลือกตัวแรก)
    String? best;
    for (final c in candidates) {
      if (c.length < 3 || c.length > 8) continue;
      if (best == null || c.length > best.length) best = c;
    }
    return best;
  }

  /// ดึงทุกชุดตัวเลขที่ติดกันออกจากข้อความ
  List<String> _digitRuns(String text) =>
      RegExp(r'\d+').allMatches(text).map((m) => m.group(0)!).toList();

  List<String> get _digits => _digitsController.text.split('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          // ---- พื้นที่กล้อง / รูปที่ถ่าย + กรอบมุมเหลือง ----
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhotoArea(),
                _buildCornerFrame(),
                if (_reading) _buildReadingOverlay(),
              ],
            ),
          ),
          // ---- ส่วนล่าง: เลขมิเตอร์ + ปุ่ม ----
          _buildBottomPanel(),
        ],
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
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.chevron_left,
                size: 28, color: Color(0xFF1A1A2E)),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.meterTitle,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  // ---- พื้นที่รูป ----
  Widget _buildPhotoArea() {
    if (_photoBytes != null) {
      return Image.memory(_photoBytes!, fit: BoxFit.cover);
    }
    // ยังไม่มีรูป → แสดงพื้นเทา + ปุ่มถ่าย
    return Container(
      color: const Color(0xFFEDEDED),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_outlined,
                size: 56, color: Color(0xFFAAAAAA)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8FDB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ถ่ายรูปมิเตอร์',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Overlay ขณะกำลังอ่านเลขจากรูป ----
  Widget _buildReadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'กำลังอ่านเลขมิเตอร์...',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- กรอบมุมเหลือง 4 มุม (viewfinder) ----
  Widget _buildCornerFrame() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _corner(topLeft: true)),
          Positioned(top: 0, right: 0, child: _corner(topRight: true)),
          Positioned(bottom: 0, left: 0, child: _corner(bottomLeft: true)),
          Positioned(bottom: 0, right: 0, child: _corner(bottomRight: true)),
        ],
      ),
    );
  }

  Widget _corner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    const color = Color(0xFFFFC107); // สีเหลือง
    const width = 4.0;
    final side = BorderSide(color: color, width: width);
    return SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: (topLeft || topRight) ? side : BorderSide.none,
            left: (topLeft || bottomLeft) ? side : BorderSide.none,
            right: (topRight || bottomRight) ? side : BorderSide.none,
            bottom: (bottomLeft || bottomRight) ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---- ส่วนล่าง: เลขมิเตอร์ + ปุ่ม ----
  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ตรวจพบเลขมิเตอร์',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          if (_ocrError != null) ...[
            const SizedBox(height: 6),
            Text(
              _ocrError!,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 12,
                color: Color(0xFFD32F2F),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // แถวเลขมิเตอร์ + ปุ่มดินสอ
          Row(
            children: [
              Expanded(
                child: _editing ? _buildEditField() : _buildDigitBoxes(),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _editing = !_editing),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _editing ? Icons.check : Icons.edit_outlined,
                    size: 20,
                    color: const Color(0xFF4F8FDB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ปุ่มยืนยันเลข
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _digitsController.text.isEmpty
                  ? null
                  : () => widget.onConfirm?.call(_digitsController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F8FDB),
                disabledBackgroundColor: const Color(0xFFBBBBBB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ยืนยันเลข',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ปุ่มถ่ายใหม่
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _takePhoto,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4F8FDB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'ถ่ายใหม่',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  color: Color(0xFF4F8FDB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- ช่องเลขแยกหลัก (อ่านอย่างเดียว) ----
  Widget _buildDigitBoxes() {
    final digits = _digits;
    return Row(
      children: List.generate(
        digits.isEmpty ? 6 : digits.length,
        (i) {
          final d = i < digits.length ? digits[i] : '';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 42,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD9D9D9)),
              ),
              child: Text(
                d,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- ช่องแก้ไขเลข ----
  Widget _buildEditField() {
    return TextField(
      controller: _digitsController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      autofocus: true,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        fontFamily: 'Prompt',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 8,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        hintText: 'กรอกเลขมิเตอร์',
        hintStyle: const TextStyle(
          fontFamily: 'Prompt',
          fontSize: 15,
          letterSpacing: 0,
          color: Color(0xFFAAAAAA),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4F8FDB)),
        ),
      ),
    );
  }
}
