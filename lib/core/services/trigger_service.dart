import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/app_limits_repository.dart';
import 'accessibility_service.dart';

class TriggerService {
  static final TriggerService instance = TriggerService._init();
  TriggerService._init();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const MethodChannel _overlayChannel =
      MethodChannel('com.austennkuna.intention/overlay');

  StreamSubscription<String>? _subscription;
  final AppLimitsRepository _repository = AppLimitsRepository();
  bool _overlayShowing = false;

  Future<void> initialise() async {
    _subscription?.cancel();
    _subscription = AppAccessibilityService.appOpenedStream.listen(
      _onAppOpened,
      onError: (e) => debugPrint('TriggerService error: $e'),
    );

    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'overlayDismissed') {
        debugPrint('TriggerService: overlay dismissed — resetting flag');
        _overlayShowing = false;
      }
    });

    await Future.delayed(const Duration(seconds: 2));
    await _syncMonitoredPackages();
  }

  Future<void> _syncMonitoredPackages() async {
    final limits = await _repository.getAppLimits();
    final packages = limits
        .where((a) => a.isEnabled)
        .map((a) => a.packageName)
        .toList();
    await AppAccessibilityService.updateMonitoredPackages(packages);
    debugPrint('TriggerService: synced ${packages.length} packages');
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

    debugPrint('TriggerService: launching overlay for ${app.displayName}');

    try {
      await _overlayChannel.invokeMethod('showOverlay', {
        'packageName': app.packageName,
        'appName': app.displayName,
        'overrideCount': app.overrideCount,
      });

      // Fallback reset — longer than the shortest wait tier (5s)
      Future.delayed(const Duration(seconds: 6), () {
        _overlayShowing = false;
        debugPrint('TriggerService: overlay flag reset (fallback)');
      });
    } catch (e) {
      debugPrint('TriggerService overlay error: $e');
      _overlayShowing = false;
    }
  }

  void onOverlayDismissed() {
    _overlayShowing = false;
    debugPrint('TriggerService: overlay dismissed — resetting flag');
  }

  Future<void> refreshMonitoredPackages() async {
    await _syncMonitoredPackages();
  }

  void dispose() {
    _subscription?.cancel();
  }
}