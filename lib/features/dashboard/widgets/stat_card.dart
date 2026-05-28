import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final int animationDelay;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      height: double.infinity,
      gradientColors: [
        gradientColors[0].withOpacity(0.25),
        gradientColors[1].withOpacity(0.1),
      ],
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, color: gradientColors[0], size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: animationDelay), duration: 500.ms)
        .slideY(
            begin: 0.2,
            delay: Duration(milliseconds: animationDelay),
            duration: 500.ms);
  }
}