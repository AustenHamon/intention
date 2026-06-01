import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/services/trigger_service.dart';
import 'core/services/usage_stats_service.dart';
import 'data/repositories/app_limits_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await AppLimitsRepository().seedDefaultApps();
  TriggerService.instance.initialise();

  // Start background usage sync
  _startUsageSync();

  runApp(const IntentionApp());
}

void _startUsageSync() {
  _syncUsage();
  Timer.periodic(const Duration(minutes: 2), (_) async {
    await _syncUsage();
  });
}

Future<void> _syncUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final repo = AppLimitsRepository();
  final limits = await repo.getAppLimits();
  if (limits.isEmpty) return;

  final hasPermission = await UsageStatsService.hasPermission();
  if (!hasPermission) return;

  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final savedDate = prefs.getString('last_sync_date') ?? '';
  if (savedDate.isNotEmpty && savedDate != todayStr) {
    debugPrint('UsageSync: new day ($todayStr) — saving yesterday then resetting');

    // Save yesterday's final snapshot BEFORE resetting
    await repo.saveTodayUsage();
    debugPrint('UsageSync: yesterday snapshot saved for $savedDate');

    // Reset everything to 0
    for (final app in limits) {
      await repo.updateAppLimit(
        app.copyWith(usedMinutesToday: 0, overrideCount: 0),
      );
    }
    debugPrint('UsageSync: usage reset for new day');
  }
  await prefs.setString('last_sync_date', todayStr);

  final packages = limits.map((a) => a.packageName).toList();
  final realUsage = await UsageStatsService.getUsageForPackages(packages);

  for (final app in limits) {
    await repo.updateAppLimit(
      app.copyWith(usedMinutesToday: realUsage[app.packageName] ?? 0),
    );
  }

  await repo.saveTodayUsage();
  debugPrint('UsageSync: updated ${limits.length} apps — $todayStr');
}

class IntentionApp extends StatelessWidget {
  const IntentionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppLimitsRepository>(
          create: (_) => AppLimitsRepository(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Intention',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}