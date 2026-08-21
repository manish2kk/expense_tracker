# Flutter Commands Cheat Sheet

A quick reference for common Flutter CLI commands — from creating a project to shipping an optimized release build.

---

## 1. Setup & Environment Check

```bash
# Check Flutter installation and environment health
flutter doctor

# Verbose version (shows detailed info per component)
flutter doctor -v

# Check Flutter SDK version
flutter --version

# Upgrade Flutter SDK to latest stable
flutter upgrade

# Switch channel (stable / beta / dev / master)
flutter channel stable
```

---

## 2. Create a Project

```bash
# Create a new Flutter project
flutter create my_app

# Create with a specific organization identifier (for package/bundle IDs)
flutter create --org com.yourcompany my_app

# Create with a specific platform list only (e.g. android, ios, web)
flutter create --platforms=android,ios my_app

# Create a project from a specific template (app, package, plugin, module)
flutter create --template=package my_package

# Re-generate platform folders in an existing project (e.g. after upgrading Flutter)
flutter create .
```

---

## 3. Get Dependencies

```bash
# Fetch packages listed in pubspec.yaml
flutter pub get

# Upgrade all dependencies to latest allowed versions
flutter pub upgrade

# Add a new package
flutter pub add http

# Add a dev dependency
flutter pub add --dev build_runner

# Remove a package
flutter pub remove http

# Check outdated packages
flutter pub outdated
```

---

## 4. Detect Devices / Emulators

```bash
# List all connected devices (physical + emulator + web + desktop)
flutter devices

# List all available Android emulators
flutter emulators

# Launch a specific emulator by ID
flutter emulators --launch <emulator_id>

# Example
flutter emulators --launch Pixel_7_API_34
```

> Tip: For a physical Android phone, enable **Developer Options → USB Debugging**, connect via USB, then run `flutter devices` to confirm it's detected.

---

## 5. Run the App

```bash
# Run on the only connected/available device
flutter run

# Run and pick a device explicitly (use device ID from `flutter devices`)
flutter run -d <device_id>

# Run on Chrome (web)
flutter run -d chrome

# Run on macOS desktop
flutter run -d macos

# Run in release mode (no hot reload, but faster/production-like)
flutter run --release

# Run in profile mode (for performance testing)
flutter run --profile

# Verbose logs while running
flutter run -v
```

**While the app is running (hot commands in terminal):**
| Key | Action |
|---|---|
| `r` | Hot reload |
| `R` | Hot restart |
| `p` | Toggle debug paint |
| `o` | Toggle platform (Android/iOS rendering) |
| `q` | Quit |

---

## 6. Build (Debug / Profile / Release)

### Android

```bash
# Build a debug APK
flutter build apk --debug

# Build a release APK (single, unoptimized-for-size)
flutter build apk --release

# Build split APKs per ABI (smaller size per device architecture)
flutter build apk --split-per-abi

# Build an Android App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build iOS release (requires macOS + Xcode)
flutter build ios --release

# Build an .ipa file for distribution
flutter build ipa
```

### Web

```bash
flutter build web --release
```

### Desktop

```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

---

## 7. Optimized / Smaller Builds

```bash
# Split APK per CPU architecture (much smaller per-device size)
flutter build apk --release --split-per-abi

# Build App Bundle — Play Store auto-generates optimized APKs per device
flutter build appbundle --release

# Analyze APK/app size breakdown
flutter build apk --analyze-size

# Analyze App Bundle size breakdown
flutter build appbundle --analyze-size

# Obfuscate Dart code + generate debug symbols (smaller + more secure release)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Tree-shake icons (removes unused icon glyphs, reduces font asset size) — enabled by default in release builds
flutter build apk --release --tree-shake-icons
```

> **Best practice for Play Store release:**
> ```bash
> flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
> ```

---

## 8. Install on a Device

```bash
# Install the already-built app on a connected device
flutter install

# Install on a specific device
flutter install -d <device_id>

# Manually install a built APK using adb
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Uninstall the app from device
adb uninstall com.yourcompany.my_app
```

---

## 9. Clean & Rebuild

```bash
# Clean build artifacts (fixes many weird build errors)
flutter clean

# Then re-fetch dependencies
flutter pub get
```

---

## 10. Change App Icon

Easiest way — use the `flutter_launcher_icons` package.

```bash
# 1. Add the package
flutter pub add --dev flutter_launcher_icons
```

Add this config to `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  min_sdk_android: 21
  web:
    generate: true
  windows:
    generate: true
  macos:
    generate: true
```

```bash
# 2. Fetch packages
flutter pub get

# 3. Generate icons for all platforms
dart run flutter_launcher_icons
```

> Use a **1024×1024 PNG** with no transparency issues for best results across platforms.

---

## 11. Change App Name

```bash
# Android: edit android/app/src/main/AndroidManifest.xml -> android:label="Your App Name"
# iOS: edit ios/Runner/Info.plist -> <key>CFBundleName</key><string>Your App Name</string>

# Or use the package:
flutter pub add --dev rename
dart run rename setAppName --targets ios,android --value "Your App Name"
```

---

## 12. Change Package / Bundle ID

```bash
flutter pub add --dev rename
dart run rename setBundleId --targets ios,android --value "com.yourcompany.myapp"
```

---

## 13. Testing & Analysis

```bash
# Run all unit/widget tests
flutter test

# Run a specific test file
flutter test test/my_test.dart

# Static code analysis (lint checks)
flutter analyze

# Format code
dart format .
```

---

## 14. App Signing (Android release prep)

```bash
# Generate an upload keystore
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then configure `android/key.properties` and reference it in `android/app/build.gradle` before running:

```bash
flutter build appbundle --release
```

---

## 15. Useful Extras

```bash
# Show connected device logs
flutter logs

# Check Flutter/Dart config
flutter config

# Enable a platform (e.g. desktop support)
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop

# Precache engine artifacts for a platform (speeds up first build)
flutter precache

# Show full list of flutter commands
flutter help

# Help for a specific command
flutter help build
```

---

### Quick Reference Summary

| Task | Command |
|---|---|
| Create project | `flutter create my_app` |
| Get packages | `flutter pub get` |
| List devices | `flutter devices` |
| List emulators | `flutter emulators` |
| Launch emulator | `flutter emulators --launch <id>` |
| Run app | `flutter run -d <device_id>` |
| Debug APK | `flutter build apk --debug` |
| Release APK | `flutter build apk --release` |
| Optimized bundle | `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info` |
| Install on device | `flutter install -d <device_id>` |
| Clean project | `flutter clean` |
| Change icon | `dart run flutter_launcher_icons` |
| Change app name | `dart run rename setAppName --targets ios,android --value "Name"` |