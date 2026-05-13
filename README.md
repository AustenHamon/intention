# intention
Per-App Screen Time Control with Intelligent Friction

# INTENTION — Per-App Screen Time Control with Intelligent Friction

> M4 Submission | BICT421 Mini Project | Theme 6: Open Pitch
> Developer: Austen Nkuna | UMP SCMS

## What is Intention?

Intention is an Android app that helps users break mindless scrolling habits
by introducing psychologically-grounded friction before accessing
time-limited apps. Instead of blocking access outright, it uses a
"cooling ladder" — escalating wait times and intention statements
that make unconscious app use harder without preventing emergency access.

## Setup & Run Instructions

### Prerequisites
- Flutter SDK (3.x or later)
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API 26+)

### Steps
1. Clone the repository:
   git clone https://github.com/YOUR_USERNAME/intention.git
   cd intention

2. Install dependencies:
   flutter pub get

3. Run on connected device or emulator:
   flutter run

4. Build release APK:
   flutter build apk --release
   Output: build/app/outputs/flutter-apk/app-release.apk

## Project Structure

lib/
├── core/
│   ├── constants/        # App-wide constants & defaults
│   ├── theme/            # Colors, text styles, app theme
│   └── utils/            # Router configuration
├── data/
│   ├── database/         # SQLite database helper
│   ├── models/           # AppLimit model
│   └── repositories/     # Data access layer
├── features/
│   ├── onboarding/       # 3-slide onboarding flow
│   ├── dashboard/        # Home screen with usage overview
│   ├── app_limits/       # Per-app limit configuration
│   ├── cooling_ladder/   # Intervention overlay (core feature)
│   ├── stats/            # Weekly statistics screen
│   └── settings/         # App preferences
└── shared/
    └── widgets/          # GlassContainer, BottomNavBar

---

## Key Features (M4 MVP)

- Liquid glass UI with animated backgrounds
- 3-slide onboarding with permission explanation
- Home dashboard with usage rings and stat cards
- Per-app daily limit configuration with slider
- Cooling ladder overlay with 3 tiers:
  - Tier 1 (5s): Pause and breathe
  - Tier 2 (15s): Breathe + intention statement
  - Tier 3 (60s): Full reflection + intention
- Weekly statistics with interactive bar chart
- Settings with strict mode, reminders, positive framing

---

## Pending for M5

- Real UsageStatsManager integration (live app tracking)
- AccessibilityService for automatic launch detection
- Push notifications for daily summaries
- Data export feature
- Widget for home screen quick stats

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| flutter_animate | ^4.5.0 | Animations |
| go_router | ^14.2.7 | Navigation |
| provider | ^6.1.2 | State management |
| sqflite | ^2.3.3+1 | Local database |
| shared_preferences | ^2.3.2 | Settings storage |
| percent_indicator | ^4.2.3 | Progress rings |
| google_fonts | ^6.2.1 | Typography |
| smooth_page_indicator | ^1.2.0+3 | Onboarding dots |

## Known Issues

- Usage data is currently simulated (demo mode) —
  real UsageStatsManager integration is planned for M5
- Cooling ladder is triggered manually via demo button —
  AccessibilityService hook planned for M5
- Strict mode toggle is UI only — DevicePolicyManager
  integration planned for M5

## Privacy

All data is stored locally on device via SQLite.
No accounts, no cloud sync, no analytics, no ads.
POPIA compliant by design.