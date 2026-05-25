import 'package:flutter/material.dart';

const double _kDesktopBreakpoint = 800;
const double _kWideBreakpoint = 1200;
const double _kContentMaxWidth = 1140;

bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= _kDesktopBreakpoint;

bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= _kWideBreakpoint;

/// 在 PC 端把内容限制在 [_kContentMaxWidth] 宽度内居中
Widget centeredContent({required Widget child, double maxWidth = _kContentMaxWidth}) {
  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
