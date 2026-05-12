import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../config/env_config.dart';
import '../services/firebase_service.dart';
import '../../shared/models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handled silently
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'fresh_basket_channel';
  static const _channelName = 'FreshBasket Notifications';

  /// Set this from the app root once the router is ready.
  static GoRouter? router;

  // Internal stream — emits route strings when a notification is tapped.
  static final _navController = StreamController<String>.broadcast();
  static Stream<String> get navigationStream => _navController.stream;

  static Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Local notifications setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      // Foreground local notification tap
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _navigate(payload);
        }
      },
    );

    // Create notification channel (Android)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from background by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = _routeFromMessage(message);
      _navigate(route);
    });

    // App launched from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final route = _routeFromMessage(initial);
      // Small delay so router is ready
      Future.delayed(const Duration(milliseconds: 500), () => _navigate(route));
    }
  }

  /// Derives a GoRouter path from FCM message data.
  static String _routeFromMessage(RemoteMessage message) {
    final data = message.data;
    final orderId = data['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      return '/order/$orderId';
    }
    return '/profile/notifications';
  }

  /// Navigates using the static [router] reference if set, otherwise pushes
  /// the route to [navigationStream] so the app root can handle it.
  static void _navigate(String route) {
    if (router != null) {
      router!.push(route);
    } else {
      _navController.add(route);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Build a payload route string so tapping navigates correctly
    final payload = _routeFromMessage(message);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  static Future<String?> getFcmToken() => _messaging.getToken();

  static Future<void> updateFcmToken(String uid) async {
    final token = await getFcmToken();
    if (token != null) {
      await FirebaseService.users.doc(uid).update({'fcmToken': token});
    }
  }

  static Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    await FirebaseService.notifications.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── FCM v1 push (service-account JWT auth) ──────────────────────────────

  /// Cached OAuth2 access token + its expiry so we don't fetch a new one
  /// for every message.
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  /// Returns a valid OAuth2 Bearer token for the FCM v1 API.
  /// Uses a self-signed JWT (service account credentials in .env).
  static Future<String?> _getFcmAccessToken() async {
    final clientEmail = EnvConfig.fcmClientEmail;
    final privateKey  = EnvConfig.fcmPrivateKey;
    if (clientEmail.isEmpty || privateKey.isEmpty) return null;

    // Reuse cached token if it hasn't expired (with 60-s safety margin)
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(seconds: 60)))) {
      return _accessToken;
    }

    try {
      final now = DateTime.now();
      final jwt = JWT(
        {
          'iss': clientEmail,
          'sub': clientEmail,
          'aud': 'https://oauth2.googleapis.com/token',
          'iat': now.millisecondsSinceEpoch ~/ 1000,
          'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        },
      );

      final token = jwt.sign(
        RSAPrivateKey(privateKey),
        algorithm: JWTAlgorithm.RS256,
      );

      final response = await Dio().post(
        'https://oauth2.googleapis.com/token',
        data: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      _accessToken = response.data['access_token'] as String?;
      final expiresIn = (response.data['expires_in'] as num?)?.toInt() ?? 3600;
      _tokenExpiry = now.add(Duration(seconds: expiresIn));
      return _accessToken;
    } catch (e) {
      debugPrint('[FCM] Token fetch failed: $e');
      return null;
    }
  }

  /// Sends an FCM push notification to a specific user via the FCM v1 API.
  /// Looks up the user's device token from Firestore, then calls
  /// https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
  static Future<void> sendFcmPush({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final projectId = EnvConfig.fcmProjectId;
      if (projectId.isEmpty) return; // not configured yet

      // Get the target user's FCM device token
      final userDoc = await FirebaseService.users.doc(userId).get();
      final deviceToken = userDoc.data()?['fcmToken'] as String?;
      if (deviceToken == null || deviceToken.isEmpty) return;

      // Get a valid OAuth2 Bearer token
      final accessToken = await _getFcmAccessToken();
      if (accessToken == null) return;

      await Dio().post(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        data: {
          'message': {
            'token': deviceToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'HIGH',
              'notification': {'sound': 'default'},
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'badge': 1},
              },
            },
            'data': (data ?? {}).map((k, v) => MapEntry(k, v.toString())),
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Never let a push failure crash the order flow
      debugPrint('[FCM] Push failed for $userId: $e');
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    await FirebaseService.notifications
        .doc(notificationId)
        .update({'isRead': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseService.firestore.batch();
    final unread = await FirebaseService.notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Stream<List<NotificationModel>> notificationsStream(String userId) {
    return FirebaseService.notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => NotificationModel.fromFirestore(d))
            .toList());
  }

  static Stream<int> unreadCountStream(String userId) {
    return FirebaseService.notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
