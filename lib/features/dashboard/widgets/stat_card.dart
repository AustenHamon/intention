import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final List<Color> gradientColors;
  final int animationDelay;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.emoji,
    required this.gradientColors,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: GlassContainer(
        width: double.infinity,
        gradientColors: [
          gradientColors[0].withOpacity(0.25),
          gradientColors[1].withOpacity(0.1),
        ],
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.2,
                )),
            const SizedBox(height: 10),
            Text(value,
                style: AppTextStyles.displayMedium.copyWith(fontSize: 26)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
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