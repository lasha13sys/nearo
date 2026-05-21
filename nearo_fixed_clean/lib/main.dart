import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/nearo_app.dart';
import 'core/providers/app_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    final isPlaceholder = options.apiKey == 'demo-api-key' || options.projectId == 'nearo-demo';
    if (isPlaceholder) {
      throw StateError('Placeholder Firebase options detected.');
    }
    await Firebase.initializeApp(
      options: options,
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(
    ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const NearoApp(),
    ),
  );
}
