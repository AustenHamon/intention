import 'package:usage_stats/usage_stats.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class UsageStatsService {
  // Check if permission is granted
  static Future<bool> hasPermission() async {
    return await UsageStats.checkUsagePermission() ?? false;
  }

  // Open the usage access settings page for the user to grant permission
  static Future<void> requestPermission() async {
    await UsageStats.grantUsagePermission();
  }

  // Get today's usage in minutes per package name
  static Future<Map<String, int>> getTodayUsageMinutes() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final stats = await UsageStats.queryUsageStats(
        startOfDay,
        now,
      );

      final Map<String, int> usageMap = {};

      for (final stat in stats) {
        if (stat.packageName != null && stat.totalTimeInForeground != null) {
          final minutes =
              (int.parse(stat.totalTimeInForeground!) / 60000).round();
          if (minutes > 0) {
            usageMap[stat.packageName!] = minutes;
          }
        }
      }

      return usageMap;
    } catch (e) {
      return {};
    }
  }

  // Get all installed apps on the device
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        true,
        true,
      );
      return apps;
    } catch (e) {
      return [];
    }
  }

  // Get usage for specific packages only
  static Future<Map<String, int>> getUsageForPackages(
      List<String> packages) async {
    final allUsage = await getTodayUsageMinutes();
    final Map<String, int> filtered = {};
    for (final package in packages) {
      filtered[package] = allUsage[package] ?? 0;
    }
    return filtered;
  }
}