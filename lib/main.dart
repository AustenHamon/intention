import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

// Sync real usage to DB every 2 minutes so TriggerService always has fresh data
void _startUsageSync() {
  Timer.periodic(const Duration(minutes: 2), (_) async {
    final repo = AppLimitsRepository();
    final limits = await repo.getAppLimits();
    if (limits.isEmpty) return;

    final hasPermission = await UsageStatsService.hasPermission();
    if (!hasPermission) return;

    final packages = limits.map((a) => a.packageName).toList();
    final realUsage = await UsageStatsService.getUsageForPackages(packages);

    for (final app in limits) {
      final updated = app.copyWith(
        usedMinutesToday: realUsage[app.packageName] ?? 0,
      );
      await repo.updateAppLimit(updated);
    }

    // Save daily snapshot for historical stats
    await repo.saveTodayUsage();

    debugPrint('UsageSync: updated ${limits.length} apps');
  });
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