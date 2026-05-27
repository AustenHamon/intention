import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/app_limits_repository.dart';
import 'accessibility_service.dart';

class TriggerService {
  static final TriggerService instance = TriggerService._init();
  TriggerService._init();

  // Navigator key — passed to GoRouter so we can navigate from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  StreamSubscription<String>? _subscription;
  final AppLimitsRepository _repository = AppLimitsRepository();
  bool _overlayShowing = false;

  void initialise() {
    _subscription?.cancel();
    _subscription = AppAccessibilityService.appOpenedStream.listen(
      _onAppOpened,
      onError: (e) => debugPrint('TriggerService error: $e'),
    );
  }
  void onOverlayDismissed() {
    _overlayShowing = false;
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _onAppOpened(String packageName) async {
  if (_overlayShowing) return;

  final context = TriggerService.navigatorKey.currentContext;
  if (context == null) return;

  final limits = await _repository.getAppLimits();
  final match = limits.where(
    (a) => a.packageName == packageName && a.isEnabled && a.isOverLimit,
  );

  if (match.isEmpty) return;

  final app = match.first;
  _overlayShowing = true;

  debugPrint('TriggerService: cooling ladder for ${app.displayName}');

  // Small delay to let the app come to foreground
  await Future.delayed(const Duration(milliseconds: 300));

  final ctx = TriggerService.navigatorKey.currentContext;
  if (ctx == null) return;

  ctx.go('/cooling-ladder', extra: {
    'packageName': app.packageName,
    'appName': app.displayName,
    'appEmoji': app.emoji,
    'overrideCount': app.overrideCount,
  });
}
}