import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/services/usage_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_limit.dart';
import '../../../data/repositories/app_limits_repository.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedDayIndex = 6;
  List<AppLimit> _appLimits = [];
  List<Map<String, dynamic>> _weeklyData = List.generate(
    7,
    (_) => {'total': 0, 'overrides': 0, 'topApp': '-'},
  );
  bool _isLoading = true;

  List<String> get _days {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return dayNames[day.weekday - 1];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    final repo = AppLimitsRepository();

    final weeklyBarData = await repo.getWeeklyBarData();
    if (weeklyBarData.isNotEmpty) {
      _weeklyData = weeklyBarData;
    }

    final limits = await repo.getAppLimits();
    final hasPermission = await UsageStatsService.hasPermission();

    if (hasPermission && limits.isNotEmpty) {
      final packages = limits.map((a) => a.packageName).toList();
      final realUsage = await UsageStatsService.getUsageForPackages(packages);
      _appLimits = limits
          .map((app) => app.copyWith(
                usedMinutesToday: realUsage[app.packageName] ?? 0,
              ))
          .toList();

      final totalToday = _appLimits.fold(0, (sum, a) => sum + a.usedMinutesToday);
      final sorted = [..._appLimits]
        ..sort((a, b) => b.usedMinutesToday.compareTo(a.usedMinutesToday));
      _weeklyData[6] = {
        ..._weeklyData[6],
        'total': totalToday,
        'topApp': sorted.isNotEmpty ? sorted.first.displayName : '-',
      };
    } else {
      _appLimits = limits;
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _appBreakdown {
    if (_appLimits.isEmpty) return [];
    return _appLimits.map((app) {
      final percent = app.dailyLimitMinutes > 0
          ? app.usedMinutesToday / app.dailyLimitMinutes
          : 0.0;
      Color color = AppColors.mintGreen;
      if (percent >= 1.0) {
        color = AppColors.dangerRed;
      } else if (percent >= 0.75) {
        color = AppColors.warningAmber;
      }
      return {
        'name': app.displayName,
        'package': app.packageName,
        'minutes': app.usedMinutesToday,
        'limit': app.dailyLimitMinutes,
        'color': color,
      };
    }).toList();
  }

  int get _maxMinutes {
    final max = _weeklyData
        .map((d) => d['total'] as int)
        .reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1 : max;
  }

  int get _selectedTotal => _weeklyData[_selectedDayIndex]['total'] as int;
  int get _selectedOverrides => _weeklyData[_selectedDayIndex]['overrides'] as int;
  String get _selectedTopApp => _weeklyData[_selectedDayIndex]['topApp'] as String;
  int get _weeklyTotal =>
      _weeklyData.fold(0, (sum, d) => sum + (d['total'] as int));
  int get _weeklyOverrides =>
      _weeklyData.fold(0, (sum, d) => sum + (d['overrides'] as int));

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softPurple.withOpacity(0.07),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
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
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Statistics',
                                style: AppTextStyles.displayMedium),
                            Text('Your weekly overview',
                                style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                ),

                // Weekly summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: GlassContainer(
                              width: double.infinity,
                              height: double.infinity,
                              padding: const EdgeInsets.all(16),
                              borderRadius: BorderRadius.circular(20),
                              gradientColors: [
                                AppColors.neonBlue.withOpacity(0.2),
                                AppColors.neonBlue.withOpacity(0.05),
                              ],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Icon(Icons.bar_chart, 
                                      color: AppColors.neonBlue, size: 26),
                                  const SizedBox(height: 10),
                                  Text(
                                    _formatMinutes(_weeklyTotal),
                                    style: AppTextStyles.headlineLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('This week',
                                      style: AppTextStyles.labelSmall),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassContainer(
                              width: double.infinity,
                              height: double.infinity,
                              padding: const EdgeInsets.all(16),
                              borderRadius: BorderRadius.circular(20),
                              gradientColors: [
                                AppColors.warningAmber.withOpacity(0.2),
                                AppColors.warningAmber.withOpacity(0.05),
                              ],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, 
                                      color: AppColors.warningAmber, size: 26),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$_weeklyOverrides',
                                    style: AppTextStyles.headlineLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Overrides',
                                      style: AppTextStyles.labelSmall),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassContainer(
                              width: double.infinity,
                              height: double.infinity,
                              padding: const EdgeInsets.all(16),
                              borderRadius: BorderRadius.circular(20),
                              gradientColors: [
                                AppColors.mintGreen.withOpacity(0.2),
                                AppColors.mintGreen.withOpacity(0.05),
                              ],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Icon(Icons.emoji_emotions_rounded, 
                                      color: AppColors.mintGreen, size: 26),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${(_weeklyData.where((d) => d['overrides'] == 0).length)}',
                                    style: AppTextStyles.headlineLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Clean days',
                                      style: AppTextStyles.labelSmall),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                ),

                // Bar chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Daily Usage',
                                  style: AppTextStyles.headlineMedium),
                              Text('Tap a bar',
                                  style: AppTextStyles.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Bar chart
                          SizedBox(
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: List.generate(_days.length, (i) {
                                final isSelected = i == _selectedDayIndex;
                                final height = (_weeklyData[i]['total']
                                            as int) /
                                        _maxMinutes *
                                        110;
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedDayIndex = i),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 300),
                                        width: 32,
                                        height: height,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: isSelected
                                                ? [
                                                    AppColors.neonBlue,
                                                    AppColors.softPurple,
                                                  ]
                                                : [
                                                    Colors.white
                                                        .withOpacity(0.2),
                                                    Colors.white
                                                        .withOpacity(0.1),
                                                  ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _days[i],
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                          color: isSelected
                                              ? AppColors.neonBlue
                                              : AppColors.textMuted,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Selected day detail
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey(_selectedDayIndex),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.neonBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.neonBlue
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _DayStat(
                                    label: 'Total',
                                    value: _formatMinutes(_selectedTotal),
                                  ),
                                  _DayStat(
                                    label: 'Overrides',
                                    value: '$_selectedOverrides',
                                  ),
                                  _DayStat(
                                    label: 'Top App',
                                    value: _selectedTopApp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ),

                // App breakdown header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text('App Breakdown',
                        style: AppTextStyles.headlineMedium),
                  ),
                ),

                // App breakdown list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final app = _appBreakdown[index];
                        final percent = ((app['minutes'] as int) /
                                (app['limit'] as int))
                            .clamp(0.0, 1.0);
                        final isOver =
                            (app['minutes'] as int) > (app['limit'] as int);

                        return GlassContainer(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              // Emoji + ring
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularPercentIndicator(
                                    radius: 30,
                                    lineWidth: 4,
                                    percent: percent,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    progressColor:
                                        app['color'] as Color,
                                    circularStrokeCap:
                                        CircularStrokeCap.round,
                                  ),
                                  AppIcon(
                                    packageName: app['package'] as String,
                                    size: 20,
                                    containerSize: 36,
                                    borderRadius: 10,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(app['name'] as String,
                                            style:
                                                AppTextStyles.labelLarge),
                                        Text(
                                          '${_formatMinutes(app['minutes'] as int)} / ${_formatMinutes(app['limit'] as int)}',
                                          style: AppTextStyles.labelSmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          app['color'] as Color,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                    if (isOver) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${(app['minutes'] as int) - (app['limit'] as int)}m over limit',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                                color:
                                                    AppColors.dangerRed),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay:
                                    Duration(milliseconds: 100 * index),
                                duration: 400.ms)
                            .slideX(
                                begin: 0.1,
                                delay: Duration(
                                    milliseconds: 100 * index),
                                duration: 400.ms);
                      },
                      childCount: _appBreakdown.length,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom nav
         BottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }
}

class _DayStat extends StatelessWidget {
  final String label;
  final String value;

  const _DayStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.neonBlue)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

