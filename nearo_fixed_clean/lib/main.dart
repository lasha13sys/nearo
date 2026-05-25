import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/nearo_app.dart';
import 'core/constants/app_config.dart';
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
    if (AppConfig.useFirebaseEmulators) {
      await _connectFirebaseEmulators(AppConfig.firebaseEmulatorHost);
    }
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

Future<void> _connectFirebaseEmulators(String host) async {
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}
