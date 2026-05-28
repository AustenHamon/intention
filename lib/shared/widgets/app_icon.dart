import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class AppIcon extends StatelessWidget {
  final String packageName;
  final double size;
  final double containerSize;
  final double borderRadius;
  final bool showBackground;

  const AppIcon({
    super.key,
    required this.packageName,
    this.size = 24,
    this.containerSize = 48,
    this.borderRadius = 14,
    this.showBackground = true,
  });

  IconData get _icon =>
      AppConstants.appIcons[packageName] ?? FontAwesomeIcons.mobileScreen;

  Color get _color {
    final colorInt = AppConstants.appIconColors[packageName];
    if (colorInt != null) return Color(colorInt);
    return AppColors.neonBlue;
  }

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return FaIcon(_icon, color: _color, size: size);
    }

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _color.withOpacity(0.25), width: 1),
      ),
      child: Center(
        child: FaIcon(_icon, color: _color, size: size),
      ),
    );
  }
}