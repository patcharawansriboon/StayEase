import 'package:flutter/material.dart';

/// เนื้อหา + ปุ่มด้านล่างที่เลื่อนไปด้วยกัน (แบบเดียวกับการ์ดในหน้า sign_in)
///
/// - ปกติ (ไม่มีแป้นพิมพ์): [bottom] อยู่ติดขอบล่างของพื้นที่เหมือนเดิม
/// - แป้นพิมพ์ขึ้น พื้นที่หดลง: เนื้อหากับปุ่มอยู่ในส่วนที่เลื่อนได้เดียวกัน
///   ปุ่มจึงไม่ลอยขึ้นมาค้างเหนือแป้นพิมพ์ ผู้ใช้เลื่อนลงเพื่อเห็นปุ่ม
///   และ Flutter เลื่อนช่องที่โฟกัสให้พ้นแป้นพิมพ์อัตโนมัติ
class KeyboardSafeScroll extends StatelessWidget {
  const KeyboardSafeScroll({
    super.key,
    required this.content,
    this.bottom,
    this.padding = EdgeInsets.zero,
  });

  /// เนื้อหาหลัก (ฟอร์ม)
  final Widget content;

  /// ปุ่มหรือแถบปุ่มด้านล่าง (ใส่ padding ของตัวเองมาแล้ว)
  final Widget? bottom;

  /// ระยะรอบ [content] (เดิมคือ padding ของ SingleChildScrollView)
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            // ขั้นต่ำเท่าความสูงพื้นที่ → spaceBetween ดัน bottom ลงไปติดขอบล่าง
            // ถ้าเนื้อหาสูงกว่าพื้นที่ (เช่น แป้นพิมพ์ขึ้น) จะเลื่อนได้ทั้งก้อน
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: padding, child: content),
                if (bottom != null) bottom!,
              ],
            ),
          ),
        );
      },
    );
  }
}
