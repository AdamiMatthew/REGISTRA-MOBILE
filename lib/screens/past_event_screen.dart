import 'package:final_project/screens/feedbackform_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/config.dart';

class PastEventScreen extends StatefulWidget {
  const PastEventScreen({super.key});

  @override
  State<PastEventScreen> createState() => _PastEventScreenState();
}

class _PastEventScreenState extends State<PastEventScreen> {
  List<dynamic> pastEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPastEvents();
  }

  Future<void> fetchPastEvents() async {
    setState(() => isLoading = true);

    final url = Uri.parse(allevents);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        DateTime now = DateTime.now();
        List<dynamic> past = data.where((event) {
          try {
            String? dateStr = event['date'];
            if (dateStr == null) return false;
            DateTime eventDate = DateTime.parse(dateStr);
            return eventDate.isBefore(now) || (event['isPastEvent'] == true);
          } catch (e) {
            //print("Invalid date format for event: $e");
            return false;
          }
        }).toList();

        setState(() {
          pastEvents = past;
          isLoading = false;
        });
      } else {
        //print("Failed to load events: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      //print("Error fetching events: $e");
      
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Events'),

        // This will pop the current screen and go back to the previous screen.
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pastEvents.isEmpty
              ? const Center(child: Text('No past events found.'))
              : ListView.builder(
                  itemCount: pastEvents.length,
                  itemBuilder: (context, index) {
                    var event = pastEvents[index];
                    String? imageUrl = event['imageUrl'];
                    String? dateStr = event['date'];
                    String? hostName = event['hostName'];

                    String formattedDate = '';
                    if (dateStr != null && dateStr.isNotEmpty) {
                      try {
                        DateTime date = DateTime.parse(dateStr);
                        formattedDate =
                            '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
                      } catch (e) {
                        formattedDate = 'Invalid date';
                      }
                    }

                    return InkWell(
                      onTap: () async {
                        String? eventId = event[
                            '_id']; // Assuming '_id' is the key for eventId
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        String? userId = prefs.getString(
                            '_id'); // Retrieve userId from SharedPreferences
                        
                        if (eventId != null && userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeedbackForm(
                                eventId: eventId,
                                userId: userId,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Unable to load feedback form.')),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                                Icons.broken_image,
                                                size: 30,
                                                color: Colors.grey),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                            Icons.image_not_supported,
                                            size: 30,
                                            color: Colors.grey),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (hostName != null && hostName.isNotEmpty)
                                      Text(
                                        'Hosted by: $hostName',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event['location'] ?? 'No Location',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (formattedDate.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
