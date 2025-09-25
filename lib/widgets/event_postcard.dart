import 'package:final_project/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventPostcard extends StatefulWidget {
  final String title;
  final String location;
  final String date;
  final String time;
  final String about;
  final double price;
  final bool isPastEvent;
  final String hostName;
  final String eventId;
  final double latitude;
  final double longitude;
  final String userId;
  final String image;
  final String eventTarget;
  final bool isRegistered;
  final String eventType;

  const EventPostcard({
    super.key,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.about,
    required this.price,
    required this.isPastEvent,
    required this.hostName,
    required this.eventId,
    required this.latitude,
    required this.longitude,
    required this.userId,
    required this.image,
    required this.eventTarget,
    this.isRegistered = false,
    required this.eventType,
  });

  @override
  State<EventPostcard> createState() => _EventPostcardState();
}

class _EventPostcardState extends State<EventPostcard> {
  @override
  Widget build(BuildContext context) {
    DateTime parseDate = DateTime.parse(widget.date);
    String formattedDate = DateFormat('MMMM dd, yyyy').format(parseDate);

    return GestureDetector(
     onTap: () {
    Navigator.pushNamed(
      context,
      '/event-detail',
      arguments: {
        'eventId': widget.eventId,
        'title': widget.title,
        'location': widget.location,
        'date': widget.date, // Use raw date string for consistency
        'time': widget.time,
        'description': widget.about,
        'ticketPrice': widget.price.toString(),
        'isPastEvent': widget.isPastEvent.toString(),
        'hostName': widget.hostName,
        'latitude': widget.latitude.toString(),
        'longitude': widget.longitude.toString(),
        'userId': widget.userId,
        'image': widget.image,
        'eventTarget': widget.eventTarget,
      },
    );
  },
      child: Stack(
        children: [
          Container(
            width: 400,
            margin: const EdgeInsets.only(right: 12.0, left: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        widget.image,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Center(child: Text("Image not available")),
                          );
                        },
                      ),
                    ),
                    if (widget.isRegistered)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: widget.isRegistered ? Colors.grey : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.eventType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isRegistered ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Hosted by ${widget.hostName}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isRegistered ? Colors.grey[600] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.isRegistered ? Colors.grey : Colors.black,
                              ),
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
          if (widget.isRegistered)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Already Registered",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
