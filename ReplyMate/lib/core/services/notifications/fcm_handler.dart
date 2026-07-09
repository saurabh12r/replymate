import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../notifications/push_notification.dart';
import '../../notifications/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  
  // Initialize Hive for background isolate
  await Hive.initFlutter();
  
  // Initialize Push Notification service
  await PushNotificationService.init();
  
  // Handle the incoming message
  await PushNotificationHandler.handleMessage(message);
}

class PushNotificationHandler {
  static Future<void> init() async {
    // Request permission (if needed on iOS/Android 13+)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground: ${message.messageId}');
      handleMessage(message);
    });

    // Background listener
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> handleMessage(RemoteMessage message) async {
    final title = message.notification?.title;
    final body = message.notification?.body;
    
    // If it's a silent notification (no title/body in notification and data payloads),
    // do not store it in the user's notification list.
    if (title == null && body == null && message.data['title'] == null && message.data['body'] == null) {
      debugPrint('FCM: Ignoring silent background message');
      return;
    }
    
    // Fallback to data payload if notification is empty
    final finalTitle = title ?? message.data['title'] ?? 'New Notification';
    final finalBody = body ?? message.data['body'] ?? 'You have a new message';
    
    final imageUrl = message.notification?.android?.imageUrl ?? 
                     message.notification?.apple?.imageUrl ?? 
                     message.data['image'];

    final notification = PushNotification(
      id: message.messageId ?? const Uuid().v4(),
      title: finalTitle,
      body: finalBody,
      imageUrl: imageUrl,
      type: message.data['type'],
      payloadData: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
    );

    await PushNotificationService.instance.addNotification(notification);
  }
}
