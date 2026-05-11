class AppConstants {
  // App info
  static const String appName = 'Intention';
  static const String appVersion = '1.0.0';

  // Onboarding
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Cooling ladder wait times (in seconds)
  static const int tier1Wait = 5;
  static const int tier2Wait = 15;
  static const int tier3Wait = 60;

  // Default monitored apps
  static const List<String> defaultMonitoredApps = [
    'com.zhiliaoapp.musically', // TikTok
    'com.instagram.android',    // Instagram
    'com.twitter.android',      // Twitter/X
    'com.google.android.youtube', // YouTube
    'com.facebook.katana',      // Facebook
  ];

  // App display names
  static const Map<String, String> appDisplayNames = {
    'com.zhiliaoapp.musically': 'TikTok',
    'com.instagram.android': 'Instagram',
    'com.twitter.android': 'Twitter / X',
    'com.google.android.youtube': 'YouTube',
    'com.facebook.katana': 'Facebook',
  };

  // App icons (emoji fallback)
  static const Map<String, String> appEmojis = {
    'com.zhiliaoapp.musically': '🎵',
    'com.instagram.android': '📸',
    'com.twitter.android': '🐦',
    'com.google.android.youtube': '▶️',
    'com.facebook.katana': '👥',
  };

  // Default daily limits (in minutes)
  static const Map<String, int> defaultLimits = {
    'com.zhiliaoapp.musically': 30,
    'com.instagram.android': 30,
    'com.twitter.android': 20,
    'com.google.android.youtube': 45,
    'com.facebook.katana': 20,
  };
}