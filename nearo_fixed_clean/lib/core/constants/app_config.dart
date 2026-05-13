class AppConfig {
  const AppConfig._();

  static const String appName = 'Nearo';
  static const String appVersion = '1.0.0';
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: false,
  );

  static const int maxSignalsPerHour = int.fromEnvironment(
    'MAX_SIGNALS_PER_HOUR',
    defaultValue: 10,
  );

  static const String proximityHashSalt = String.fromEnvironment(
    'PROXIMITY_HASH_SALT',
    defaultValue: 'nearo-local-development-salt',
  );

  static bool get isProduction => environment == 'production';
}
