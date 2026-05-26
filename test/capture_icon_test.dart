// 运行: flutter test test/capture_icon_test.dart
// 生成 web/app_icon.png（1024×1024），然后再运行 dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dodominimart/core/widgets/dodo_logo.dart';

void main() {
  testWidgets('generate app_icon.png', (WidgetTester tester) async {
    // 512 逻辑像素 × pixelRatio 2.0 = 1024 物理像素
    tester.view.physicalSize = const Size(512, 512);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: RepaintBoundary(
            key: repaintKey,
            child: const DodoLogo(size: 512, showShadow: false),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final file = File('web/app_icon.png');
    await file.writeAsBytes(bytes);
    // ignore: avoid_print
    print('✅ 图标已保存：${file.absolute.path}  (${bytes.length} bytes)');
  });
}
