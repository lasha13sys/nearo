class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final bool isDemo;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isDemo = false,
  });

  static const demo = AppUser(
    uid: 'demo-user',
    email: 'demo@nearo.app',
    displayName: 'Demo User',
    isDemo: true,
  );
}
