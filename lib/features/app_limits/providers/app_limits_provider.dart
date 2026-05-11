import 'package:flutter/material.dart';
import '../../../data/models/app_limit.dart';
import '../../../data/repositories/app_limits_repository.dart';

class AppLimitsProvider extends ChangeNotifier {
  final AppLimitsRepository _repository = AppLimitsRepository();

  List<AppLimit> _appLimits = [];
  bool _isLoading = true;
  String? _editingPackage;

  List<AppLimit> get appLimits => _appLimits;
  bool get isLoading => _isLoading;
  String? get editingPackage => _editingPackage;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    _appLimits = await _repository.getAppLimits();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateLimit(String packageName, int newLimitMinutes) async {
    final index =
        _appLimits.indexWhere((a) => a.packageName == packageName);
    if (index == -1) return;
    final updated =
        _appLimits[index].copyWith(dailyLimitMinutes: newLimitMinutes);
    _appLimits[index] = updated;
    await _repository.updateAppLimit(updated);
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

  void setEditing(String? packageName) {
    _editingPackage = packageName;
    notifyListeners();
  }

  String formatLimit(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}