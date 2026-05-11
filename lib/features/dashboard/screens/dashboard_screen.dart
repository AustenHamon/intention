import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/app_usage_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider()..loadData(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.backgroundGradient,
              ),
            ),
          ),

          // Background orbs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
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

          // Main content
          SafeArea(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: provider.refresh,
                    color: AppColors.neonBlue,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(provider.greetingMessage,
                                        style: AppTextStyles.bodyMedium),
                                    Text('Your Day',
                                        style: AppTextStyles.displayMedium),
                                  ],
                                ).animate().fadeIn(duration: 500.ms).slideY(
                                    begin: -0.2, duration: 500.ms),

                                // Settings button
                                GlassContainer(
                                  width: 48,
                                  height: 48,
                                  padding: EdgeInsets.zero,
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ).animate().fadeIn(duration: 500.ms),
                              ],
                            ),
                          ),
                        ),

                        // Overall usage ring
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(24),
                              borderRadius: BorderRadius.circular(28),
                              child: Row(
                                children: [
                                  // Ring
                                  _OverallRing(
                                      percent: provider.overallUsagePercent),
                                  const SizedBox(width: 24),
                                  // Text info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Today\'s Usage',
                                            style: AppTextStyles.labelSmall),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${provider.totalMinutesUsed}m used',
                                          style: AppTextStyles.headlineLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'of ${provider.totalMinutesAllowed}m total limit',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                        const SizedBox(height: 16),
                                        if (provider.appsOverLimit > 0)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.dangerRed
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: AppColors.dangerRed
                                                      .withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              '${provider.appsOverLimit} app${provider.appsOverLimit > 1 ? 's' : ''} over limit',
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                      color:
                                                          AppColors.dangerRed),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                        ),

                       // Stat cards row
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              label: 'Apps tracked',
              value: '${provider.totalAppsMonitored}',
              emoji: '🛡️',
              gradientColors: [
                AppColors.neonBlue,
                AppColors.softPurple
              ],
              animationDelay: 300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Over limit',
              value: '${provider.appsOverLimit}',
              emoji: '⚠️',
              gradientColors: [
                AppColors.warningAmber,
                AppColors.dangerRed
              ],
              animationDelay: 400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Minutes saved',
              value: '12',
              emoji: '✅',
              gradientColors: [
                AppColors.mintGreen,
                AppColors.neonBlue
              ],
              animationDelay: 500,
            ),
          ),
        ],
      ),
    ),
  ),
),

                        // App list header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 28, 24, 12),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('App Usage',
                                    style: AppTextStyles.headlineMedium),
                                GestureDetector(
                                  onTap: () => context.push('/app-limits'),
                                  child: GlassContainer(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        Text('Manage',
                                            style: AppTextStyles.labelLarge
                                                .copyWith(
                                                    color:
                                                        AppColors.neonBlue)),
                                        const SizedBox(width: 4),
                                        const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: AppColors.neonBlue,
                                            size: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // App usage list
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => AppUsageCard(
                                app: provider.appLimits[index],
                                index: index,
                                onToggle: () => provider.toggleApp(
                                    provider.appLimits[index].packageName),
                              ),
                              childCount: provider.appLimits.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Bottom nav bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomNavBar(currentIndex: 0),
          ),
        ],
      ),
    );
  }
}

class _OverallRing extends StatelessWidget {
  final double percent;
  const _OverallRing({required this.percent});

  Color get _color {
    if (percent >= 1.0) return AppColors.dangerRed;
    if (percent >= 0.75) return AppColors.warningAmber;
    return AppColors.neonBlue;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Inner content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).toInt()}%',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'used',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const _BottomNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        borderRadius: BorderRadius.circular(28),
        blur: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => context.go('/dashboard')),
            _NavItem(
                icon: Icons.shield_rounded,
                label: 'Limits',
                isActive: currentIndex == 1,
                onTap: () => context.go('/app-limits')),
            _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                isActive: currentIndex == 2,
                onTap: () {}),
            _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: currentIndex == 3,
                onTap: () {}),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOut);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive
              ? AppColors.neonBlue.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive
                    ? AppColors.neonBlue
                    : Colors.white.withOpacity(0.4),
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive
                    ? AppColors.neonBlue
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}