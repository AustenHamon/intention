import '../database/database_helper.dart';
import '../models/app_limit.dart';
import '../../core/constants/app_constants.dart';

class AppLimitsRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<AppLimit>> getAppLimits() async {
    return await _db.getAllAppLimits();
  }

  Future<void> saveAppLimit(AppLimit limit) async {
    await _db.insertAppLimit(limit);
  }

  Future<void> updateAppLimit(AppLimit limit) async {
    await _db.updateAppLimit(limit);
  }

  Future<void> deleteAppLimit(String packageName) async {
    await _db.deleteAppLimit(packageName);
  }

  Future<void> logOverride(String packageName, int tier) async {
    await _db.logOverride(packageName, tier);
  }

  Future<void> saveTodayUsage() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final limits = await getAppLimits();
    for (final app in limits) {
      await _db.saveDailyUsage(app.packageName, dateStr, app.usedMinutesToday);
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyBarData() async {
    final records = await _db.getWeeklyUsage();

    final Map<String, int> dailyTotals = {};
    for (final record in records) {
      final date = record['date'] as String;
      final minutes = record['totalMinutes'] as int;
      dailyTotals[date] = (dailyTotals[date] ?? 0) + minutes;
    }

    final List<Map<String, dynamic>> result = [];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      result.add({
        'total': dailyTotals[dateStr] ?? 0,
        'overrides': 0,
        'topApp': '',
        'date': dateStr,
      });
    }
    return result;
  }

  Future<void> seedDefaultApps() async {
  final existing = await _db.getAllAppLimits();
  if (existing.isNotEmpty) return;

  for (final package in AppConstants.defaultMonitoredApps) {
    final limit = AppLimit(
      packageName: package,
      displayName: AppConstants.appDisplayNames[package] ?? package,
      dailyLimitMinutes: AppConstants.defaultLimits[package] ?? 30,
    );
    await _db.insertAppLimit(limit);
  }
}
}