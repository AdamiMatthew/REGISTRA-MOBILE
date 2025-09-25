import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:final_project/config.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Track handled notifications to avoid duplicate navigation on hot restart
  static String? _lastHandledMessageId;
  static bool _initialMessageHandled = false;
  static const String _pendingEventStorageKey = 'pending_event_open_payload';

  // Navigator key used in main.dart
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> initNotifications() async {
    // Init local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Ensure iOS shows notifications while app is in foreground
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    // On Android 13+ you must request the POST_NOTIFICATIONS permission for local notifications
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    // Get FCM token
    final fCMToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fCMToken tokengina');

    // Subscribe to per-user topic for targeted notifications (e.g., ticket ready)
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('_id') ?? prefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        final topic = 'user_' + userId;
        await _firebaseMessaging.subscribeToTopic(topic);
        // print('Subscribed to user topic: ' + topic);
      } else {
        // print('No user id found for topic subscription');
      }
    } catch (e) {
      // print('Error subscribing to user topic: ' + e.toString());
    }

    // Foreground push messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        try { print('FCM onMessage data: ' + message.data.toString()); } catch (_) {}
        _showNotification(message);
      }
    });

    // When app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      // try { print('FCM onMessageOpenedApp data: ' + message.data.toString()); } catch (_) {}
      if (message.messageId != null && message.messageId == _lastHandledMessageId) {
        return;
      }
      _lastHandledMessageId = message.messageId;
      await _savePendingEventPayload(message.data);
      await _navigateToScreen(message.data);
    });

    // When app is terminated and opened by tapping a notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && !_initialMessageHandled) {
        _initialMessageHandled = true;
        if (message.messageId != null && message.messageId == _lastHandledMessageId) {
          return;
        }
        _lastHandledMessageId = message.messageId;
        // try { print('FCM getInitialMessage data: ' + message.data.toString()); } catch (_) {}
        _savePendingEventPayload(message.data);
        _navigateToScreen(message.data);
      }
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Try to restore any pending event navigation after hot restart
    try {
      await _restorePendingEventPayloadIfAny();
    } catch (_) {}
  }

  // Foreground notification popup
  Future<void> _showNotification(RemoteMessage message) async {
    String payload = '';
    if (message.data.isNotEmpty) {
      payload = Uri(
        queryParameters: message.data.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      ).query;
    }

    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: payload,
    );
  }

  // Tap on local notification (foreground or scheduled)
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> eventData = Map<String, dynamic>.from(
          Uri.splitQueryString(response.payload!),
        );
        // try { print('Local notification tapped payload: ' + eventData.toString()); } catch (_) {}
        _navigateToScreen(eventData);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Navigate depending on payload
  static Future<void> _navigateToScreen(Map<String, dynamic> eventData) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    try { print('Navigate with eventData: ' + eventData.toString()); } catch (_) {}

    // Fallback: if no payload at all, go to navbar so bottom nav remains
    if (eventData.isEmpty) {
      navigator.pushNamed('/navbar');
      return;
    }

    if (eventData.containsKey("registrationsId")) {
      navigator.pushNamed('/ticket-screen', arguments: eventData);
      return;
    }

    // Normalize payload keys and ensure we have full event details when only eventId is provided
    Map<String, dynamic> args = Map<String, dynamic>.from(eventData);
    // Normalize server payload keys to route expectations
    if (args['description'] == null && args['about'] != null) {
      args['description'] = args['about'];
    }
    if (args['ticketPrice'] == null && args['price'] != null) {
      args['ticketPrice'] = args['price'];
    }
    final String? eventId = (args['eventId'] ?? args['_id'] ?? args['id'] ?? args['event_id'])?.toString();
    if (args['eventId'] == null && eventId != null) {
      args['eventId'] = eventId;
    }
    final bool hasCoreDetails =
        (args['title'] != null && args['title'].toString().isNotEmpty) &&
        (args['location'] != null && args['location'].toString().isNotEmpty) &&
        (args['date'] != null && args['date'].toString().isNotEmpty) &&
        (args['time'] != null && args['time'].toString().isNotEmpty);
    // try { print('Resolved eventId: ' + (eventId ?? 'null') + ', hasCoreDetails=' + hasCoreDetails.toString()); } catch (_) {}
    if (eventId != null && !hasCoreDetails) {
      try {
        // print('Fetching event details for id: ' + eventId);
        final response = await http.get(Uri.parse('$eventDetail/$eventId'));

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = json.decode(response.body) as Map<String, dynamic>;
          // API returns { success: true, event: {...} }
          final Map<String, dynamic> match = (body['event'] is Map<String, dynamic>)
              ? Map<String, dynamic>.from(body['event'] as Map)
              : body;
          // Map API fields to route args expected by DetailScreen
          final dynamic rawPrice = match['price'];
          double price = 0.0;
          if (rawPrice is num) {
            price = rawPrice.toDouble();
          } else if (rawPrice is String) {
            price = double.tryParse(rawPrice) ?? 0.0;
          }

          final String description = (match['about'] ?? match['description'] ?? '')?.toString() ?? '';

          args = {
            'eventId': (match['_id'] ?? match['id'] ?? eventId).toString(),
            'title': match['title'] ?? '',
            'location': match['location'] ?? '',
            'date': match['date'] ?? '',
            'time': match['time'] ?? '',
            'description': description,
            'ticketPrice': price,
            'isPastEvent': match['isPastEvent'] ?? false,
            'hostName': match['hostName'] ?? '',
            'latitude': (match['coordinates'] is List && (match['coordinates'] as List).length >= 2)
                ? ((match['coordinates'][1] as num?)?.toDouble() ?? 0.0)
                : 0.0,
            'longitude': (match['coordinates'] is List && (match['coordinates'] as List).length >= 2)
                ? ((match['coordinates'][0] as num?)?.toDouble() ?? 0.0)
                : 0.0,
            'userId': args['userId'] ?? '',
            'image': match['image'] ?? '',
            'eventTarget': match['eventTarget'] ?? '',
          };
        }

        // Ensure normalized keys are present even if API already had core details
        if (args['description'] == null && args['about'] != null) {
          args['description'] = args['about'];
        }
        if (args['ticketPrice'] == null && args['price'] != null) {
          final dynamic p = args['price'];
          args['ticketPrice'] = (p is num) ? p.toDouble() : (double.tryParse(p.toString()) ?? 0.0);
        }
      } catch (e) {
        // Fallback to whatever we have
        // print('Failed to enrich event payload: $e');
      }
    }

    navigator.pushNamed('/event-detail', arguments: args);
  }

  // Persist last event payload to survive hot restart
  static Future<void> _savePendingEventPayload(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(data.map((k, v) => MapEntry(k, v.toString())));
      await prefs.setString(_pendingEventStorageKey, encoded);
    } catch (_) {}
  }

  // Restore and clear pending payload
  static Future<void> _restorePendingEventPayloadIfAny() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_pendingEventStorageKey);
      if (stored != null && stored.isNotEmpty) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json.decode(stored));
        await prefs.remove(_pendingEventStorageKey);
        // Avoid duplicate handling if we already navigated in this session
        if (!_initialMessageHandled) {
          _initialMessageHandled = true;
          await _navigateToScreen(data);
        }
      }
    } catch (_) {}
  }

  // Show immediate ticket notification
  Future<void> showTicketNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, String> payload,
  }) async {
    try {
      String payloadString = Uri(queryParameters: payload).query;

      final androidDetails = AndroidNotificationDetails(
        'ticket_notifications',
        'Ticket Notifications',
        channelDescription: 'Notifications when tickets are ready',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payloadString,
      );
      
      // print('Ticket notification shown: $title');
    } catch (e) {
      // print('Error showing ticket notification: $e');
    }
  }

  // Schedule or show a ticket/event notification
  Future<void> scheduleEventNotificationWithData({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required Map<String, String> payload,
  }) async {
    try {
      String payloadString = Uri(queryParameters: payload).query;

      final androidDetails = AndroidNotificationDetails(
        'event_reminders',
        'Event Reminders',
        channelDescription: 'Notifications for upcoming events',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payloadString,
      );
    } catch (e) {
      // print('Error scheduling: $e');
      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders',
            'Event Reminders',
            channelDescription: 'Notifications for upcoming events',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: Uri(queryParameters: payload).query,
      );
    }
  }
}

// Background push handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // print('Background message: ${message.messageId}');
}
