import 'package:flutter/material.dart';
import '../../../data/models/app_limit.dart';
import '../../../data/repositories/app_limits_repository.dart';
import '../../../core/services/usage_stats_service.dart';
import 'dart:async';

class DashboardProvider extends ChangeNotifier {
  final AppLimitsRepository _repository = AppLimitsRepository();

  List<AppLimit> _appLimits = [];
  bool _isLoading = true;

  List<AppLimit> get appLimits => _appLimits;
  bool get isLoading => _isLoading;

  int get totalAppsMonitored => _appLimits.where((a) => a.isEnabled).length;

  int get appsOverLimit => _appLimits.where((a) => a.isOverLimit).length;

  int get totalMinutesUsed =>
      _appLimits.fold(0, (sum, a) => sum + a.usedMinutesToday);

  int get totalMinutesAllowed =>
      _appLimits.fold(0, (sum, a) => sum + a.dailyLimitMinutes);

  double get overallUsagePercent {
    if (totalMinutesAllowed == 0) return 0;
    return (totalMinutesUsed / totalMinutesAllowed).clamp(0.0, 1.0);
  }

  String get greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

Future<void> loadData() async {
  _isLoading = true;
  notifyListeners();

  final hasPermission = await UsageStatsService.hasPermission();
  _appLimits = await _repository.getAppLimits();

  if (hasPermission && _appLimits.isNotEmpty) {
    final packages = _appLimits.map((a) => a.packageName).toList();
    final realUsage = await UsageStatsService.getUsageForPackages(packages);

    _appLimits = await Future.wait(_appLimits.map((app) async {
      final updated = app.copyWith(
        usedMinutesToday: realUsage[app.packageName] ?? 0,
      );
      // Save real usage back to database so TriggerService can read it
      await _repository.updateAppLimit(updated);
      return updated;
    }));
  }

  _isLoading = false;
  notifyListeners();
}

  Future<void> toggleApp(String packageName) async {
  final index =
      _appLimits.indexWhere((a) => a.packageName == packageName);
  if (index == -1) return;
  final updated =
      _appLimits[index].copyWith(isEnabled: !_appLimits[index].isEnabled);
  _appLimits[index] = updated;
  await _repository.updateAppLimit(updated);
  notifyListeners();
}
Timer? _refreshTimer;

void startAutoRefresh() {
  _refreshTimer?.cancel();
  // Refresh usage every 60 seconds
  _refreshTimer = Timer.periodic(
    const Duration(seconds: 60),
    (_) => loadData(),
  );
}

void stopAutoRefresh() {
  _refreshTimer?.cancel();
  _refreshTimer = null;
}

@override
void dispose() {
  stopAutoRefresh();
  super.dispose();
}
}