// dart run tool/generate_icon.dart
// 2048×2048 绘制后缩至 1024×1024，自带抗锯齿
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

const int DS = 2048; // 绘制尺寸（2×）
const int OUT = 1024; // 输出尺寸

// ── 几何工具 ──────────────────────────────────────────────────────────────────

bool _inRR(double px, double py, double x, double y, double w, double h, double r) {
  if (px < x || px >= x + w || py < y || py >= y + h) return false;
  if (px < x + r && py < y + r) return _d(px, py, x + r, y + r) <= r;
  if (px >= x + w - r && py < y + r) return _d(px, py, x + w - r, y + r) <= r;
  if (px < x + r && py >= y + h - r) return _d(px, py, x + r, y + h - r) <= r;
  if (px >= x + w - r && py >= y + h - r) return _d(px, py, x + w - r, y + h - r) <= r;
  return true;
}

double _d(double ax, double ay, double bx, double by) =>
    sqrt(pow(ax - bx, 2) + pow(ay - by, 2));

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

// 以 alpha 混合白色覆盖到像素上
void _blendWhite(img.Image im, int px, int py, double alpha) {
  if (px < 0 || px >= DS || py < 0 || py >= DS || alpha <= 0) return;
  final p = im.getPixel(px, py);
  im.setPixel(px, py, img.ColorRgba8(
    _lerp(p.r.toInt(), 255, alpha),
    _lerp(p.g.toInt(), 255, alpha),
    _lerp(p.b.toInt(), 255, alpha),
    255,
  ));
}

void _fillRR(img.Image im, double x, double y, double w, double h, double r, double alpha) {
  for (var py = y.round() - 1; py <= (y + h).round() + 1; py++) {
    for (var px = x.round() - 1; px <= (x + w).round() + 1; px++) {
      if (_inRR(px.toDouble(), py.toDouble(), x, y, w, h, r)) {
        _blendWhite(im, px, py, alpha);
      }
    }
  }
}

// ── 字母绘制 ──────────────────────────────────────────────────────────────────

// 绘制字母 "D"（左竖条 + 右半椭圆环）
void _drawD(img.Image im, double x, double y, double w, double h) {
  final stroke = w * 0.30;      // 竖条宽度
  final cx = x + stroke;         // 曲线中心 x
  final cy = y + h * 0.5;        // 曲线中心 y
  final outerRx = w * 0.80;
  final outerRy = h * 0.50;
  final innerRx = outerRx - stroke * 0.90;
  final innerRy = outerRy - stroke * 0.90;

  for (var py = (y - 1).round(); py <= (y + h + 1).round(); py++) {
    for (var px = (x - 1).round(); px <= (x + w + 1).round(); px++) {
      if (px < 0 || px >= DS || py < 0 || py >= DS) continue;
      final lx = px.toDouble() - x;
      final ly = py.toDouble() - y;
      bool inside = false;

      // 左竖条
      if (lx >= 0 && lx <= stroke && ly >= 0 && ly <= h) {
        inside = true;
      }

      // 上横封口
      if (lx >= 0 && lx <= w * 0.72 && ly >= 0 && ly <= stroke) {
        inside = true;
      }

      // 下横封口
      if (lx >= 0 && lx <= w * 0.72 && ly >= h - stroke && ly <= h) {
        inside = true;
      }

      // 右半椭圆弧
      if (!inside && lx >= stroke * 0.35) {
        final ex = px.toDouble() - cx;
        final ey = py.toDouble() - cy;
        final od = pow(ex / outerRx, 2) + pow(ey / outerRy, 2);
        final iD = pow(ex / innerRx, 2) + pow(ey / innerRy, 2);
        if (od <= 1.0 && iD >= 1.0) inside = true;
      }

      if (inside) im.setPixel(px, py, img.ColorRgba8(255, 255, 255, 255));
    }
  }
}

// 绘制字母 "O"（椭圆环）
void _drawO(img.Image im, double x, double y, double w, double h) {
  final cx = x + w * 0.5;
  final cy = y + h * 0.5;
  final rx = w * 0.50;
  final ry = h * 0.50;
  final stroke = w * 0.265;
  final irx = rx - stroke;
  final iry = ry - stroke;

  for (var py = (y - 1).round(); py <= (y + h + 1).round(); py++) {
    for (var px = (x - 1).round(); px <= (x + w + 1).round(); px++) {
      if (px < 0 || px >= DS || py < 0 || py >= DS) continue;
      final ex = px.toDouble() - cx;
      final ey = py.toDouble() - cy;
      final od = pow(ex / rx, 2) + pow(ey / ry, 2);
      final iD = pow(ex / irx, 2) + pow(ey / iry, 2);
      if (od <= 1.0 && iD >= 1.0) {
        im.setPixel(px, py, img.ColorRgba8(255, 255, 255, 255));
      }
    }
  }
}

