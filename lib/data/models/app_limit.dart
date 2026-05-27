class AppLimit {
  final String packageName;
  final String displayName;
  final String emoji;
  final int dailyLimitMinutes;
  final bool isEnabled;
  final int usedMinutesToday;
  final int overrideCount;

  const AppLimit({
    required this.packageName,
    required this.displayName,
    required this.emoji,
    required this.dailyLimitMinutes,
    this.isEnabled = true,
    this.usedMinutesToday = 0,
    this.overrideCount = 0,
  });

  double get usagePercent {
    if (dailyLimitMinutes == 0) return 0;
    return (usedMinutesToday / dailyLimitMinutes).clamp(0.0, 1.0);
  }

  bool get isOverLimit => usedMinutesToday >= dailyLimitMinutes;

  int get remainingMinutes =>
      (dailyLimitMinutes - usedMinutesToday).clamp(0, dailyLimitMinutes);

  AppLimit copyWith({
    String? packageName,
    String? displayName,
    String? emoji,
    int? dailyLimitMinutes,
    bool? isEnabled,
    int? usedMinutesToday,
    int? overrideCount,
  }) {
    return AppLimit(
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      emoji: emoji ?? this.emoji,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      overrideCount: overrideCount ?? this.overrideCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'displayName': displayName,
      'emoji': emoji,
      'dailyLimitMinutes': dailyLimitMinutes,
      'isEnabled': isEnabled ? 1 : 0,
      'usedMinutesToday': usedMinutesToday,
      'overrideCount': overrideCount,
    };
  }

  factory AppLimit.fromMap(Map<String, dynamic> map) {
    return AppLimit(
      packageName: map['packageName'],
      displayName: map['displayName'],
      emoji: map['emoji'],
      dailyLimitMinutes: map['dailyLimitMinutes'],
      isEnabled: map['isEnabled'] == 1,
      usedMinutesToday: map['usedMinutesToday'] ?? 0,
      overrideCount: map['overrideCount'] ?? 0,
    );
  }
}