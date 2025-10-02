import 'package:final_project/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';
import 'map_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

class DetailScreen extends StatelessWidget {
  final String eventId;
  final String title;
  final String location;
  final String date;
  final String time;
  final String description;
  final double ticketPrice;
  final bool isPastEvent;
  final String hostName;
  final double latitude;
  final double longitude;
  final String userId;
  final String image;
  final String eventTarget;

  const DetailScreen({
    super.key,
    required this.eventId,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.description,
    required this.ticketPrice,
    required this.isPastEvent,
    required this.hostName,
    required this.latitude,
    required this.longitude,
    required this.userId,
    required this.image,
    required this.eventTarget,
  });

  String _formatDate(String dateString) {
    try {
      final DateTime? parsed = DateTime.tryParse(dateString);
      if (parsed != null) {
        return DateFormat('MMMM dd, yyyy').format(parsed);
      }
      return dateString;
    } catch (_) {
      return dateString;
    }
  }

  Future<bool> _checkIfRegistered(String eventId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$registered?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> registeredEvents = json.decode(response.body);
        return registeredEvents.any((event) => event['_id'] == eventId);
      } else {
        //('Failed to fetch registered events: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      //print('Error checking registration: $e');
      return false;
    }
  }

  void _showAlreadyRegisteredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Already Registered"),
          content: const Text("You are already registered for this event. You can find your ticket in the ticket navigation bar."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  

  void _shareToFacebook(BuildContext context) async {
    // Create a shorter, more reliable share text
    final String shareText = "🎉 $title\n📅 ${_formatDate(date)} at $time\n📍 $location\n💰 ₱${ticketPrice.toStringAsFixed(2)}\n🎯 $hostName\n\nJoin us for an incredible experience! 🚀";
    
    // Use the standard Facebook web sharing URL
    final String facebookUrl = "https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://registra.com/event/$eventId')}&quote=${Uri.encodeComponent(shareText)}";
    
    try {
      await launchUrl(Uri.parse(facebookUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar(context, "Could not open Facebook");
    }
  }

  void _shareToTwitter(BuildContext context) async {
    final String shareText = "Check out this amazing event: $title\n\nDate: ${_formatDate(date)}\nTime: $time\nLocation: $location\n\nJoin us for an incredible experience!";
    final String encodedText = Uri.encodeComponent(shareText);
    final String twitterUrl = "https://twitter.com/intent/tweet?text=$encodedText&url=${Uri.encodeComponent('https://registra.com/event/$eventId')}";
    
    if (await canLaunchUrl(Uri.parse(twitterUrl))) {
      await launchUrl(Uri.parse(twitterUrl), mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar(context, "Could not open Twitter");
    }
  }

  

  

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _formatDate(date);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display event image with error handling
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Image.network(
                image,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(child: Text("Image not available")),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.record_voice_over,
                          size: 26, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hostName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_month,
                          size: 26, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(
                            title: title,
                            location: location,
                            date: date,
                            time: time,
                            description: description,
                            ticketPrice: ticketPrice,
                            isPastEvent: isPastEvent,
                            hostName: hostName,
                            eventId: eventId,
                            latitude: latitude,
                            longitude: longitude,
                            image: image,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            size: 28, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 26, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(time,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Share This Event Section
                  const Text("Share This Event",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Facebook Share
                      InkWell(
                        onTap: () => _shareToFacebook(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.facebook, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                             
                            ],
                          ),
                        ),
                      ),
                      // X (Twitter) Share
                      InkWell(
                        onTap: () => _shareToTwitter(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "X",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Overview",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: Colors.grey, width: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/peso.svg',
                width: 15,
                height: 15,
              ),
              Text(
                ticketPrice.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  final isRegistered =
                      await _checkIfRegistered(eventId, userId);
                  if (isRegistered) {
                    _showAlreadyRegisteredDialog(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          eventId: eventId,
                          ticketPrice: ticketPrice,
                          eventName: title,
                          eventDate: date,
                          eventTime: time,
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                   "REGISTER",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
