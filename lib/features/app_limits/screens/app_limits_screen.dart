import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_icon.dart';
import '../providers/app_limits_provider.dart';
import '../widgets/limit_editor_sheet.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class AppLimitsScreen extends StatelessWidget {
  const AppLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppLimitsProvider()..loadData(),
      child: const _AppLimitsView(),
    );
  }
}

class _AppLimitsView extends StatelessWidget {
  const _AppLimitsView();

  void _showLimitEditor(BuildContext context, app, AppLimitsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: LimitEditorSheet(
          app: app,
          onSave: (minutes) => provider.updateLimit(app.packageName, minutes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppLimitsProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.backgroundGradient,
              ),
            ),
          ),

          // Orbs
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softPurple.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/dashboard'),
                        child: GlassContainer(
                          width: 44,
                          height: 44,
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(14),
                          child: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('App Limits',
                              style: AppTextStyles.displayMedium),
                          Text('Tap an app to edit its limit',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 24),

                // Info banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(18),
                    gradientColors: [
                      AppColors.neonBlue.withOpacity(0.2),
                      AppColors.softPurple.withOpacity(0.1),
                    ],
                    child: Row(
                      children: [
                        const Text('💡',
                            style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'When you reach a limit, Intention will ask for your intention before granting access.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // App list
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: provider.appLimits.length,
                          itemBuilder: (context, index) {
                            final app = provider.appLimits[index];
                            return GlassContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(18),
                              borderRadius: BorderRadius.circular(22),
                              child: Row(
                                children: [
                                  // App icon
                                  AppIcon(
                                    packageName: app.packageName,
                                    size: 24,
                                    containerSize: 52,
                                    borderRadius: 16,
                                  ),

                                  const SizedBox(width: 16),

                                  // Info
                                 // Info
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        app.displayName,
        style: AppTextStyles.labelLarge.copyWith(
          color: app.isEnabled
              ? AppColors.textPrimary
              : AppColors.textMuted,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.neonBlue.withOpacity(0.3),
              ),
            ),
            child: Text(
              provider.formatLimit(app.dailyLimitMinutes),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.neonBlue,
              ),
            ),
          ),
          Text(
            app.isEnabled ? 'Monitoring on' : 'Paused',
            style: AppTextStyles.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ],
  ),
),

                                  // Edit button
                                  GestureDetector(
                                    onTap: () => _showLimitEditor(
                                        context, app, provider),
                                    child: GlassContainer(
                                      width: 40,
                                      height: 40,
                                      padding: EdgeInsets.zero,
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 18),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Toggle
                                  GestureDetector(
                                    onTap: () =>
                                        provider.toggleApp(app.packageName),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 44,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(13),
                                        color: app.isEnabled
                                            ? AppColors.neonBlue
                                                .withOpacity(0.6)
                                            : Colors.white.withOpacity(0.1),
                                        border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: AnimatedAlign(
                                        duration: const Duration(
                                            milliseconds: 300),
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
                                    delay: Duration(
                                        milliseconds: 100 * index),
                                    duration: 400.ms)
                                .slideX(
                                    begin: 0.1,
                                    delay: Duration(
                                        milliseconds: 100 * index),
                                    duration: 400.ms);
                          },
                        ),
                ),
              ],
            ),
          ),

          // Bottom nav
          BottomNavBar(currentIndex: 1),
          
        ],
      ),
    );
  }
}