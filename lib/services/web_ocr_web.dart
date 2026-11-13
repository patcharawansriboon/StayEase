import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// ตัวช่วย JS ใน web/meter_ocr.js (ใช้ Tesseract.js อ่านเฉพาะตัวเลข)
@JS('stayeaseMeterOcr')
external JSPromise<JSString> _stayeaseMeterOcr(JSString dataUrl);

@JS('stayeaseIsDesktopBrowser')
external JSBoolean _stayeaseIsDesktopBrowser();

@JS('stayeaseCaptureWebcam')
external JSPromise<JSString> _stayeaseCaptureWebcam();

/// อ่านข้อความตัวเลขจากรูปบนเว็บ คืน null ถ้าอ่านไม่ได้ (เช่น โหลดไลบรารีไม่สำเร็จ)
Future<String?> recognizeDigitsOnWeb(Uint8List bytes) async {
  try {
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final result = await _stayeaseMeterOcr(dataUrl.toJS).toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('❌ web OCR error: $e');
    return null;
  }
}

/// true ถ้าเป็นเบราว์เซอร์บนคอมพิวเตอร์ (image_picker แบบกล้องเปิดไม่ได้ ต้องใช้เว็บแคม)
bool isDesktopWebBrowser() {
  try {
    return _stayeaseIsDesktopBrowser().toDart;
  } catch (_) {
    return false;
  }
}

/// เปิดหน้าต่างถ่ายรูปด้วยเว็บแคม
/// คืน null ถ้าผู้ใช้กดยกเลิก / ถ้าเปิดกล้องไม่ได้จะ throw ให้ผู้เรียกสำรองไปใช้ตัวเลือกไฟล์
Future<Uint8List?> captureWebcamPhoto() async {
  final dataUrl = (await _stayeaseCaptureWebcam().toDart).toDart;
  if (dataUrl.isEmpty) return null;
  return base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1));
}
