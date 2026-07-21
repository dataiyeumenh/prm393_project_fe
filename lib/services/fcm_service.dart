import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> setupFCM() async {
    // 1. Cấu hình cho flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // 2. Request permissions (Required for iOS, recommended for Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('FCM: User granted permission');
      
      // 3. Retrieve FCM Token
      try {
        String? fcmToken = await _firebaseMessaging.getToken();
        print("=== FCM Device Token: $fcmToken ===");
        // TODO: Gửi $fcmToken lên Spring Boot Backend API (vào bảng UserDevice)
      } catch (e) {
        print("FCM: Error fetching token: $e");
      }

      // 4. Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print("FCM: Token refreshed: $newToken");
        // TODO: Cập nhật newToken vào Backend API
      });

      // 5. Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('FCM: Foreground message received: ${message.notification?.title}');
        if (message.notification != null) {
          // Hiển thị popup notification ngay cả khi đang mở app
          _showLocalNotification(message);
        }
      });
    } else {
      print('FCM: User declined or has not accepted permission');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _localNotificationsPlugin.show(
      id: message.notification.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: notificationDetails,
      payload: message.data.toString(),
    );
  }
}

