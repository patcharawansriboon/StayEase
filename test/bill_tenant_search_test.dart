import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_mate/build_tenant_bill.dart';

List<Map<String, String>> _tenants() => [
      {
        'userId': 'u1',
        'name': 'พัชราวรรณ ศรีบุญ',
        'room': 'A101',
        'role': 'ผู้เช่าหลัก',
      },
      {
        'userId': 'u2',
        'name': 'จอน จองกุก',
        'room': 'A101',
        'role': 'Roommate',
      },
      {
        'userId': 'u3',
        'name': 'ณัฐพล เงาศรี',
        'room': 'A103',
        'role': 'ผู้เช่าหลัก',
      },
    ];

void main() {
  test('ค้นหาด้วยชื่อผู้เช่า', () {
    final result = BuildTenantBillScreenState.filterTenantsByKeyword(
        _tenants(), 'จอน');
    expect(result.length, 1);
    expect(result.first['name'], 'จอน จองกุก');
  });

  test('ค้นหาด้วยเลขห้อง', () {
    final result = BuildTenantBillScreenState.filterTenantsByKeyword(
        _tenants(), 'A103');
    expect(result.length, 1);
    expect(result.first['room'], 'A103');
  });

  test('ค้นหาแบบไม่ระบุตัวพิมพ์', () {
    final result = BuildTenantBillScreenState.filterTenantsByKeyword(
        _tenants(), 'a101');
    expect(result.length, 2);
  });

  test('ค้นหาด้วยบทบาท (Roommate)', () {
    final result = BuildTenantBillScreenState.filterTenantsByKeyword(
        _tenants(), 'Roommate');
    expect(result.length, 1);
    expect(result.first['name'], 'จอน จองกุก');
  });

  test('คำค้นว่าง → แสดงทั้งหมด', () {
    final result =
        BuildTenantBillScreenState.filterTenantsByKeyword(_tenants(), '  ');
    expect(result.length, 3);
  });

  test('ไม่พบรายการที่ค้นหา', () {
    final result = BuildTenantBillScreenState.filterTenantsByKeyword(
        _tenants(), 'zzz');
    expect(result.isEmpty, isTrue);
  });

  testWidgets('popup มีช่องค้นหา', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: BuildTenantBillScreen()));
    await tester.pumpAndSettle();

    // เปิด popup เลือกผู้เช่า
    final trigger = find.text('เลือกผู้เช่า').last;
    await tester.ensureVisible(trigger);
    await tester.pumpAndSettle();
    await tester.tap(trigger);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.hintText == 'ค้นหาชื่อผู้เช่าหรือเลขห้อง'),
      findsOneWidget,
    );
    expect(find.text('ค้นหาชื่อผู้เช่าหรือเลขห้อง'), findsOneWidget);
  });
}
