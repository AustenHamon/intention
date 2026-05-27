import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/app_limits_repository.dart';
import 'accessibility_service.dart';

class TriggerService {
  static final TriggerService instance = TriggerService._init();
  TriggerService._init();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  StreamSubscription<String>? _subscription;
  final AppLimitsRepository _repository = AppLimitsRepository();
  bool _overlayShowing = false;

Future<void> initialise() async {
  _subscription?.cancel();
  _subscription = AppAccessibilityService.appOpenedStream.listen(
    _onAppOpened,
    onError: (e) => debugPrint('TriggerService error: $e'),
  );

  // Delay sync to ensure database is ready
  await Future.delayed(const Duration(seconds: 2));
  await _syncMonitoredPackages();
}

  // Sync monitored packages to Kotlin accessibility service
Future<void> _syncMonitoredPackages() async {
  final limits = await _repository.getAppLimits();
  final packages = limits
      .where((a) => a.isEnabled)
      .map((a) => a.packageName)
      .toList();
  
  debugPrint('TriggerService: found ${limits.length} limits in DB');
  debugPrint('TriggerService: syncing packages: $packages');
  
  await AppAccessibilityService.updateMonitoredPackages(packages);
  debugPrint('TriggerService: synced ${packages.length} monitored packages to Kotlin');
}

  Future<void> _onAppOpened(String packageName) async {
    if (_overlayShowing) return;

    final limits = await _repository.getAppLimits();

    final match = limits.where(
      (a) => a.packageName == packageName && a.isEnabled && a.isOverLimit,
    );

    debugPrint('TriggerService: $packageName — over limit: ${match.isNotEmpty}');

    if (match.isEmpty) return;

    final app = match.first;
    _overlayShowing = true;

    debugPrint('TriggerService: cooling ladder for ${app.displayName}');

    await Future.delayed(const Duration(milliseconds: 300));

    final ctx = TriggerService.navigatorKey.currentContext;
    if (ctx == null) {
      _overlayShowing = false;
      return;
    }

    ctx.go('/cooling-ladder', extra: {
      'packageName': app.packageName,
      'appName': app.displayName,
      'appEmoji': app.emoji,
      'overrideCount': app.overrideCount,
    });
  }

  void onOverlayDismissed() {
    _overlayShowing = false;
  }

  // Call this after user updates app limits
  Future<void> refreshMonitoredPackages() async {
    await _syncMonitoredPackages();
  }

  void dispose() {
    _subscription?.cancel();
  }
}