import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _token = "Fetching FCM token...";
  String _message = "No message received yet.";

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (iOS & Android 13+)
    await messaging.requestPermission();

    // Get FCM token
    String? token = await messaging.getToken();
    setState(() => _token = token ?? "No Token Found");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _message =
            "Title: ${message.notification?.title ?? ''}\nBody: ${message.notification?.body ?? ''}";
      });
    });

    // Handle messages when app is launched from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _navigateToDetail(initialMessage);
    }

    // Handle when the app is opened from the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateToDetail(message);
    });
  }

  void _navigateToDetail(RemoteMessage message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          title: message.notification?.title ?? "No Title",
          body: message.notification?.body ?? "No Body",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("FCM Token:",
                style: Theme.of(context).textTheme.titleLarge),
            SelectableText(_token, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            Text("Latest Message:",
                style: Theme.of(context).textTheme.titleLarge),
            Text(_message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
