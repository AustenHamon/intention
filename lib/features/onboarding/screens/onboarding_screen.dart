import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      emoji: '📱',
      title: 'You open apps\nwithout thinking.',
      subtitle:
          'Research shows young adults check their phones 96 times a day — most of the time, without even realising it.',
      accentColor: AppColors.neonBlue,
      gradientColors: [Color(0xFF0A0E27), Color(0xFF1E3A8A)],
    ),
    OnboardingData(
      emoji: '🧘',
      title: 'Intention adds\nmindful friction.',
      subtitle:
          'Before you scroll, we ask: is this intentional? A short pause is all it takes to break the habit loop.',
      accentColor: AppColors.softPurple,
      gradientColors: [Color(0xFF1A1040), Color(0xFF4C1D95)],
    ),
    OnboardingData(
      emoji: '🎯',
      title: 'You set the rules.\nWe hold them.',
      subtitle:
          'Choose your apps, set daily limits, and let Intention do the rest — privately, on your device, always.',
      accentColor: AppColors.mintGreen,
      gradientColors: [Color(0xFF0D2B1F), Color(0xFF064E3B)],
    ),
  ];

Future<void> _completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(AppConstants.onboardingCompleteKey, true);
  if (mounted) context.go('/permission');
}

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() => _completeOnboarding();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pages[_currentPage].gradientColors,
              ),
            ),
          ),

          // Floating orbs background effect
          ..._buildFloatingOrbs(),

          // Page content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _currentPage < _pages.length - 1
                        ? GestureDetector(
                            onTap: _skip,
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              borderRadius: BorderRadius.circular(30),
                              child: Text('Skip',
                                  style: AppTextStyles.labelLarge),
                            ),
                          ).animate().fadeIn(duration: 400.ms)
                        : const SizedBox(height: 44),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) =>
                        _OnboardingPage(data: _pages[index]),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Column(
                    children: [
                      // Page indicator
                      AnimatedSmoothIndicator(
                        activeIndex: _currentPage,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: _pages[_currentPage].accentColor,
                          dotColor: Colors.white.withOpacity(0.3),
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 4,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Next / Get Started button
                      GestureDetector(
                        onTap: _nextPage,
                        child: GlassContainer(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          borderRadius: BorderRadius.circular(20),
                          gradientColors: [
                            _pages[_currentPage].accentColor.withOpacity(0.4),
                            _pages[_currentPage].accentColor.withOpacity(0.2),
                          ],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage < _pages.length - 1
                                    ? 'Continue'
                                    : 'Get Started',
                                style: AppTextStyles.headlineMedium,
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                _currentPage < _pages.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.check_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ).animate().slideY(
                            begin: 0.3,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingOrbs() {
    return [
      Positioned(
        top: -80,
        right: -60,
        child: _Orb(
          size: 250,
          color: _pages[_currentPage].accentColor.withOpacity(0.15),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -80,
        child: _Orb(
          size: 200,
          color: _pages[_currentPage].accentColor.withOpacity(0.1),
        ),
      ),
      Positioned(
        top: 300,
        right: -40,
        child: _Orb(
          size: 120,
          color: Colors.white.withOpacity(0.05),
        ),
      ),
    ];
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji in glass card
          GlassContainer(
            width: 130,
            height: 130,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(40),
            gradientColors: [
              data.accentColor.withOpacity(0.3),
              data.accentColor.withOpacity(0.1),
            ],
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 60),
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

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            style: AppTextStyles.displayMedium.copyWith(height: 1.2),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.2, delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 20),

          // Subtitle in glass card
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(20),
            child: Text(
              data.subtitle,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.2, delay: 400.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<Color> gradientColors;

  const OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.gradientColors,
  });
}