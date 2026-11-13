import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_mate/user/rental_fee.dart';

void main() {
  testWidgets('การ์ดค่าเช่าแสดงผู้เช่าหลัก + Roommate', (tester) async {
    final breakdown = <Map<String, dynamic>>[
      {
        'name': 'พัชราวรรณ ศรีบุญ',
        'phone': '0289890000',
        'role': 'ผู้เช่าหลัก',
        'rent': 4500.0,
        'isMe': true,
        'isMainTenant': true,
      },
      {
        'name': 'จอน จองกุก',
        'phone': '0696896000',
        'role': 'Roommate',
        'rent': 3500.0,
        'isMe': false,
        'isMainTenant': false,
      },
    ];

    await tester.pumpWidget(MaterialApp(
      home: RentalFeeScreen(
        currentBill: const {
          'month': 'ตุลาคม 2569',
          'total': 5090,
          'status_label': 'รอชำระ',
          'due_date': '5 พฤศจิกายน 2569',
        },
        hasRoom: true,
        rentBreakdown: breakdown,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ค่าเช่ารายคนในห้อง'), findsOneWidget);
    expect(find.text('พัชราวรรณ ศรีบุญ (ฉัน)'), findsOneWidget);
    expect(find.text('จอน จองกุก'), findsOneWidget);
    expect(find.text('ผู้เช่าหลัก'), findsOneWidget);
    expect(find.text('Roommate'), findsOneWidget);
    expect(find.text('4,500'), findsOneWidget);
    expect(find.text('3,500'), findsOneWidget);
    expect(find.text('รวมค่าเช่าในห้อง'), findsOneWidget);
    expect(find.text('8,000 บาท'), findsOneWidget);
    expect(find.text('2 คน'), findsOneWidget);
  });

  testWidgets('การ์ดค่าเช่าไม่ล้นเมื่อมีสมาชิกเยอะและชื่อยาว', (tester) async {
    final breakdown = <Map<String, dynamic>>[
      for (var i = 0; i < 4; i++)
        {
          'name': 'ผู้เช่าคนที่ $i มีชื่อที่ยาวมากมาย',
          'phone': '080000000$i',
          'role': i == 0 ? 'ผู้เช่าหลัก' : 'Roommate',
          'rent': 12345.6,
          'isMe': i == 0,
          'isMainTenant': i == 0,
        },
    ];

    await tester.pumpWidget(MaterialApp(
      home: RentalFeeScreen(
        currentBill: const {'month': 'ตุลาคม 2569', 'total': 5090},
        hasRoom: true,
        rentBreakdown: breakdown,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('4 คน'), findsOneWidget);
    expect(find.text('49,382 บาท'), findsOneWidget);
  });
}
