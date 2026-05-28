import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    'com.zhiliaoapp.musically',
    'com.instagram.android',
    'com.twitter.android',
    'com.google.android.youtube',
    'com.facebook.katana',
  ];

  // App display names
  static const Map<String, String> appDisplayNames = {
    'com.zhiliaoapp.musically': 'TikTok',
    'com.instagram.android': 'Instagram',
    'com.twitter.android': 'Twitter / X',
    'com.google.android.youtube': 'YouTube',
    'com.facebook.katana': 'Facebook',
  };

  // App icons using FontAwesome
  static const Map<String, IconData> appIcons = {
    'com.zhiliaoapp.musically': FontAwesomeIcons.tiktok,
    'com.instagram.android': FontAwesomeIcons.instagram,
    'com.twitter.android': FontAwesomeIcons.xTwitter,
    'com.google.android.youtube': FontAwesomeIcons.youtube,
    'com.facebook.katana': FontAwesomeIcons.facebook,
    'com.snapchat.android': FontAwesomeIcons.snapchat,
    'com.whatsapp': FontAwesomeIcons.whatsapp,
    'com.reddit.frontpage': FontAwesomeIcons.reddit,
    'com.linkedin.android': FontAwesomeIcons.linkedin,
    'com.discord': FontAwesomeIcons.discord,
    'com.spotify.music': FontAwesomeIcons.spotify,
    'com.telegram.messenger': FontAwesomeIcons.telegram,
  };

  // App icon colors
  static const Map<String, int> appIconColors = {
    'com.zhiliaoapp.musically': 0xFF000000,
    'com.instagram.android': 0xFFE1306C,
    'com.twitter.android': 0xFF000000,
    'com.google.android.youtube': 0xFFFF0000,
    'com.facebook.katana': 0xFF1877F2,
    'com.snapchat.android': 0xFFFFFC00,
    'com.whatsapp': 0xFF25D366,
    'com.reddit.frontpage': 0xFFFF4500,
    'com.linkedin.android': 0xFF0A66C2,
    'com.discord': 0xFF5865F2,
    'com.spotify.music': 0xFF1DB954,
    'com.telegram.messenger': 0xFF2AABEE,
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