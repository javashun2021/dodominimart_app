import 'package:flutter/material.dart';

class DodoLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const DodoLogo({super.key, this.size = 100, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB347), Color(0xFFE85D04)],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFFE85D04).withValues(alpha: 0.45),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 便利店图标区域
          Container(
            width: size * 0.52,
            height: size * 0.34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(size * 0.09),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: size * 0.27,
                ),
                // 便利店招牌灯效果
                Positioned(
                  bottom: size * 0.02,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: size * 0.06,
                        height: size * 0.025,
                        margin:
                            EdgeInsets.symmetric(horizontal: size * 0.012),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(size * 0.02),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size * 0.06),
          // DODO 主文字
          Text(
            'DODO',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.25,
              fontWeight: FontWeight.w900,
              letterSpacing: size * 0.025,
              height: 1.0,
            ),
          ),
          SizedBox(height: size * 0.01),
          // MiniMart 副文字
          Text(
            'MiniMart',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: size * 0.1,
              fontWeight: FontWeight.w500,
              letterSpacing: size * 0.008,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// 横排小 logo，用于 AppBar
class DodoLogoBar extends StatelessWidget {
  const DodoLogoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFB347), Color(0xFFE85D04)],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.storefront, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'DODO',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                height: 1.0,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'MiniMart',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFF888888),
                height: 1.2,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
