import 'dart:convert';
import 'dart:typed_data';
import 'package:final_project/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'detail_screen.dart';

class AllMapScreen extends StatefulWidget {
  final String title;
  final String location;
  final String date;
  final String time;
  final String description;
  final double ticketPrice;
  final bool isPastEvent;
  final String hostName;
  final String eventId;
  final double latitude;
  final double longitude;
  final String userId;
  final String image; // Assuming you have an image URL field
  final String eventTarget;

  const AllMapScreen(
      {super.key,
      required this.title,
      required this.location,
      required this.date,
      required this.time,
      required this.description,
      required this.ticketPrice,
      required this.isPastEvent,
      required this.hostName,
      required this.eventId,
      required this.latitude,
      required this.longitude,
      required this.userId,
      required this.image,
      required this.eventTarget});

  @override
  State<AllMapScreen> createState() => _AllMapScreenState();
}

class _AllMapScreenState extends State<AllMapScreen> {
  late MaplibreMapController mapController;
  List<dynamic> events = [];
  List<Map<String, dynamic>> selectedEvents = [];
  Map<String, dynamic> symbolIdToEvent = {};
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _fetchEvents();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.locationWhenInUse.request();
  }

  Future<void> _fetchEvents() async {
    try {
      final response =
          await http.get(Uri.parse(allevents));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            events = data;
          });
          if (_isControllerInitialized) {
            await _addEventMarkers();
          }
        } else {
          // print("Expected a list of events, but got: $data");
        }
      } else {
        // print('Failed to fetch events.');
      }
    } catch (e) {
      // print('Error fetching events: $e');
    }
  }

  Future<void> _onMapCreated(MaplibreMapController controller) async {
    mapController = controller;
    _isControllerInitialized = true;
    await mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 11.0,
        ),
      ),
    );
  }

  Future<void> _addEventMarkers() async {
    try {
      final ByteData bytes =
          await rootBundle.load('assets/images/location-pin.png');
      final Uint8List markerImage = bytes.buffer.asUint8List();
      await mapController.addImage('custom-marker', markerImage);
      for (var event in events) {
        // Skip past events
        if (event['isPastEvent'] == true) {
          continue;
        }
        final coordinates = event['coordinates'];
        if (coordinates != null &&
            coordinates is List &&
            coordinates.length >= 2) {
          final longitude = coordinates[0];
          final latitude = coordinates[1];

          Symbol symbol = await mapController.addSymbol(
            SymbolOptions(
              geometry: LatLng(latitude, longitude),
              iconImage: 'custom-marker',
              iconSize: 0.2,
              iconAnchor: "bottom",
            ),
          );

          symbolIdToEvent[symbol.id] = event;
        }
      }

      mapController.onSymbolTapped.add((symbol) async {
        if (symbolIdToEvent.containsKey(symbol.id)) {
          final selectedEvent = symbolIdToEvent[symbol.id];
          final coordinates = selectedEvent['coordinates'];
          if (coordinates != null &&
              coordinates is List &&
              coordinates.length >= 2) {
            final double longitude = coordinates[0];
            final double latitude = coordinates[1];

            await mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 16.0,
                ),
              ),
            );
          }

          setState(() {
            selectedEvents = [selectedEvent];
          });
        }
      });
    } catch (e) {
      // print("❌ Failed to add event markers: $e");
    }
  }

  String formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      // print("Error formatting date: $e");
      return dateString;
    }
  }

  @override
  void dispose() {
    // Clear listeners and heavy structures to reduce resource usage
    try {
      if (_isControllerInitialized) {
        // Remove any registered callbacks to avoid leaks
        mapController.onSymbolTapped.clear();
        mapController.dispose();
      }
    } catch (_) {}

    // Clear in-memory data
    events = [];
    selectedEvents = [];
    symbolIdToEvent.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: MediaQuery.of(context).size.width,
                  child: MapLibreMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.latitude, widget.longitude),
                      zoom: 13.5,
                    ),
                    styleString:
                        'https://api.maptiler.com/maps/streets-v2/style.json?key=STMkt4wyjqssBgai0hzm',
                    myLocationEnabled: false,
                  ),
                ),
                if (selectedEvents.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: selectedEvents.map((selectedEvent) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                  eventId: selectedEvent['_id'] ?? widget.eventId,
                                  title: selectedEvent['title'] ?? widget.title,
                                  location:
                                      selectedEvent['location'] ?? widget.location,
                                  date: selectedEvent['date'] ?? widget.date,
                                  time: selectedEvent['time'] ?? widget.time,
                                  description: selectedEvent['about'] ??
                                      widget.description,
                                  ticketPrice: (selectedEvent['price'] as num?)
                                          ?.toDouble() ??
                                      widget.ticketPrice,
                                  isPastEvent: selectedEvent['isPastEvent'] ??
                                      widget.isPastEvent,
                                  hostName:
                                      selectedEvent['hostName'] ?? widget.hostName,
                                  latitude: (selectedEvent['coordinates']?[1] as num?)
                                          ?.toDouble() ??
                                      widget.latitude,
                                  longitude:
                                      (selectedEvent['coordinates']?[0] as num?)
                                              ?.toDouble() ??
                                          widget.longitude,
                                  userId: widget.userId,
                                  image: selectedEvent['image'] ?? widget.image,
                                  eventTarget: widget.eventTarget,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 8,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      selectedEvent['image'] ??
                                          'https://www.icpepncr.org/storage/posters/YqcFNpNX8wOxmliHpv1bgcwQ7TLLfJXgd3IdeGbd.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image,
                                              color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formatDate(
                                              selectedEvent['date'] ?? widget.date),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          selectedEvent['title'] ?? widget.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Hosted by ${selectedEvent['hostName'] ?? widget.hostName}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                selectedEvent['location'] ??
                                                    widget.location,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red, size: 28),
                                    onPressed: () async {
                                      setState(() {
                                        selectedEvents.remove(selectedEvent);
                                      });

                                      // Animate the zoom out to level 12 smoothly
                                      await mapController.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            target: LatLng(
                                                widget.latitude, widget.longitude),
                                            zoom:
                                                11.0, // Zoom out to level 12 after closing
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          // Events List Section
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${events.where((event) => event['isPastEvent'] != true).length} events',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Events List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.where((event) => event['isPastEvent'] != true).length,
                      itemBuilder: (context, index) {
                        final availableEvents = events.where((event) => event['isPastEvent'] != true).toList();
                        final event = availableEvents[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () {
                              _selectEventOnMap(event);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      event['image'] ?? 'https://www.icpepncr.org/storage/posters/YqcFNpNX8wOxmliHpv1bgcwQ7TLLfJXgd3IdeGbd.jpg',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image, color: Colors.grey, size: 20),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event['title'] ?? 'Event Title',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatDate(event['date'] ?? ''),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          event['location'] ?? 'Location',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectEventOnMap(Map<String, dynamic> event) async {
    final coordinates = event['coordinates'];
    if (coordinates != null && coordinates is List && coordinates.length >= 2) {
      final double longitude = coordinates[0];
      final double latitude = coordinates[1];

      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 16.0,
          ),
        ),
      );

      setState(() {
        selectedEvents = [event];
      });
    }
  }
}
