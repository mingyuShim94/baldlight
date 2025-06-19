# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BaldLight is a Flutter-based Korean mobile app that combines flashlight functionality with entertaining bald character animations. The app serves as a humorous take on utility apps, featuring ad monetization through Google AdMob and a collection-based gamification system.

## Core Architecture

### Service Layer (Singleton Pattern)
- **FlashlightService**: Hardware flashlight control using `torch_light` plugin with custom exception handling
- **AdMobService**: Google AdMob integration for App Open Ads with environment-aware configuration
- **AppLifecycleService**: App lifecycle management and ad timing logic

### Screen Structure
- **SplashScreen**: Initial loading screen with ad display logic
- **FlashlightMainPage**: Main UI with full-screen bald character images and flashlight controls

## Development Commands

### Allowed Commands
```bash
flutter pub upgrade    # Update dependencies
flutter clean          # Clear build cache
flutter doctor         # Check development environment
flutter doctor -v      # Detailed environment info
flutter test           # Run tests
flutter devices        # List connected devices (info only)
```

### Icon Generation
```bash
flutter pub run flutter_launcher_icons
```

## Build Configuration

### Platform Requirements
- **Flutter SDK**: 3.6.0+
- **Android**: minSdk 23 (required by torch_light)
- **iOS**: 13.0+

### Ad Unit IDs (Production)
- **Android App**: `ca-app-pub-5294358720517664~6429367856`
- **Android Interstitial**: `ca-app-pub-5294358720517664/6026027260`
- **iOS App**: `ca-app-pub-5294358720517664~9561113448`
- **iOS Interstitial**: `ca-app-pub-5294358720517664/3403749268`

Debug mode automatically uses test ad IDs.

## Dependencies & Tech Stack

### Core Dependencies
- `torch_light: ^1.1.0` - Flashlight hardware control
- `google_mobile_ads: ^6.0.0` - AdMob integration
- `flutter_launcher_icons: ^0.14.4` - Custom app icons

### Platform Configuration
- **Android**: Requires FLASHLIGHT and CAMERA permissions in AndroidManifest.xml
- **iOS**: Requires NSCameraUsageDescription in Info.plist

## Asset Management

### Image Assets
- `assets/images/on.webp` - Flashlight ON state
- `assets/images/off.webp` - Flashlight OFF state
- `assets/images/bald_styles/` - Additional character styles (future use)
- `assets/icon/icon.png` - App icon source

### Icon Configuration
Icons are generated automatically via `flutter_launcher_icons.yaml` with platform-specific settings.

## Code Architecture Patterns

### Exception Handling
Custom flashlight exceptions: `FlashlightException`, `FlashlightNotSupportedException`, `FlashlightInUseException`

### State Management
- Services use singleton pattern with internal constructors
- UI uses StatefulWidget with proper lifecycle management
- Animation controllers for UI feedback (150ms scale, 300ms transitions)

### UI Design
- Material 3 with orange color scheme
- System theme mode support (light/dark)
- Full-screen image display with responsive controls
- Accessibility support with semantic labels

## Development Workflow Restrictions

**Important**: Do not execute Flutter build, run, or pub get commands. The user handles:
- Dependency installation
- Code analysis
- Building
- Device testing
- App execution

## Testing Strategy

- **Widget Tests**: UI component testing (currently minimal setup)
- **Physical Device Required**: Flashlight functionality only works on real devices
- **Ad Testing**: Automatic test ad units in debug mode

## Performance Considerations

- **Ad Caching**: 4-hour expiration cycle
- **Response Time**: Flashlight toggle <200ms requirement
- **Memory Usage**: Target ≤150MB
- **App Size**: Target ≤20MB

## Key Files Structure

```
lib/
├── main.dart                     # App entry point & main flashlight UI
├── screens/
│   └── splash_screen.dart       # Splash screen with ad loading
└── services/
    ├── flashlight_service.dart  # Hardware flashlight control
    ├── admob_service.dart      # Ad management (App Open Ads)
    └── app_lifecycle_service.dart # App lifecycle & ad timing
```

## Future Architecture Notes

The current implementation is Phase 1 of a larger roadmap. Planned features include:
- Counting/collection system with rewarded ads
- Multiple bald character styles
- Settings screen with customization options
- Firebase Remote Config for feature flags

The service layer architecture is designed to accommodate these future features without major refactoring.

## Language Instructions
- **메모**: 코드 및 프로젝트 관련 모든 설명은 한국어로 처리