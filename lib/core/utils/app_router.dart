import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/app_limits/screens/app_limits_screen.dart';
import '../../core/constants/app_constants.dart';

class AppRouter {
  static Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
    return onboardingDone ? '/dashboard' : '/onboarding';
  }

  static GoRouter get router => GoRouter(
        initialLocation: '/onboarding',
        redirect: (context, state) async {
          final initialRoute = await _getInitialRoute();
          if (state.matchedLocation == '/onboarding' &&
              initialRoute == '/dashboard') {
            return '/dashboard';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/app-limits',
            builder: (context, state) => const AppLimitsScreen(),
          ),
        ],
      );
}