# Nearo

Nearo is a proximity-based Flutter/Firebase social nightlife app. This package is a cleaned, launchable baseline that fixes the original prototype blockers: invalid imports, missing Firebase bootstrap files, missing dependencies, broken code generation dependencies, unsafe Firestore rules, missing Cloud Functions package files, and incomplete project documentation.

## What is included

- Clean Flutter app structure with Riverpod state management.
- Email/password auth with a demo-mode fallback when Firebase credentials are not yet real.
- Nearby users, venue discovery, signals, matches, profile visibility and basic chat-ready data layer.
- Firebase Firestore rules, indexes, Cloud Functions and Storage rules.
- Android scaffold and web scaffold.
- No required build_runner/code-generation step.

## Quick start

```bash
flutter pub get
flutter run -d chrome
```

For Android:

```bash
flutter pub get
flutter run -d android
```

If your local Flutter SDK regenerates platform metadata, run:

```bash
flutter create . --platforms=android,ios,web
```

This keeps `lib/`, `pubspec.yaml`, tests and Firebase files intact while refreshing native wrappers.

## Firebase setup for production

The project includes a placeholder `lib/firebase_options.dart` so the app can compile immediately. Replace it with real Firebase credentials before production:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then copy platform config files if your workflow uses them:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Deploy backend configuration:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

## Required Firebase services

Enable these in Firebase Console:

- Authentication: Email/Password, optionally Google Sign-In.
- Cloud Firestore.
- Cloud Functions.
- Cloud Storage.
- Cloud Messaging if push notifications are enabled.
- Analytics/Crashlytics/Performance for production monitoring.

## Safety notes

Nearo is a real-world social app. Before public launch, keep the included 18+ gate, reporting flow, security rules and server-side match creation. Add manual moderation workflows and abuse monitoring before App Store/Play Store release.

## Validation commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=ENV=production
```
