import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/app_limits_repository.dart';
import 'accessibility_service.dart';
import 'usage_stats_service.dart';

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

    // Listen for overlay dismissed from native
    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'overlayDismissed') {
        debugPrint('TriggerService: overlay dismissed — resetting flag');
        _overlayShowing = false;
      }
    });

    await Future.delayed(const Duration(seconds: 2));
    await _syncMonitoredPackages();
  }

  Future<void> _onAppOpened(String packageName) async {

  if (_overlayShowing) return;

  // Fetch fresh usage directly from UsageStatsManager
  final limits = await _repository.getAppLimits();
  final appLimit = limits.where(
    (a) => a.packageName == packageName && a.isEnabled,
  );

  if (appLimit.isEmpty) return;

  final app = appLimit.first;

  // Get real-time usage
  final realUsage = await UsageStatsService.getUsageForPackages([packageName]);
  final freshMinutes = realUsage[packageName] ?? 0;

  debugPrint(
    'TriggerService: $packageName — used=${freshMinutes}m limit=${app.dailyLimitMinutes}m',
  );

  // UsageStatsManager only updates every ~1 min; trigger 1 min early so the
  // check fires within the same window the user hits their limit.
  final effectiveLimit = (app.dailyLimitMinutes - 1).clamp(0, app.dailyLimitMinutes);
  if (freshMinutes < effectiveLimit) return;

  // Save to DB
  await _repository.updateAppLimit(
    app.copyWith(usedMinutesToday: freshMinutes),
  );

  await _triggerOverlay(app.packageName, app.displayName, app.overrideCount);
}

  Future<void> _triggerOverlay(
      String packageName, String appName, int overrideCount) async {
    _overlayShowing = true;
    debugPrint('TriggerService: launching overlay for $appName');

    final prefs = await SharedPreferences.getInstance();
    final showOverrideCount = prefs.getBool('show_override_count') ?? true;
    final positiveFraming = prefs.getBool('positive_framing') ?? true;
    final strictMode = prefs.getBool('strict_mode') ?? false;

    try {
      await _overlayChannel.invokeMethod('showOverlay', {
        'packageName': packageName,
        'appName': appName,
        'overrideCount': overrideCount,
        'showOverrideCount': showOverrideCount,
        'positiveFraming': positiveFraming,
        'strictMode': strictMode,
      });

      // Safety net reset after longest tier + buffer
      Future.delayed(const Duration(seconds: 70), () {
        if (_overlayShowing) {
          _overlayShowing = false;
          debugPrint('TriggerService: safety net reset');
        }
      });
    } catch (e) {
      debugPrint('TriggerService overlay error: $e');
      _overlayShowing = false;
    }
  }

  Future<void> _syncMonitoredPackages() async {
    final limits = await _repository.getAppLimits();
    final packages =
        limits.where((a) => a.isEnabled).map((a) => a.packageName).toList();
    await AppAccessibilityService.updateMonitoredPackages(packages);
    debugPrint('TriggerService: synced ${packages.length} packages');
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