import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'user_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> initializeForUser({
    required String uid,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await UserService.saveFcmToken(uid: uid, token: token);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'New alert';
      final body = message.notification?.body ?? '';
      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((_) {});
  }
}
