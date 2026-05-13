import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final bool firebaseReady;

  NotificationService({required this.firebaseReady});

  Future<String?> requestAndGetToken() async {
    if (!firebaseReady) return null;
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    return messaging.getToken();
  }
}
