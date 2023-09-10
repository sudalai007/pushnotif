import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pushnotif/main.dart';
import 'package:pushnotif/pages/notification_screen.dart';

class FirebaseApi {
  //
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Create a new AndroidNotificationChannel instance:
  final _androidChannel = const AndroidNotificationChannel(
      'high_importance_channel', 'High Importance Notification',
      description: 'This channel is used for important notification',
      importance: Importance.defaultImportance);

  // Create the channel on the device (if a channel with an id already exists, it will be updated):
  final _localNotification = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    navigatorKey.currentState
        ?.pushNamed(NotificationScreen.route, arguments: message);
  }

  Future initLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(android: android, iOS: iOS);
    await _localNotification.initialize(settings,
        onDidReceiveNotificationResponse: (payload) {
      final message = RemoteMessage.fromMap(jsonDecode(payload as String));
      handleMessage(message);
    });
    final platform = _localNotification.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  Future initPushNotification() async {
    // IOS Enabling foreground notifications is generally a straightforward process.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // Get any messages which caused the application to open from a terminated state.
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // Also handle any interaction when the app is in the background via a Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Android sdk block any foreground message your app is open condition, so use local messaging notification
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      if (notification != null) {
        _localNotification.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@drawable/ic launcher?',
              // other properties...
            ),
          ),
          payload: jsonEncode(message.toMap()),
        );
      }
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();

    // Get the token each time the application loads
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token : $fCMToken');
    initPushNotification();
    initLocalNotifications();
  }
}

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}
