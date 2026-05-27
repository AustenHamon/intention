import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/app_limits_repository.dart';
import '../../../core/services/trigger_service.dart';

enum CoolingTier { tier1, tier2, tier3 }

enum AppOverlayState { pausing, breathing, intention, granted, exited }

class CoolingLadderProvider extends ChangeNotifier {
  final AppLimitsRepository _repository = AppLimitsRepository();

  String packageName = '';
  String appName = '';
  String appEmoji = '';

  CoolingTier _currentTier = CoolingTier.tier1;
  AppOverlayState _overlayState = AppOverlayState.pausing;


  int _secondsRemaining = 0;
  bool _timerRunning = false;
  String _intentionText = '';
  int _overrideCount = 0;

  CoolingTier get currentTier => _currentTier;
  AppOverlayState get overlayState => _overlayState;
  int get secondsRemaining => _secondsRemaining;
  bool get timerRunning => _timerRunning;
  String get intentionText => _intentionText;
  int get overrideCount => _overrideCount;

  int get waitSeconds {
    switch (_currentTier) {
      case CoolingTier.tier1:
        return AppConstants.tier1Wait;
      case CoolingTier.tier2:
        return AppConstants.tier2Wait;
      case CoolingTier.tier3:
        return AppConstants.tier3Wait;
    }
  }

  String get tierLabel {
    switch (_currentTier) {
      case CoolingTier.tier1:
        return 'Take a breath';
      case CoolingTier.tier2:
        return 'Pause & reflect';
      case CoolingTier.tier3:
        return 'Are you sure?';
    }
  }

  String get tierMessage {
    switch (_currentTier) {
      case CoolingTier.tier1:
        return 'You\'ve reached your limit for $appName. Take a moment before continuing.';
      case CoolingTier.tier2:
        return 'This is your second override today. Is this how you want to spend your time?';
      case CoolingTier.tier3:
        return 'You\'ve overridden your limit multiple times. Please state your intention clearly.';
    }
  }

  bool get requiresIntention =>
      _currentTier == CoolingTier.tier2 ||
      _currentTier == CoolingTier.tier3;

  bool get canProceed =>
      !_timerRunning &&
      (!requiresIntention || _intentionText.trim().length >= 5);

  void initialise(String package, String name, String emoji, int overrides) {
    packageName = package;
    appName = name;
    appEmoji = emoji;
    _overrideCount = overrides;
    _currentTier = _tierFromCount(overrides);
    _overlayState = AppOverlayState.pausing;
    _intentionText = '';
    startTimer();
  }

  CoolingTier _tierFromCount(int count) {
    if (count == 0) return CoolingTier.tier1;
    if (count == 1) return CoolingTier.tier2;
    return CoolingTier.tier3;
  }

  void startTimer() {
    _secondsRemaining = waitSeconds;
    _timerRunning = true;
    notifyListeners();
    _tick();
  }

  void _tick() async {
    while (_secondsRemaining > 0 && _timerRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (_timerRunning) {
        _secondsRemaining--;
        if (_secondsRemaining == 0) {
          _timerRunning = false;
          _overlayState = requiresIntention
              ? AppOverlayState.intention
              : AppOverlayState.breathing;
        }
        notifyListeners();
      }
    }
  }

  void updateIntention(String text) {
    _intentionText = text;
    notifyListeners();
  }

  Future<void> proceedToApp() async {
  if (!canProceed) return;
  await _repository.logOverride(packageName, _overrideCount + 1);
  _overlayState = AppOverlayState.granted;
  TriggerService.instance.onOverlayDismissed();
  notifyListeners();
}

void exitToHome() {
  _overlayState = AppOverlayState.exited;
  _timerRunning = false;
  TriggerService.instance.onOverlayDismissed();
  notifyListeners();
}
}