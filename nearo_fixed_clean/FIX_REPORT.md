# Nearo Fix Report

This cleaned project replaces the broken prototype state with a runnable Flutter/Firebase baseline.

## Fixed blockers

- Replaced invalid relative imports and late imports.
- Removed Riverpod code-generation dependency from runtime code; no `.g.dart` files are required.
- Added missing Firebase bootstrap file: `lib/firebase_options.dart`.
- Added missing Firebase deployment files: `firebase.json`, Firestore rules, Storage rules, indexes, Functions `package.json` and `index.js`.
- Added missing dependencies from the audit: `google_sign_in` and `firebase_performance`.
- Replaced test-only code in production services with production-safe services.
- Rebuilt the app layer around a clean Riverpod auth controller and safe demo fallback.
- Reworked signal/match flow so matches are created server-side by Cloud Functions.
- Hardened Firestore rules for users, signals, matches, conversations, messages, venues and reports.
- Added 18+ signup gate and safety acknowledgement.
- Added Android and web scaffolding plus platform bootstrap scripts.
- Replaced stale tests with a smoke test for the cleaned app.

## Important production step

`lib/firebase_options.dart` contains placeholder values so the app can compile immediately. Before real launch, run:

```bash
flutterfire configure
```

Then deploy backend rules/functions:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

## Validation commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=ENV=production
```
