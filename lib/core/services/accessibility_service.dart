import 'package:flutter/services.dart';

class AppAccessibilityService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.austennkuna.intention/accessibility');

  static const EventChannel _eventChannel =
      EventChannel('com.austennkuna.intention/app_events');

  // Check if accessibility service is enabled
  static Future<bool> isEnabled() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Open accessibility settings
  static Future<void> openSettings() async {
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // Handle error
    }
  }

  // Stream of package names when apps are opened
  static Stream<String> get appOpenedStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString());
  }
}