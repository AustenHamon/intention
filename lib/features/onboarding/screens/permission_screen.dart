import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/usage_stats_service.dart';
import '../../../core/services/accessibility_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _isChecking = false;
  bool _permissionGranted = false;
  bool _accessibilityGranted = false;
  bool _overlayGranted = false;

  static const _overlayChannel =
      MethodChannel('com.austennkuna.intention/overlay');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final usage = await UsageStatsService.hasPermission();
    final accessibility = await AppAccessibilityService.isEnabled();
    final overlay = await _checkOverlayPermission();
    setState(() {
      _permissionGranted = usage;
      _accessibilityGranted = accessibility;
      _overlayGranted = overlay;
    });
  }

  Future<bool> _checkOverlayPermission() async {
    try {
      final result =
          await _overlayChannel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);
    try {
      if (!_permissionGranted) {
        await UsageStatsService.requestPermission();
      } else if (!_accessibilityGranted) {
        await AppAccessibilityService.openSettings();
      } else if (!_overlayGranted) {
        await _overlayChannel.invokeMethod('requestOverlayPermission');
      }
    } finally {
      // didChangeAppLifecycleState handles the re-check and clears _isChecking
      // on resume. This finally only fires if the intent returned synchronously
      // or threw, so we don't double-clear — the observer will overwrite anyway.
      if (mounted) setState(() => _isChecking = false);
    }
  }

  bool get _allGranted =>
      _permissionGranted && _accessibilityGranted && _overlayGranted;

  String get _buttonText {
    if (_allGranted) return 'Continue →';
    if (!_permissionGranted) return 'Grant Usage Access';
    if (!_accessibilityGranted) return 'Grant Accessibility Access';
    return 'Grant Display Over Apps';
  }

  String get _statusText {
    if (!_permissionGranted) return 'Usage access required';
    if (!_accessibilityGranted) return 'Accessibility access required';
    return 'Display over apps required';
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
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Keeps the premium UI feel
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Forces the Column to take up at least the full height of the viewport
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 40), // Slightly reduced from 60 to give breathability

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
                        Icons.shield_rounded,
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

                  const SizedBox(height: 32), // Reduced from 40

                  // Title
                  Text(
                    'Three permissions.\nFull protection.',
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
                              'Reads how long you spend in each app — stored only on your device.',
                          color: AppColors.neonBlue,
                          granted: _permissionGranted,
                        ),
                        const SizedBox(height: 16),
                        _PermissionRow(
                          icon: Icons.settings_accessibility_rounded,
                          title: 'Accessibility Service',
                          description:
                              'Detects when you open a monitored app so Intention can intervene.',
                          color: AppColors.softPurple,
                          granted: _accessibilityGranted,
                        ),
                        const SizedBox(height: 16),
                        _PermissionRow(
                          icon: Icons.layers_rounded,
                          title: 'Display Over Other Apps',
                          description:
                              'Shows the cooling ladder on top of the monitored app — the core feature.',
                          color: AppColors.warningAmber,
                          granted: _overlayGranted,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.2, delay: 400.ms),

                  // The Spacer still works on large screens thanks to IntrinsicHeight
                  const Spacer(),
                  const SizedBox(height: 24), // Gives guaranteed padding above status box

                  // Permission status
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _allGranted
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
                                  'All permissions granted!',
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
                                  _statusText,
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
                        : _allGranted
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
                                _buttonText,
                                style: AppTextStyles.headlineMedium,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24), // Reduced from 40 to prevent bottom clipping
                ],
              ),
            ),
          ),
        );
      },
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
  final bool granted;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.granted,
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
            color: granted
                ? AppColors.mintGreen.withOpacity(0.15)
                : color.withOpacity(0.15),
            border: Border.all(
              color: granted
                  ? AppColors.mintGreen.withOpacity(0.3)
                  : color.withOpacity(0.3),
            ),
          ),
          child: Icon(
            granted ? Icons.check_rounded : icon,
            color: granted ? AppColors.mintGreen : color,
            size: 20,
          ),
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