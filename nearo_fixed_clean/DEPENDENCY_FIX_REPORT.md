# Nearo dependency hotfix report

## Why this hotfix exists

The Firebase Studio / IDX web build failed because the project was using older FlutterFire web packages pulled by older Firebase constraints. The failing packages included:

- `firebase_auth_web-5.8.13`
- `firebase_messaging_web-3.5.18`
- `firebase_storage_web-3.6.22`

Those packages produced `PromiseJsImpl`, `handleThenable`, `dartify`, and `jsify` errors in the current Flutter/Dart web compiler. Flutter's newer Material theme API also rejected `CardTheme` where `CardThemeData` is now expected.

## Files changed

### `pubspec.yaml`

Updated Firebase / FlutterFire dependencies:

```yaml
firebase_core: ^4.8.0
firebase_auth: ^6.5.0
cloud_firestore: ^6.4.0
cloud_functions: ^6.3.0
firebase_storage: ^13.4.0
firebase_messaging: ^16.2.1
firebase_analytics: ^12.4.0
firebase_crashlytics: ^5.2.1
firebase_performance: ^0.11.4
```

Also updated:

```yaml
flutter_riverpod: ^2.6.1
google_sign_in: ^6.3.0
```

`google_sign_in` intentionally remains on the 6.x line because version 7.x has a breaking sign-in API migration. This project currently does not use Google sign-in directly in code, but keeping 6.x avoids unnecessary auth refactoring.

### `lib/core/theme/nearo_theme.dart`

Changed:

```dart
cardTheme: CardTheme(...)
```

to:

```dart
cardTheme: CardThemeData(...)
```

## Recommended clean run commands

Run these from the real Flutter project root, where `pubspec.yaml` exists:

```bash
cd ~/nearo/nearo_fixed_clean
flutter clean
rm -f pubspec.lock
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

If Firebase Studio asks to open a forwarded port, open port `8080`.

## Notes

This package was patched for the online Flutter environment. I could not run `flutter analyze` or `flutter run` inside the ChatGPT container because Flutter SDK is not installed there.
