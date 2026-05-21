import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../core/theme/nearo_theme.dart';
import '../presentation/screens/auth/onboarding_screen.dart';
import '../presentation/screens/auth/phone_auth_screen.dart';
import '../presentation/screens/home/home_screen.dart';

class NearoApp extends ConsumerStatefulWidget {
  const NearoApp({super.key});

  @override
  ConsumerState<NearoApp> createState() => _NearoAppState();
}

class _NearoAppState extends ConsumerState<NearoApp> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      final token = await ref.read(notificationServiceProvider).requestAndGetToken();
      final user = ref.read(authControllerProvider).valueOrNull;
      if (token != null && user != null) {
        await ref.read(userRepositoryProvider).updateFcmToken(uid: user.uid, token: token);
      }
    } catch (_) {
      // Push permissions are non-blocking for the core Nearo flow.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Nearo',
      debugShowCheckedModeBanner: false,
      theme: NearoTheme.darkTheme,
      home: authState.when(
        data: (user) {
          if (user == null) return const PhoneAuthScreen();
          final profile = ref.watch(currentUserProfileProvider);
          return profile.when(
            data: (item) => item == null || !item.isOnboarded
                ? OnboardingScreen(appUser: user)
                : const HomeScreen(),
            loading: () => const _BootstrapScreen(),
            error: (_, __) => OnboardingScreen(appUser: user),
          );
        },
        loading: () => const _BootstrapScreen(),
        error: (_, __) => const PhoneAuthScreen(),
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
