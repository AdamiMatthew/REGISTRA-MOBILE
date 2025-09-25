/* import 'package:flutter/material.dart';
import 'package:final_project/screens/detail_screen.dart';

class ExtraCurricularActivitiesPostcard extends StatelessWidget {
  final String title;
  final String location;
  final String date;
  final String time;
  final String about;
  final String hostName;
  final bool isPastActivity;
  

  const ExtraCurricularActivitiesPostcard({
    super.key,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.about,
    required this.hostName,

    required this.isPastActivity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(
              title: title,
              location: location,
              date: date,
              time: time,
              description: about,
              ticketPrice: 0.0, // Activities are usually free
              isPastEvent: isPastActivity,
              hostName: hostName,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: 350,
            margin: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text("No Image"),
                        ),
                      ),
                    ),
                    if (isPastActivity)
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
                          color: isPastActivity ? Colors.grey : Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              date.split(" ").length > 1 ? date.split(" ")[0] : date,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              date.split(" ").length > 1 ? date.split(" ")[1] : "",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Activity Details
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPastActivity ? Colors.grey : Colors.black)),
                      const SizedBox(height: 4),
                      Text("Hosted by $hostName",
                          style: TextStyle(
                            fontSize: 13,
                            color: isPastActivity ? Colors.grey[600] : Colors.grey[800],
                          )),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(location,
                              style: TextStyle(
                                  color: isPastActivity ? Colors.grey : Colors.black)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isPastActivity)
            Positioned(
              top: 40,
              left: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Past Activity",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
 */