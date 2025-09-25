
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
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
  final String image;

  const MapScreen({
    super.key,
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
    required this.image,

  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MaplibreMapController mapController;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.locationWhenInUse.request();
  }

  void _onMapCreated(MaplibreMapController controller) async {
  mapController = controller;
  _isControllerInitialized = true;
  //print("✅ Map created successfully");

  await mapController.moveCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(widget.latitude, widget.longitude),
        zoom: 13.0,
      ),
    ),
  );

  await addCustomMarker(); // Call the custom marker function
}


Future<void> addCustomMarker() async {
  try {
    
    final ByteData bytes = await rootBundle.load('assets/images/location-pin.png');
    final Uint8List markerImage = bytes.buffer.asUint8List();

    await mapController.addImage('custom-marker', markerImage);

    await mapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(widget.latitude, widget.longitude),
        iconImage: 'custom-marker',
        iconSize: 0.2,
        iconAnchor: "bottom",
      ),
    );

    //print("📍 Custom marker placed at: Latitude: ${widget.latitude}, Longitude: ${widget.longitude}");
  } catch (e) {
    //print("❌ Failed to add custom marker: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: MapLibreMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 13.5, // Temporary zoom before adjusting in _onMapCreated
              ),
              styleString: 'https://api.maptiler.com/maps/streets-v2/style.json?key=STMkt4wyjqssBgai0hzm',
              myLocationEnabled: false,
            ),
          ),

          // Event Info Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
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
              widget.image,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
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
                            widget.date,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hosted by ${widget.hostName}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
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
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      if (_isControllerInitialized) {
        mapController.dispose();
      }
    } catch (_) {}
    super.dispose();
  }
}
