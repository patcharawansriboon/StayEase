import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_mate/user/report_a_repair.dart';

const String fontDir =
    '/var/folders/7q/jz14gfds47g3339lt4dfy8lw0000gn/T/kilo/fonts';
const String outFile =
    '/var/folders/7q/jz14gfds47g3339lt4dfy8lw0000gn/T/kilo/render.png';

void main() {
  testWidgets('render report a repair screen', (tester) async {
    final loader = FontLoader('Prompt');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('$fontDir/Prompt-$w.ttf').readAsBytesSync();
      loader.addFont(
          Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    }
    await loader.load();

    tester.view.physicalSize = const Size(375, 817);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Prompt'),
        home: const RepaintBoundary(
          key: ValueKey('root'),
          child: UserReportARepairScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('root')));
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(outFile).writeAsBytesSync(data!.buffer.asUint8List());
    print('wrote $outFile');
  });
}