// ── 主函数 ────────────────────────────────────────────────────────────────────
void main() async {
  final canvas = img.Image(width: DS, height: DS);

  // 1. 橙色渐变圆角背景
  final cornerR = DS * 0.22;
  for (var y = 0; y < DS; y++) {
    for (var x = 0; x < DS; x++) {
      if (!_inRR(x.toDouble(), y.toDouble(), 0, 0, DS.toDouble(), DS.toDouble(), cornerR)) continue;
      final t = (x + y) / (2.0 * (DS - 1));
      canvas.setPixel(x, y, img.ColorRgba8(
        _lerp(0xFF, 0xE8, t), _lerp(0xB3, 0x5D, t), _lerp(0x47, 0x04, t), 255));
    }
  }

  // 2. 计算列布局（与 DodoLogo widget 一致）
  //    store_box_h + gap(0.06) + dodo_h(0.25) + gap(0.01) + minimart_h(0.10)
  final bh = DS * 0.34;
  final bw = DS * 0.52;
  final gapSM = DS * 0.06;
  final dodoH = DS * 0.25;
  final mmH = DS * 0.10;
  final totalH = bh + gapSM + dodoH + DS * 0.01 + mmH;
  final startY = (DS - totalH) / 2;
  final bx = (DS - bw) / 2;
  final by = startY;

  // 3. 便利店容器（白色半透明）
  _fillRR(canvas, bx, by, bw, bh, DS * 0.09, 0.22);

  // 4. 店铺图标（简化几何）
  final iconW = bw * 0.62;
  final iconH = bh * 0.78;
  final ix = bx + (bw - iconW) / 2;
  final iy = by + (bh - iconH) / 2;

  // 屋顶
  _fillRR(canvas, ix, iy, iconW, iconH * 0.28, DS * 0.015, 0.92);
  // 遮阳篷（深一点）
  _fillRR(canvas, ix - iconW * 0.05, iy + iconH * 0.28, iconW * 1.10, iconH * 0.10, 0, 0.65);
  // 建筑主体
  _fillRR(canvas, ix + iconW * 0.06, iy + iconH * 0.38, iconW * 0.88, iconH * 0.62, 0, 0.75);
  // 门
  final dw = iconW * 0.22;
  final dh = iconH * 0.38;
  _fillRR(canvas, ix + (iconW - dw) / 2, iy + iconH - dh, dw, dh, DS * 0.008, 1.0);
  // 左窗
  _fillRR(canvas, ix + iconW * 0.10, iy + iconH * 0.45, iconW * 0.20, iconH * 0.20, DS * 0.005, 1.0);
  // 右窗
  _fillRR(canvas, ix + iconW * 0.70, iy + iconH * 0.45, iconW * 0.20, iconH * 0.20, DS * 0.005, 1.0);

  // 5. 三个小白点（霓虹招牌）
  final dotR = (DS * 0.022).round();
  final dotY = (by + bh + gapSM * 0.30).round();
  for (var i = -1; i <= 1; i++) {
    img.fillCircle(canvas,
        x: (DS / 2 + i * DS * 0.072).round(),
        y: dotY,
        radius: dotR,
        color: img.ColorRgba8(255, 255, 255, 185));
  }

  // 6. "DODO" 文字（几何字母）
  final dodoY = by + bh + gapSM;
  final lw = dodoH * 0.72; // 每个字母宽度
  final ls = DS * 0.020;   // 字母间距
  final totalLW = 4 * lw + 3 * ls;
  var lx = (DS - totalLW) / 2;

  for (final letter in ['D', 'O', 'D', 'O']) {
    if (letter == 'D') {
      _drawD(canvas, lx, dodoY, lw, dodoH);
    } else {
      _drawO(canvas, lx, dodoY, lw, dodoH);
    }
    lx += lw + ls;
  }

  // 7. "MiniMart" — 用细白线占位（尺寸太小时文字无法正常渲染）
  final mmY = dodoY + dodoH + DS * 0.012;
  _fillRR(canvas, (DS - DS * 0.30) / 2, mmY, DS * 0.30, DS * 0.016, DS * 0.008, 0.60);

  // 8. 2048 → 1024 缩放（cubic 插值 = 天然抗锯齿）
  final out = img.copyResize(canvas,
      width: OUT, height: OUT, interpolation: img.Interpolation.cubic);

  final bytes = img.encodePng(out);
  await File('web/app_icon.png').writeAsBytes(bytes);
  // ignore: avoid_print
  print('✅ web/app_icon.png 已生成 (${OUT}×${OUT}, ${bytes.length} bytes)');
}
