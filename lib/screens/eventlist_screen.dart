import 'package:final_project/config.dart';
import 'package:final_project/firebase_Api/firebase_api.dart';
import 'package:final_project/screens/ticket_screen.dart';
import 'package:final_project/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<dynamic> registeredEvents = [];
  bool isLoading = true;
  Set<String> _notifiedTickets = {}; // Track which tickets we've already notified about
  Set<String> _scheduledReminders = {}; // Track which 1-day reminders are scheduled
  String? _currentUserId; // Store current user id for use in build

  @override
  void initState() {
    super.initState();
    fetchRegisteredEvents();
  }

  Future<void> fetchRegisteredEvents() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('_id');

    // Cache for build usage
    _currentUserId = userId;

    if (userId == null) {
      //print("User ID not found.");
      setState(() {
        registeredEvents = [];
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$registered?userId=$userId');
    //print('Fetching registered events from URL: $url');

    try {
      final response = await http.get(url);
      //print('API Response Status: ${response.statusCode}');
      //print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isEmpty) {
          setState(() {
            registeredEvents = [];
            isLoading = false;
          });
          return;
        }

        DateTime now = DateTime.now();
        List<dynamic> upcoming = [];

        for (var event in data) {
          var registration = event['registrations']?.firstWhere(
            (reg) => reg['userId'] == userId,
            orElse: () => null,
          );

          if (registration == null) continue;

          var eventWithRegId = {
            ...event,
            'registrationsId': registration['_id'],
          };

          String? dateStr = event['date'];
          if (dateStr != null) {
            try {
              DateTime eventDate = DateTime.parse(dateStr);
              if (eventDate.isAfter(now)) {
                upcoming.add(eventWithRegId);
              }
            } catch (e) {
              //print("Invalid date format for event: $e");
            }
          }
        }

        setState(() {
          registeredEvents = upcoming;
          isLoading = false;
        });

        // Check for tickets and show notifications
        await _checkForTicketNotifications(upcoming, userId);

        // await prefs.setString('pastEvents', jsonEncode([])); // This line seems incorrect, commented out
      } else {
        //print("Failed to load registered events: ${response.body}");
        setState(() {
          registeredEvents = [];
          isLoading = false;
        });
      }
    } catch (e) {
      //print("Error fetching registered events: $e");
      setState(() {
        registeredEvents = [];
        isLoading = false;
      });
    }
  }

  // Check for tickets and show notifications for new tickets
  Future<void> _checkForTicketNotifications(List<dynamic> events, String userId) async {
    final api = FirebaseApi();
    final prefs = await SharedPreferences.getInstance();
    
    // Load previously notified tickets from storage
    final notifiedTicketsJson = prefs.getString('notified_tickets') ?? '[]';
    final List<dynamic> notifiedTicketsList = jsonDecode(notifiedTicketsJson);
    _notifiedTickets = Set<String>.from(notifiedTicketsList);
    // Load previously scheduled reminders from storage
    final scheduledRemindersJson = prefs.getString('scheduled_reminders') ?? '[]';
    final List<dynamic> scheduledRemindersList = jsonDecode(scheduledRemindersJson);
    _scheduledReminders = Set<String>.from(scheduledRemindersList);
    
    List<String> newNotifiedTickets = [];
    List<String> newScheduledReminders = [];
    
    for (var event in events) {
      var registration = event['registrations']?.firstWhere(
        (reg) => reg['userId'] == userId,
        orElse: () => null,
      );

      if (registration != null) {
        String registrationId = registration['_id'];
        bool hasQRImage = registration['ticketQR'] != null && 
                         registration['ticketQR'].isNotEmpty;
        
        // Only notify if ticket is ready, payment is not rejected, and we haven't notified about this ticket before
        bool isPaymentRejected = registration['paymentStatus']?.toString().toLowerCase() == 'rejected';
        if (hasQRImage && !isPaymentRejected && !_notifiedTickets.contains(registrationId)) {
          String formattedDate = '';
          try {
            DateTime eventDate = DateTime.parse(event['date']);
            formattedDate = DateFormat('MMMM dd, yyyy').format(eventDate);
          } catch (e) {
            formattedDate = event['date'];
          }

          await api.showTicketNotification(
            id: registrationId.hashCode,
            title: "🎟 Ticket Available!",
            body: "Your ticket for ${event['title']} on $formattedDate is ready!",
            payload: {
              "title": event['title'] ?? '',
              "location": event['location'] ?? '',
              "eventDate": event['date'] ?? '',
              "eventTime": event['time'] ?? '',
              "registrationsId": registrationId,
              "image": event['image'] ?? '',
            },
          );

          // Mark this ticket as notified
          _notifiedTickets.add(registrationId);
          newNotifiedTickets.add(registrationId);
          //print('Notified user about ticket for: ${event['title']}');
        }

        // Schedule 1-day-before reminder if not already scheduled and payment is not rejected
        if (hasQRImage && !isPaymentRejected && !_scheduledReminders.contains(registrationId)) {
          try {
            final DateTime eventDate = DateTime.parse(event['date']);
            final DateTime eventDateTime = _combineDateAndTime(eventDate, event['time']?.toString() ?? '');
            final DateTime reminderTime = eventDateTime.subtract(const Duration(days: 1));

            if (reminderTime.isAfter(DateTime.now())) {
              await api.scheduleEventNotificationWithData(
                id: registrationId.hashCode ^ 0x1DA, // derive a different id
                title: "Reminder: ${event['title']} is tomorrow",
                body: "Happening at ${event['location']} on ${DateFormat('MMMM dd, yyyy').format(eventDate)} at ${event['time']}",
                scheduledDate: reminderTime,
                payload: {
                  "title": event['title'] ?? '',
                  "location": event['location'] ?? '',
                  "eventDate": event['date'] ?? '',
                  "eventTime": event['time'] ?? '',
                  "registrationsId": registrationId,
                  "image": event['image'] ?? '',
                },
              );

              _scheduledReminders.add(registrationId);
              newScheduledReminders.add(registrationId);
              //print('Scheduled 1-day reminder for: ${event['title']} at ' + reminderTime.toIso8601String());
            } else {
              //print('Skip scheduling reminder (time passed) for: ${event['title']}');
            }
          } catch (e) {
            //print('Failed to schedule 1-day reminder: $e');
          }
        }
      }
    }
    
    // Save updated notification state
    if (newNotifiedTickets.isNotEmpty) {
      await prefs.setString('notified_tickets', jsonEncode(_notifiedTickets.toList()));
    }
    if (newScheduledReminders.isNotEmpty) {
      await prefs.setString('scheduled_reminders', jsonEncode(_scheduledReminders.toList()));
    }
    
    // Clean up notifications for past events
    await _cleanupOldNotifications(events, userId);
  }

  // Combine a DateTime date part and a time string like "4:30 PM"
  DateTime _combineDateAndTime(DateTime date, String timeStr) {
    if (timeStr.isEmpty || !timeStr.contains(':')) {
      return DateTime(date.year, date.month, date.day, 9, 0); // default 9:00 AM
    }
    try {
      // Expect formats like "4:30 PM" or "04:05 AM"
      final parts = timeStr.split(' ');
      final hm = parts[0].split(':');
      int hour = int.tryParse(hm[0]) ?? 9;
      int minute = (hm.length > 1) ? int.tryParse(hm[1]) ?? 0 : 0;
      final suffix = (parts.length > 1) ? parts[1].toUpperCase() : '';
      if (suffix == 'PM' && hour < 12) hour += 12;
      if (suffix == 'AM' && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
  }
  
  // Clean up notifications for past events to keep storage clean
  Future<void> _cleanupOldNotifications(List<dynamic> events, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get all current event registration IDs
    Set<String> currentRegistrationIds = {};
    for (var event in events) {
      var registration = event['registrations']?.firstWhere(
        (reg) => reg['userId'] == userId,
        orElse: () => null,
      );
      if (registration != null) {
        currentRegistrationIds.add(registration['_id']);
      }
    }
    
    // Remove notifications for events that are no longer in the upcoming list
    _notifiedTickets.removeWhere((registrationId) => !currentRegistrationIds.contains(registrationId));
    
    // Save cleaned up notification state
    await prefs.setString('notified_tickets', jsonEncode(_notifiedTickets.toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Registered Events",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white), // Set back button color to white
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align column children to start
              children: [
                // Note below the title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align everything to the left
                    children: [
                      const Text(
                        "Status Indicators:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusIndicator(
                        color: const Color(0xFF4682B4),
                        borderColor: const Color(0xFFDC143C),
                        text: 'QR Ready',
                      ),
                      const SizedBox(height: 8), // Space between the two rows
                      _buildStatusIndicator(
                        color: const Color(0xFFDC143C),
                        borderColor: Colors.black,
                        text: 'Pending QR ',
                      ),
                    ],
                  ),
                ),
                // List of registered events
                registeredEvents.isEmpty
                    ? const Expanded(
                        child: Center(
                          child: Text(
                            "No upcoming registered events",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Add padding to the list
                          itemCount: registeredEvents.length,
                          itemBuilder: (context, index) {
                            var event = registeredEvents[index];
                            String? image = event['image'];
                            String? dateStr = event['date'];
                            String? hostName = event['hostName'];

                            // Find the registration where the user is registered
                            var registration = event['registrations']?.firstWhere(
                              (reg) => reg['userId'] == _currentUserId,
                              orElse: () => null,
                            );

                            // Check if the registration has a ticketQR and payment is not rejected
                            bool hasQRImage = registration != null &&
                                registration['ticketQR'] != null &&
                                registration['ticketQR'].isNotEmpty &&
                                registration['paymentStatus']?.toString().toLowerCase() != 'rejected';

                            // Check if payment is rejected
                            bool isPaymentRejected = registration != null &&
                                (registration['paymentStatus']?.toString().toLowerCase() == 'rejected');

                            // Format the event date
                            String formattedDate = '';
                            if (dateStr != null && dateStr.isNotEmpty) {
                              try {
                                DateTime eventDate = DateTime.parse(dateStr);
                                formattedDate =
                                    DateFormat('MMMM dd, yyyy').format(eventDate); // Improved date format
                              } catch (e) {
                                formattedDate = 'Invalid date';
                              }
                            }

                           // ...existing code...
return GestureDetector(
  onTap: () {
    // If ticket QR exists, allow navigation regardless of previous status
    if (hasQRImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketScreen(
            title: event['title'] ?? 'No Title',
            location: event['location'] ?? 'No Location',
            ticketQR: registration?['ticketQR'] ?? '',
            registrationsId: registration?['_id'] ?? '',
            image: event['image'] ?? '',
            eventDate: event['date'] ?? '',
            eventTime: event['time'] ?? '',
          ),
        ),
      );
      return;
    }
    // Handle payment rejected with option to resend
    if (isPaymentRejected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Rejected'),
          content: const Text(
              'Your payment was rejected by the admin. You can resend your receipt for review.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      eventId: event['_id']?.toString() ?? '',
                      ticketPrice: (event['price'] as num?)?.toDouble() ?? 0.0,
                      eventName: event['title']?.toString() ?? 'Event',
                      eventDate: event['date']?.toString() ?? '',
                      eventTime: event['time']?.toString() ?? '',
                      registrationId: registration?['_id']?.toString(),
                    ),
                  ),
                ).then((_) {
                  fetchRegisteredEvents();
                });
              },
              child: const Text('Resend Receipt'),
            ),
          ],
        ),
      );
      return;
    }
    // Only allow navigation if not admin rejected
    if (registration == null || registration['status'] != 'rejected') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketScreen(
            title: event['title'] ?? 'No Title',
            location: event['location'] ?? 'No Location',
            ticketQR: hasQRImage ? registration['ticketQR'] : '',
            registrationsId: registration?['_id'] ?? '',
            image: event['image'] ?? '',
            eventDate: event['date'] ?? '',
            eventTime: event['time'] ?? '',
          ),
        ),
      );
    }
  },
  child: Card(
    // ---- Card Color Logic ----
    color: registration != null && registration['status'] == 'rejected'
        ? Colors.grey[600] // Gray if rejected
        : hasQRImage
            ? const Color(0xFF4682B4) // Blue if has QR
            : const Color(0xFFDC143C), // Red if no QR
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image != null && image.isNotEmpty
                ? Image.network(
                    image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image,
                            size: 30, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported,
                        size: 30, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (hostName != null && hostName.isNotEmpty)
                  Text(
                    'Hosted by: $hostName',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 15, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event['location'] ?? 'No Location',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (formattedDate.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          size: 15, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                // --- Show "Admin Rejected" label if rejected ---
                if (registration != null &&
                    registration['status'] == 'rejected')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Rejected (Reviewed by Admin)",
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                // --- Show "Payment Rejected" label if payment is rejected ---
                if (isPaymentRejected)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Payment Rejected",
                            style: TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  eventId: event['_id']?.toString() ?? '',
                                  ticketPrice: (event['price'] as num?)?.toDouble() ?? 0.0,
                                  eventName: event['title']?.toString() ?? 'Event',
                                  eventDate: event['date']?.toString() ?? '',
                                  eventTime: event['time']?.toString() ?? '',
                                  registrationId: registration?['_id']?.toString(),
                                ),
                              ),
                            ).then((_) {
                              fetchRegisteredEvents();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Resend Receipt',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

// ...existing code...
                          },
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildStatusIndicator({required Color color, required Color borderColor, required String text}) {
    return Row(
      children: [
        Container(
          width: 14, // Slightly larger circle
          height: 14, // Slightly larger circle
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 1.5, // Thicker border
            ),
          ),
        ),
        const SizedBox(width: 10), // Increased space
        Text(
          text,
          style: const TextStyle(
            fontSize: 15, // Slightly larger font
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
