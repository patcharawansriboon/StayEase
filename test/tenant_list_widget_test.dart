import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_mate/tenant.dart';

List<Map<String, String>> _sampleTenants() => [
      {
        'name': 'พัชราวรรณ ศรีบุญ',
        'room': 'A101',
        'role': 'ผู้เช่าหลัก',
        'phone': '0289890000',
        'status': 'กำลังเช่า',
        'member_id': 'm1',
      },
      {
        'name': 'จอน จองกุก',
        'room': 'A101',
        'role': 'Roommate',
        'phone': '0696896000',
        'status': 'กำลังเช่า',
        'member_id': 'm2',
      },
      {
        'name': 'ณัฐพล เงาศรี',
        'room': 'A103',
        'role': 'ผู้เช่าหลัก',
        'phone': '0897826999',
        'status': 'รอการอนุมัติ',
        'member_id': 'm3',
      },
    ];

void main() {
  testWidgets('หน้าผู้เช่าแสดงทั้งผู้เช่าหลักและ Roommate', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TenantScreen(tenants: _sampleTenants()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('พัชราวรรณ ศรีบุญ'), findsOneWidget);
    expect(find.text('จอน จองกุก'), findsOneWidget);
    expect(find.text('ณัฐพล เงาศรี'), findsOneWidget);
    // บรรทัด "ห้อง • บทบาท" เป็น Text.rich → ต้องใช้ findRichText
    expect(find.textContaining('Roommate', findRichText: true), findsOneWidget);
    expect(
        find.textContaining('ผู้เช่าหลัก', findRichText: true), findsNWidgets(2));
  });

  testWidgets('ค้นหาด้วยชื่อหรือเลขห้อง', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TenantScreen(tenants: _sampleTenants()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A103');
    await tester.pumpAndSettle();

    expect(find.text('ณัฐพล เงาศรี'), findsOneWidget);
    expect(find.text('จอน จองกุก'), findsNothing);
  });

  testWidgets('ตัวกรองว่าง/รอ แสดงเฉพาะรายการที่ยังไม่ได้เช่า', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TenantScreen(tenants: _sampleTenants()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ว่าง/รอ'));
    await tester.pumpAndSettle();

    expect(find.text('ณัฐพล เงาศรี'), findsOneWidget);
    expect(find.text('จอน จองกุก'), findsNothing);
  });
}
