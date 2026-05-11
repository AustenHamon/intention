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

  Future<void> seedDefaultApps() async {
    final existing = await _db.getAllAppLimits();
    if (existing.isNotEmpty) return;

    for (final package in AppConstants.defaultMonitoredApps) {
      final limit = AppLimit(
        packageName: package,
        displayName: AppConstants.appDisplayNames[package] ?? package,
        emoji: AppConstants.appEmojis[package] ?? '📱',
        dailyLimitMinutes: AppConstants.defaultLimits[package] ?? 30,
      );
      await _db.insertAppLimit(limit);
    }
  }
}