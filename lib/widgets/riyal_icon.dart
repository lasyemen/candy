import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/design_system.dart';

class RiyalIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showText;

  const RiyalIcon({
    super.key,
    this.size = 16,
    this.color,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? DesignSystem.primary;

    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icon/rsak.svg',
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            'ريال',
            style: TextStyle(
              color: iconColor,
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return SvgPicture.asset(
      'assets/icon/rsak.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
