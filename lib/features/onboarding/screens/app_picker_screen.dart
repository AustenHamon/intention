import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/services/usage_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_limit.dart';
import '../../../data/repositories/app_limits_repository.dart';
import '../../../shared/widgets/glass_container.dart';

class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  List<AppInfo> _installedApps = [];
  final Set<String> _selectedPackages = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  // Popular social apps to highlight at the top
  final List<String> _priorityApps = [
    'com.zhiliaoapp.musically',
    'com.instagram.android',
    'com.twitter.android',
    'com.google.android.youtube',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.whatsapp',
    'com.reddit.frontpage',
  ];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    final apps = await UsageStatsService.getInstalledApps();

    // Sort: priority apps first, then alphabetical
    apps.sort((a, b) {
      final aPriority = _priorityApps.contains(a.packageName);
      final bPriority = _priorityApps.contains(b.packageName);
      if (aPriority && !bPriority) return -1;
      if (!aPriority && bPriority) return 1;
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    setState(() {
      _installedApps = apps;
      _isLoading = false;
    });
  }

  List<AppInfo> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;
    return _installedApps
        .where((app) =>
            (app.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _saveAndContinue() async {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one app to monitor',
              style: AppTextStyles.bodyMedium),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final repo = AppLimitsRepository();

    // Clear existing limits
    for (final app in _installedApps) {
      if (app.packageName != null) {
        await repo.deleteAppLimit(app.packageName!);
      }
    }

    // Save selected apps with default 30 min limit
    for (final package in _selectedPackages) {
      final app = _installedApps
          .firstWhere((a) => a.packageName == package);
      await repo.saveAppLimit(AppLimit(
        packageName: package,
        displayName: app.name ?? package,
        emoji: '📱',
        dailyLimitMinutes: 30,
      ));
    }

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.backgroundGradient,
              ),
            ),
          ),

          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softPurple.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose your apps',
                              style: AppTextStyles.displayMedium)
                          .animate()
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 4),
                      Text(
                        'Select the apps you want to monitor. You can change this later.',
                        style: AppTextStyles.bodyMedium,
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    borderRadius: BorderRadius.circular(16),
                    child: TextField(
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search apps...',
                        hintStyle: AppTextStyles.bodyMedium,
                        border: InputBorder.none,
                        icon: const Icon(Icons.search_rounded,
                            color: Colors.white54),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 8),

                // Selected count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedPackages.length} selected',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _selectedPackages.isNotEmpty
                              ? AppColors.neonBlue
                              : AppColors.textMuted,
                        ),
                      ),
                      if (_selectedPackages.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPackages.clear()),
                          child: Text('Clear all',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.dangerRed)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // App list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredApps.isEmpty
                          ? Center(
                              child: Text('No apps found',
                                  style: AppTextStyles.bodyMedium))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 0, 24, 120),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filteredApps.length,
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                final isSelected = _selectedPackages
                                    .contains(app.packageName);
                                final isPriority = _priorityApps
                                    .contains(app.packageName);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedPackages
                                            .remove(app.packageName);
                                      } else {
                                        _selectedPackages
                                            .add(app.packageName!);
                                      }
                                    });
                                  },
                                  child: GlassContainer(
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    borderRadius: BorderRadius.circular(18),
                                    gradientColors: isSelected
                                        ? [
                                            AppColors.neonBlue
                                                .withOpacity(0.25),
                                            AppColors.neonBlue
                                                .withOpacity(0.1),
                                          ]
                                        : null,
                                    child: Row(
                                      children: [
                                        // App icon
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: app.icon != null
                                              ? Image.memory(
                                                  app.icon!,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.neonBlue
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Icon(
                                                      Icons.apps_rounded,
                                                      color: Colors.white54),
                                                ),
                                        ),

                                        const SizedBox(width: 14),

                                        // App name
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      app.name ?? 'Unknown',
                                                      style: AppTextStyles
                                                          .labelLarge,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                  if (isPriority)
                                                    Container(
                                                      margin:
                                                          const EdgeInsets
                                                              .only(left: 6),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: AppColors
                                                            .softPurple
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        border: Border.all(
                                                          color: AppColors
                                                              .softPurple
                                                              .withOpacity(
                                                                  0.4),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Popular',
                                                        style: AppTextStyles
                                                            .labelSmall
                                                            .copyWith(
                                                          color: AppColors
                                                              .softPurple,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              Text(
                                                app.packageName ?? '',
                                                style:
                                                    AppTextStyles.labelSmall,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Checkbox
                                        AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 250),
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? AppColors.neonBlue
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.neonBlue
                                                  : Colors.white
                                                      .withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(
                                        delay: Duration(
                                            milliseconds:
                                                20 * index.clamp(0, 20)),
                                        duration: 300.ms)
                                    .slideX(
                                        begin: 0.05,
                                        delay: Duration(
                                            milliseconds:
                                                20 * index.clamp(0, 20)),
                                        duration: 300.ms);
                              },
                            ),
                ),
              ],
            ),
          ),

          // Bottom save button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveAndContinue,
                child: GlassContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  borderRadius: BorderRadius.circular(20),
                  gradientColors: [
                    AppColors.neonBlue.withOpacity(0.4),
                    AppColors.softPurple.withOpacity(0.2),
                  ],
                  child: Center(
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Start Monitoring',
                                  style: AppTextStyles.headlineMedium),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}