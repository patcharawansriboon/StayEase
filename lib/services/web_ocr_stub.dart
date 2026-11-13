import 'dart:typed_data';

/// แพลตฟอร์มที่ไม่ใช่เว็บ (Android/iOS) ใช้ ML Kit แทน จึงไม่มี OCR ฝั่งเว็บ
Future<String?> recognizeDigitsOnWeb(Uint8List bytes) async => null;

/// ไม่ใช่เว็บ จึงไม่ใช่เบราว์เซอร์คอมพิวเตอร์
bool isDesktopWebBrowser() => false;

/// ไม่ใช่เว็บ: ไม่มีกล้องเว็บแคม (ใช้ image_picker แทน)
Future<Uint8List?> captureWebcamPhoto() async => null;
