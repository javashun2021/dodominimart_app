// 运行: dart run tool/generate_icon.dart
// 生成 web/app_icon.png (1024×1024)，与 DodoLogo widget 同色系
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

const int S = 1024; // 输出尺寸

// 判断点 (px, py) 是否在圆角矩形内
bool _inRR(double px, double py, double x, double y, double w, double h, double r) {
  if (px < x || px >= x + w || py < y || py >= y + h) return false;
  if (px < x + r && py < y + r) return _dist(px, py, x + r, y + r) <= r;
  if (px >= x + w - r && py < y + r) return _dist(px, py, x + w - r, y + r) <= r;
  if (px < x + r && py >= y + h - r) return _dist(px, py, x + r, y + h - r) <= r;
  if (px >= x + w - r && py >= y + h - r) return _dist(px, py, x + w - r, y + h - r) <= r;
  return true;
}

double _dist(double ax, double ay, double bx, double by) =>
    sqrt(pow(ax - bx, 2) + pow(ay - by, 2));

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

// 以 alpha 混合把白色叠加到某像素上
void _blendWhite(img.Image image, int x, int y, double alpha) {
  if (x < 0 || x >= S || y < 0 || y >= S) return;
  final p = image.getPixel(x, y);
  final r = _lerp(p.r.toInt(), 255, alpha);
  final g = _lerp(p.g.toInt(), 255, alpha);
  final b = _lerp(p.b.toInt(), 255, alpha);
  image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
}

// 填充圆角矩形（白色，带透明度）
void _fillRR(img.Image image, double x, double y, double w, double h, double r, double alpha) {
  for (var py = y.round(); py < (y + h).round(); py++) {
    for (var px = x.round(); px < (x + w).round(); px++) {
      if (_inRR(px.toDouble(), py.toDouble(), x, y, w, h, r)) {
        _blendWhite(image, px, py, alpha);
      }
    }
  }
}

void main() async {
  final out = img.Image(width: S, height: S);

  // ── Step 1: 橙色渐变圆角背景 ────────────────────────────────────────────────
  final cornerR = S * 0.22;
  for (var y = 0; y < S; y++) {
    for (var x = 0; x < S; x++) {
      if (!_inRR(x.toDouble(), y.toDouble(), 0, 0, S.toDouble(), S.toDouble(), cornerR)) {
        continue; // 圆角外保持透明(0,0,0,0)
      }
      // 渐变: #FFB347(左上) → #E85D04(右下)
      final t = (x + y) / (2.0 * (S - 1));
      final rv = _lerp(0xFF, 0xE8, t);
      final gv = _lerp(0xB3, 0x5D, t);
      final bv = _lerp(0x47, 0x04, t);
      out.setPixel(x, y, img.ColorRgba8(rv, gv, bv, 255));
    }
  }

  // ── Step 2: 白色半透明内框（便利店招牌区）─────────────────────────────────
  final bw = S * 0.52;
  final bh = S * 0.35;
  final bx = (S - bw) / 2;
  final by = S * 0.18;
  _fillRR(out, bx, by, bw, bh, S * 0.09, 0.22);

  // ── Step 3: 白色 storefront 图标（简化几何）──────────────────────────────
  // 屋顶（扁矩形）
  final roofH = bh * 0.28;
  _fillRR(out, bx + bw * 0.06, by + bh * 0.06, bw * 0.88, roofH, S * 0.02, 0.92);

  // 店铺主体
  final bodyY = by + bh * 0.34;
  final bodyH = bh * 0.54;
  _fillRR(out, bx + bw * 0.06, bodyY, bw * 0.88, bodyH, S * 0.01, 0.80);

  // 门（中央白色矩形，不透明）
  final doorW = bw * 0.18;
  final doorH = bodyH * 0.55;
  final doorX = bx + (bw - doorW) / 2;
  final doorY = bodyY + bodyH - doorH;
  _fillRR(out, doorX, doorY, doorW, doorH, S * 0.015, 1.0);

  // ── Step 4: 三个小白点（霓虹灯效果）─────────────────────────────────────
  final dotR = (S * 0.025).round();
  final dotY = (by + bh + S * 0.055).round();
  for (var i = -1; i <= 1; i++) {
    final dotX = (S / 2 + i * S * 0.075).round();
    img.fillCircle(
      out,
      x: dotX,
      y: dotY,
      radius: dotR,
      color: img.ColorRgba8(255, 255, 255, 200),
      antialias: true,
    );
  }

  // ── Step 5: "DODO" 文字用矩形块拼出（D-O-D-O，图标小尺寸时也可辨识）──
  // 跳过：图标尺寸太小时文字无法辨识，品牌色+形状已足够

  // ── 保存 ─────────────────────────────────────────────────────────────────
  final bytes = img.encodePng(out);
  await File('web/app_icon.png').writeAsBytes(bytes);
  // ignore: avoid_print
  print('✅ web/app_icon.png 已生成 (${S}×${S}, ${bytes.length} bytes)');
}
