import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging Service — push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Push Notifications: Authorized');
    } else {
      print('⚠️ Push Notifications: Denied');
    }

    // Get FCM token for this device
    final token = await _messaging.getToken();
    print('📱 FCM Token: $token');

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message: ${message.notification?.title}');
      // Handle foreground notification display here
    });

    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Notification tapped: ${message.notification?.title}');
      // Navigate to relevant screen based on message data
    });
  }

  /// Get the FCM device token (for sending targeted push notifications)
  Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic (e.g., "clinic_updates", "emergency_alerts")
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
