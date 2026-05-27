import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppAccessibilityService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.austennkuna.intention/accessibility');

  static const EventChannel _eventChannel =
      EventChannel('com.austennkuna.intention/app_events');

  static Future<bool> isEnabled() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } catch (e) {}
  }

  // Send monitored packages to Kotlin so it only broadcasts those
  static Future<void> updateMonitoredPackages(List<String> packages) async {
    try {
      await _methodChannel.invokeMethod('updateMonitoredPackages', {
        'packages': packages,
      });
    } catch (e) {
      debugPrint('updateMonitoredPackages error: $e');
    }
  }

  static Stream<String> get appOpenedStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString());
  }
}