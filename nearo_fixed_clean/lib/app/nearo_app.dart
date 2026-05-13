import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../core/theme/nearo_theme.dart';
import '../presentation/screens/auth/sign_in_screen.dart';
import '../presentation/screens/home/home_screen.dart';

class NearoApp extends ConsumerWidget {
  const NearoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Nearo',
      debugShowCheckedModeBanner: false,
      theme: NearoTheme.darkTheme,
      home: authState.when(
        data: (user) => user == null ? const SignInScreen() : const HomeScreen(),
        loading: () => const _BootstrapScreen(),
        error: (_, __) => const SignInScreen(),
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
