import 'package:final_project/screens/detail_screen.dart';
import 'package:flutter/material.dart';

class EventListPostcard extends StatelessWidget {
  final String date;
  final String time;
  final String title;
  final String location;
  final String image;
  final String description;
  final double ticketPrice;
  final bool isPastEvent;
  final String hostName;
  final String eventId;
  final double latitude;
  final double longitude;
  final String userId; // Add userId parameter
  final String eventTarget;

  const EventListPostcard({
    super.key,
    required this.date,
    required this.time,
    required this.title,
    required this.location,
    required this.image,
    required this.description,
    required this.ticketPrice,
    required this.isPastEvent,
    required this.hostName,
    required this.eventId,
    required this.latitude,
    required this.longitude,
    required this.userId, // Add userId parameter
    required this.eventTarget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              eventId: eventId,
              title: title,
              location: location,
              date: date,
              time: time,
              description: description,
              ticketPrice: ticketPrice,
              isPastEvent: isPastEvent,
              hostName: hostName,
              latitude: latitude,
              longitude: longitude,
              userId: userId, // Pass userId to DetailScreen
              image: image, // Pass image URL to DetailScreen
              eventTarget: eventTarget,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$date • $time',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
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
  }
}