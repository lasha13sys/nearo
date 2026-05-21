class AppUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final bool isDemo;

  const AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    this.isDemo = false,
  });

  static const demo = AppUser(
    uid: 'demo-user',
    phoneNumber: '+995555000000',
    displayName: 'Demo User',
    isDemo: true,
  );
}
