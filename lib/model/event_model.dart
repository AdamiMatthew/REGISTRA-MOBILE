class Event {
  final String eventId;
  final String title;
  final String location;
  final String date;
  final String time;
  final String eventType;
  final String about;
  final double price;
  final bool isPastEvent;
  final String hostName;
  final List<double> coordinates;
  final String image;
  final String eventTarget;
  final String status;

  Event({
    required this.eventId,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.eventType,
    required this.about,
    required this.price,
    required this.isPastEvent,
    required this.hostName,
    required this.coordinates,
    required this.image,
    required this.eventTarget,
    required this.status,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['_id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      eventType: json['eventType'] ?? '',
      about: json['about'] ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      isPastEvent: json['isPastEvent'] ?? false,
      hostName: json['hostName'] ?? '',
      coordinates: List<double>.from((json['coordinates'] as List?)?.map((e) => e.toDouble()) ?? [0.0, 0.0]),
      image: json['image'] ?? '',
      eventTarget: json['eventTarget'] ?? '',
      status: json['status'] ?? '',
    );
  }
}