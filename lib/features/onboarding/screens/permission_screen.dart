import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/usage_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isChecking = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await UsageStatsService.hasPermission();
    setState(() => _permissionGranted = granted);
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);
    await UsageStatsService.requestPermission();
    // Wait a moment then recheck
    await Future.delayed(const Duration(seconds: 2));
    await _checkPermission();
    setState(() => _isChecking = false);
  }

  Future<void> _continue() async {
    context.go('/app-picker');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0E27), Color(0xFF1A1040)],
              ),
            ),
          ),

          // Orbs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softPurple.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Icon
                  GlassContainer(
                    width: 120,
                    height: 120,
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(36),
                    gradientColors: [
                      AppColors.neonBlue.withOpacity(0.3),
                      AppColors.softPurple.withOpacity(0.1),
                    ],
                    child: const Center(
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'One permission\nto rule them all.',
                    style: AppTextStyles.displayMedium.copyWith(height: 1.2),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.2, delay: 200.ms),

                  const SizedBox(height: 20),

                  // Explanation card
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        _PermissionRow(
                          icon: Icons.access_time_rounded,
                          title: 'Usage Access',
                          description:
                              'Lets Intention read how long you spend in each app — stored only on your device.',
                          color: AppColors.neonBlue,
                        ),
                        const SizedBox(height: 16),
                        _PermissionRow(
                          icon: Icons.lock_outline_rounded,
                          title: '100% Private',
                          description:
                              'No data leaves your phone. No accounts, no cloud, no tracking.',
                          color: AppColors.mintGreen,
                        ),
                        const SizedBox(height: 16),
                        _PermissionRow(
                          icon: Icons.settings_accessibility_rounded,
                          title: 'Accessibility Service',
                          description:
                              'Detects when you open a monitored app so Intention can show the intervention.',
                          color: AppColors.softPurple,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.2, delay: 400.ms),

                  const Spacer(),

                  // Permission status
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _permissionGranted
                        ? GlassContainer(
                            key: const ValueKey('granted'),
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(16),
                            gradientColors: [
                              AppColors.mintGreen.withOpacity(0.2),
                              AppColors.mintGreen.withOpacity(0.05),
                            ],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.mintGreen, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Usage access granted!',
                                  style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.mintGreen),
                                ),
                              ],
                            ),
                          )
                        : GlassContainer(
                            key: const ValueKey('not-granted'),
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(16),
                            gradientColors: [
                              AppColors.warningAmber.withOpacity(0.2),
                              AppColors.warningAmber.withOpacity(0.05),
                            ],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.warningAmber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Permission not yet granted',
                                  style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.warningAmber),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Action button
                  GestureDetector(
                    onTap: _isChecking
                        ? null
                        : _permissionGranted
                            ? _continue
                            : _requestPermission,
                    child: GlassContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      borderRadius: BorderRadius.circular(20),
                      gradientColors: [
                        AppColors.neonBlue.withOpacity(0.4),
                        AppColors.neonBlue.withOpacity(0.2),
                      ],
                      child: Center(
                        child: _isChecking
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : Text(
                                _permissionGranted
                                    ? 'Continue →'
                                    : 'Grant Permission',
                                style: AppTextStyles.headlineMedium,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              const SizedBox(height: 4),
              Text(description, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}