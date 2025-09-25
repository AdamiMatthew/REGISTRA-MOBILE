import 'package:flutter/material.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String title;
  final String body;

  const NotificationDetailScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Title:", style: Theme.of(context).textTheme.titleLarge),
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text("Body:", style: Theme.of(context).textTheme.titleLarge),
            Text(body, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
