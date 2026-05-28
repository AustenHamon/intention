import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';
import '../providers/cooling_ladder_provider.dart';
import '../../../shared/widgets/app_icon.dart';

class CoolingLadderScreen extends StatelessWidget {
  final String packageName;
  final String appName;
  final String appEmoji;
  final int overrideCount;

  const CoolingLadderScreen({
    super.key,
    required this.packageName,
    required this.appName,
    required this.appEmoji,
    required this.overrideCount,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CoolingLadderProvider()
        ..initialise(packageName, appName, appEmoji, overrideCount),
      child: const _CoolingLadderView(),
    );
  }
}

class _CoolingLadderView extends StatelessWidget {
  const _CoolingLadderView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoolingLadderProvider>();

    // Handle exit states
    if (provider.overlayState == AppOverlayState.granted ||
        provider.overlayState == AppOverlayState.exited) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Animated background based on tier
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _backgroundColors(provider.currentTier),
              ),
            ),
          ),

          // Floating orbs
          ..._buildOrbs(provider.currentTier),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Top bar
                  _TopBar(provider: provider),

                  const Spacer(flex: 1),

                  // App icon
                  _AppIcon(provider: provider),

                  const SizedBox(height: 32),

                  // Title & message
                  _TitleSection(provider: provider),

                  const SizedBox(height: 40),

                  // Timer or intention input
                  if (provider.timerRunning)
                    _TimerDisplay(provider: provider)
                  else if (provider.overlayState == AppOverlayState.intention)
                    _IntentionInput(provider: provider)
                  else
                    _BreathingPrompt(),

                  const Spacer(flex: 2),

                  // Action buttons
                  _ActionButtons(provider: provider),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _backgroundColors(CoolingTier tier) {
    switch (tier) {
      case CoolingTier.tier1:
        return [const Color(0xFF0A1628), const Color(0xFF0D2B4B)];
      case CoolingTier.tier2:
        return [const Color(0xFF1A0E00), const Color(0xFF3D2000)];
      case CoolingTier.tier3:
        return [const Color(0xFF1A0000), const Color(0xFF3D0000)];
    }
  }

  List<Widget> _buildOrbs(CoolingTier tier) {
    final color = tier == CoolingTier.tier1
        ? AppColors.neonBlue
        : tier == CoolingTier.tier2
            ? AppColors.warningAmber
            : AppColors.dangerRed;

    return [
      Positioned(
        top: -100,
        left: -80,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
        ),
      ),
      Positioned(
        bottom: 50,
        right: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.08),
          ),
        ),
      ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  final CoolingLadderProvider provider;
  const _TopBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tier indicator
        GlassContainer(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Icon(
                Icons.layers_rounded,
                color: _tierColor(provider.currentTier),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Override ${provider.overrideCount + 1}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: _tierColor(provider.currentTier),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        // Exit button
        GestureDetector(
          onTap: provider.exitToHome,
          child: GlassContainer(
            width: 44,
            height: 44,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(14),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 20),
          ),
        ).animate().fadeIn(duration: 400.ms),
      ],
    );
  }

  Color _tierColor(CoolingTier tier) {
    switch (tier) {
      case CoolingTier.tier1:
        return AppColors.neonBlue;
      case CoolingTier.tier2:
        return AppColors.warningAmber;
      case CoolingTier.tier3:
        return AppColors.dangerRed;
    }
  }
}

class _AppIcon extends StatelessWidget {
  final CoolingLadderProvider provider;
  const _AppIcon({required this.provider});

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      packageName: provider.packageName,
      size: 52,
      containerSize: 110,
      borderRadius: 32,
    )
        .animate()
        .scale(
          begin: const Offset(0.6, 0.6),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 400.ms);
  }
}

class _TitleSection extends StatelessWidget {
  final CoolingLadderProvider provider;
  const _TitleSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          provider.tierLabel,
          style: AppTextStyles.displayMedium,
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.2, delay: 200.ms),

        const SizedBox(height: 12),

        GlassContainer(
          padding: const EdgeInsets.all(18),
          borderRadius: BorderRadius.circular(18),
          child: Text(
            provider.tierMessage,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 500.ms)
            .slideY(begin: 0.2, delay: 300.ms),
      ],
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final CoolingLadderProvider provider;
  const _TimerDisplay({required this.provider});

  Color get _timerColor {
    switch (provider.currentTier) {
      case CoolingTier.tier1:
        return AppColors.neonBlue;
      case CoolingTier.tier2:
        return AppColors.warningAmber;
      case CoolingTier.tier3:
        return AppColors.dangerRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        provider.secondsRemaining / provider.waitSeconds;

    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_timerColor),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Seconds
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${provider.secondsRemaining}',
                    style: AppTextStyles.timerDisplay.copyWith(
                      color: _timerColor,
                      fontSize: 52,
                    ),
                  ),
                  Text('seconds',
                      style: AppTextStyles.labelSmall),
                ],
              ),
            ],
          ),
        ).animate().scale(
              begin: const Offset(0.8, 0.8),
              duration: 500.ms,
              curve: Curves.easeOut,
            ),
      ],
    );
  }
}

class _BreathingPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      gradientColors: [
        AppColors.mintGreen.withOpacity(0.2),
        AppColors.mintGreen.withOpacity(0.05),
      ],
      child: Column(
        children: [
          const Text('🌬️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('Ready to continue?',
              style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'The timer is done. You can proceed or go back.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.9, 0.9),
          duration: 500.ms,
        );
  }
}

class _IntentionInput extends StatefulWidget {
  final CoolingLadderProvider provider;
  const _IntentionInput({required this.provider});

  @override
  State<_IntentionInput> createState() => _IntentionInputState();
}

class _IntentionInputState extends State<_IntentionInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why do you need this right now?',
              style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            style: AppTextStyles.bodyLarge,
            maxLines: 3,
            onChanged: widget.provider.updateIntention,
            decoration: InputDecoration(
              hintText: 'State your intention...',
              hintStyle: AppTextStyles.bodyMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.neonBlue, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_controller.text.trim().length}/5 characters minimum',
            style: AppTextStyles.labelSmall.copyWith(
              color: _controller.text.trim().length >= 5
                  ? AppColors.mintGreen
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, duration: 500.ms);
  }
}

class _ActionButtons extends StatelessWidget {
  final CoolingLadderProvider provider;
  const _ActionButtons({required this.provider});

  Color get _accentColor {
    switch (provider.currentTier) {
      case CoolingTier.tier1:
        return AppColors.neonBlue;
      case CoolingTier.tier2:
        return AppColors.warningAmber;
      case CoolingTier.tier3:
        return AppColors.dangerRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Proceed button
        GestureDetector(
          onTap: provider.canProceed ? provider.proceedToApp : null,
          child: AnimatedOpacity(
            opacity: provider.canProceed ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              borderRadius: BorderRadius.circular(20),
              gradientColors: [
                _accentColor.withOpacity(0.4),
                _accentColor.withOpacity(0.2),
              ],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    provider.timerRunning
                        ? Icons.hourglass_top_rounded
                        : Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    provider.timerRunning
                        ? 'Please wait...'
                        : 'Open ${provider.appName}',
                    style: AppTextStyles.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Go back button
        GestureDetector(
          onTap: provider.exitToHome,
          child: GlassContainer(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_rounded,
                    color: Colors.white54, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Go back to home',
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().slideY(
          begin: 0.3,
          delay: 400.ms,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}