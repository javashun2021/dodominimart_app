// 运行方式: flutter run -d windows --target tool/capture_icon.dart
// 会在 web/app_icon.png 生成 1024x1024 的 Logo PNG，然后自动退出
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../lib/core/widgets/dodo_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _IconCapture());
}

class _IconCapture extends StatefulWidget {
  const _IconCapture();
  @override
  State<_IconCapture> createState() => _IconCaptureState();
}

class _IconCaptureState extends State<_IconCapture> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    // 等一帧，确保 widget 完全渲染
    await Future.delayed(const Duration(milliseconds: 300));
    final boundary =
        _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    // pixelRatio: 2.0 → 512 logical × 2 = 1024 物理像素
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final file = File('web/app_icon.png');
    await file.writeAsBytes(bytes);
    // ignore: avoid_print
    print('✅ 图标已保存到 ${file.absolute.path}');
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: RepaintBoundary(
            key: _key,
            // 512 逻辑像素 × pixelRatio 2.0 = 1024 物理像素
            child: const DodoLogo(size: 512, showShadow: false),
          ),
        ),
      ),
    );
  }
}
