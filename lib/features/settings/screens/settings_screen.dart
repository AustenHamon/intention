import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _strictMode = false;
  bool _dailyReminder = true;
  bool _showOverrideCount = true;
  bool _positiveFraming = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _strictMode = prefs.getBool('strict_mode') ?? false;
      _dailyReminder = prefs.getBool('daily_reminder') ?? true;
      _showOverrideCount = prefs.getBool('show_override_count') ?? true;
      _positiveFraming = prefs.getBool('positive_framing') ?? true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, false);
    if (mounted) context.go('/onboarding');
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              surface: Color(0xFF1A1040),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
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
                colors: AppColors.backgroundGradient,
              ),
            ),
          ),

          // Orbs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softPurple.withOpacity(0.08),
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
                          Text('Settings',
                              style: AppTextStyles.displayMedium),
                          Text('Customise your experience',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 24),

                // Settings list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Section: Behaviour
                      _SectionHeader(title: 'Behaviour', emoji: '🧠'),
                      const SizedBox(height: 12),

                      _SettingsTile(
                        emoji: '🔒',
                        title: 'Strict Mode',
                        subtitle:
                            'Prevents uninstalling the app without disabling first',
                        value: _strictMode,
                        onChanged: (val) {
                          setState(() => _strictMode = val);
                          _savePref('strict_mode', val);
                        },
                        accentColor: AppColors.dangerRed,
                        delay: 100,
                      ),

                      const SizedBox(height: 10),

                      _SettingsTile(
                        emoji: '🔢',
                        title: 'Show Override Count',
                        subtitle:
                            'Display how many times you\'ve bypassed limits today',
                        value: _showOverrideCount,
                        onChanged: (val) {
                          setState(() => _showOverrideCount = val);
                          _savePref('show_override_count', val);
                        },
                        accentColor: AppColors.neonBlue,
                        delay: 200,
                      ),

                      const SizedBox(height: 10),

                      _SettingsTile(
                        emoji: '💚',
                        title: 'Positive Framing',
                        subtitle:
                            'Use intention-based language instead of restriction language',
                        value: _positiveFraming,
                        onChanged: (val) {
                          setState(() => _positiveFraming = val);
                          _savePref('positive_framing', val);
                        },
                        accentColor: AppColors.mintGreen,
                        delay: 300,
                      ),

                      const SizedBox(height: 24),

                      // Section: Reminders
                      _SectionHeader(title: 'Reminders', emoji: '🔔'),
                      const SizedBox(height: 12),

                      _SettingsTile(
                        emoji: '📅',
                        title: 'Daily Summary Reminder',
                        subtitle:
                            'Get a daily nudge to review your screen time',
                        value: _dailyReminder,
                        onChanged: (val) {
                          setState(() => _dailyReminder = val);
                          _savePref('daily_reminder', val);
                        },
                        accentColor: AppColors.softPurple,
                        delay: 400,
                      ),

                      if (_dailyReminder) ...[
                        const SizedBox(height: 10),
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              const Text('🕗',
                                  style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Reminder Time',
                                        style: AppTextStyles.labelLarge),
                                    Text(
                                      '${_reminderTime.hourOfPeriod}:${_reminderTime.minute.toString().padLeft(2, '0')} ${_reminderTime.period.name.toUpperCase()}',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickReminderTime,
                                child: GlassContainer(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  borderRadius: BorderRadius.circular(12),
                                  gradientColors: [
                                    AppColors.softPurple.withOpacity(0.3),
                                    AppColors.softPurple.withOpacity(0.1),
                                  ],
                                  child: Text('Change',
                                      style: AppTextStyles.labelLarge
                                          .copyWith(
                                              color:
                                                  AppColors.softPurple)),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                            delay: 500.ms, duration: 400.ms),
                      ],

                      const SizedBox(height: 24),

                      // Section: About
                      _SectionHeader(title: 'About', emoji: 'ℹ️'),
                      const SizedBox(height: 12),

                      // App info card
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            GlassContainer(
                              width: 56,
                              height: 56,
                              padding: EdgeInsets.zero,
                              borderRadius: BorderRadius.circular(16),
                              gradientColors: [
                                AppColors.neonBlue.withOpacity(0.3),
                                AppColors.softPurple.withOpacity(0.1),
                              ],
                              child: const Center(
                                child: Text('🎯',
                                    style: TextStyle(fontSize: 28)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Intention',
                                      style: AppTextStyles.headlineMedium),
                                  Text(
                                      'Version ${AppConstants.appVersion}',
                                      style: AppTextStyles.bodyMedium),
                                  Text(
                                      'Built for UMP SCMS — Theme 6',
                                      style: AppTextStyles.labelSmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                      const SizedBox(height: 10),

                      // Privacy note
                      GlassContainer(
                        padding: const EdgeInsets.all(18),
                        borderRadius: BorderRadius.circular(20),
                        gradientColors: [
                          AppColors.mintGreen.withOpacity(0.15),
                          AppColors.mintGreen.withOpacity(0.05),
                        ],
                        child: Row(
                          children: [
                            const Text('🔐',
                                style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('100% Private',
                                      style: AppTextStyles.labelLarge
                                          .copyWith(
                                              color:
                                                  AppColors.mintGreen)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'All data stays on your device. No accounts, no cloud, no tracking.',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                      const SizedBox(height: 24),

                      // Section: Reset
                      _SectionHeader(title: 'Reset', emoji: '⚠️'),
                      const SizedBox(height: 12),

                      // Replay onboarding
                      GestureDetector(
                        onTap: _resetOnboarding,
                        child: GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              const Text('🔄',
                                  style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Replay Onboarding',
                                        style: AppTextStyles.labelLarge),
                                    Text(
                                      'Go through the introduction again',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white54,
                                  size: 16),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom nav
          BottomNavBar(currentIndex: 3),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;

  const _SectionHeader({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            )),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final Color accentColor;
  final int delay;

  const _SettingsTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      gradientColors: value
          ? [
              accentColor.withOpacity(0.15),
              accentColor.withOpacity(0.05),
            ]
          : null,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: value
                    ? accentColor.withOpacity(0.6)
                    : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: value
                      ? accentColor.withOpacity(0.8)
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 22,
                    height: 22,
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
            delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(
            begin: 0.1,
            delay: Duration(milliseconds: delay),
            duration: 400.ms);
  }
}




 