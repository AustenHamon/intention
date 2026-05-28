import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_limit.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_icon.dart';

class AppUsageCard extends StatelessWidget {
  final AppLimit app;
  final int index;
  final VoidCallback? onToggle;

  const AppUsageCard({
    super.key,
    required this.app,
    required this.index,
    this.onToggle,
  });

  Color get _progressColor {
    if (app.usagePercent >= 1.0) return AppColors.dangerRed;
    if (app.usagePercent >= 0.75) return AppColors.warningAmber;
    return AppColors.neonBlue;
  }

  String get _statusText {
    if (app.isOverLimit) return 'Limit reached';
    if (app.remainingMinutes <= 5) return '${app.remainingMinutes}m left';
    return '${app.remainingMinutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      gradientColors: app.isOverLimit
          ? [
              AppColors.dangerRed.withOpacity(0.2),
              AppColors.dangerRed.withOpacity(0.05),
            ]
          : null,
      child: Row(
        children: [
          // App icon + progress ring
          Stack(
            alignment: Alignment.center,
            children: [
              CircularPercentIndicator(
                radius: 32,
                lineWidth: 4,
                percent: app.usagePercent,
                backgroundColor: Colors.white.withOpacity(0.1),
                progressColor: _progressColor,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              AppIcon(
                packageName: app.packageName,
                size: 18,
                containerSize: 36,
                borderRadius: 10,
              ),
            ],
          ),

          const SizedBox(width: 16),

          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(app.displayName, style: AppTextStyles.labelLarge),
                    Text(
                      '${app.usedMinutesToday}m / ${app.dailyLimitMinutes}m',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: app.usagePercent,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _statusText,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: _progressColor),
                    ),
                    if (app.isOverLimit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.dangerRed.withOpacity(0.5)),
                        ),
                        child: Text('Over limit',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dangerRed)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: app.isEnabled
                    ? AppColors.neonBlue.withOpacity(0.6)
                    : Colors.white.withOpacity(0.1),
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: app.isEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 100 * index), duration: 400.ms)
        .slideX(
            begin: 0.1,
            delay: Duration(milliseconds: 100 * index),
            duration: 400.ms);
  }
}