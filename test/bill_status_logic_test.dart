import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_mate/build_tenant_bill.dart';

void main() {
  testWidgets('เดือนของบิลตรงกับรอบปัจจุบันหรือไม่', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: BuildTenantBillScreen()));

    final state = tester.state<BuildTenantBillScreenState>(
        find.byType(BuildTenantBillScreen));

    const thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    final now = DateTime.now();
    final currentPeriod = '${thaiMonths[now.month - 1]} ${now.year + 543}';
    final year = '${now.year + 543}';
    final monthNum = now.month.toString().padLeft(2, '0');

    expect(state.isCurrentBillPeriod(currentPeriod), isTrue);
    expect(state.isCurrentBillPeriod('$year-$monthNum'), isTrue);
    expect(state.isCurrentBillPeriod('$monthNum/$year'), isTrue);
    expect(state.isCurrentBillPeriod(''), isTrue);
    expect(state.isCurrentBillPeriod(null), isTrue);

    // เดือนอื่น → ยังไม่ถือว่าสร้างแล้ว
    expect(state.isCurrentBillPeriod('กรกฎาคม 2560'), isFalse);
    expect(state.isCurrentBillPeriod('2560-01'), isFalse);
  });
}
