import 'package:flutter/material.dart';
import '../../../data/models/app_limit.dart';
import '../../../data/repositories/app_limits_repository.dart';

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

    // Load from DB
    _appLimits = await _repository.getAppLimits();

    // Simulate some usage data for demo purposes
    if (_appLimits.isNotEmpty) {
      _appLimits = _appLimits.map((app) {
        final demoUsage = <String, int>{
          'com.zhiliaoapp.musically': 45,
          'com.instagram.android': 28,
          'com.twitter.android': 12,
          'com.google.android.youtube': 67,
          'com.facebook.katana': 8,
        };
        return app.copyWith(
          usedMinutesToday: demoUsage[app.packageName] ?? 0,
        );
      }).toList();
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

  Future<void> refresh() async => loadData();
}