import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/event_postcard.dart';
import '../model/event_model.dart';
import '../config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../firebase_Api/firebase_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Event> upcomingEvents = [];
  List<Event> extraCurricularEvents = [];
  List<Event> todayEvents = [];
  List<Event> registeredEvents = [];
  bool isLoading = true;
  String? userId;
  String? userType;
  String? membership;
  String selectedEventType = 'All event types';
  String selectedLocation = 'All locations';
  DateTime? selectedDate;
  TextEditingController dateController = TextEditingController();
  List<String> registeredEventIds = [];

  bool _locationPermissionGranted = false;
  String _currentCity = "";
  String _currentCountry = "";
  bool _isGettingLocation = true;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _determineSplashBehavior();
  }

  Future<void> _determineSplashBehavior() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenHomeSplash') ?? false;
    if (!hasSeen) {
      await _showHomeSplash();
      await prefs.setBool('hasSeenHomeSplash', true);
    } else {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
      // Load data immediately without showing splash
      _initializeData();
    }
  }

  Future<void> _showHomeSplash() async {
    // Show splash for 3 seconds ONLY on first login/first visit
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
      // Start loading data after splash
      _initializeData();
    }
  }

  Widget _buildHomeSplash() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
  'assets/images/icpeplogolatest.svg',
  width: 160,
  height: 160,
  fit: BoxFit.contain,
),
          const SizedBox(height: 20),
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Loading your events...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeData() async {
    await fetchUserId();
    //print('DEBUG: _initializeData - userId after fetchUserId: $userId');
    await fetchMembership();
    await fetchuserType();
    await fetchEvents();
    await _checkAndGetLocation();
    setState(() {}); // Rebuild UI after all data is fetched
  }

  Future<void> fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('_id');
    //print("DEBUG: fetchUserId - User ID: $userId");
    // Removed setState here as it's now handled by _initializeData
  }

  Future<void> fetchuserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userType = prefs.getString('userType');
    //print("DEBUG: fetchuserType - User Type: $userType");
    // Removed setState here as it's now handled by _initializeData
  }

  Future<void> fetchMembership() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    membership = prefs.getString('membership');
    //print("DEBUG: fetchMembership - Membership: $membership");
    // Removed setState here as it's now handled by _initializeData
  }

  void checkTodayEvents(List<Event> allEvents) {
    final today = DateTime.now();
    todayEvents = allEvents.where((event) {
      DateTime eventDate = DateTime.parse(event.date);
      return eventDate.year == today.year &&
          eventDate.month == today.month &&
          eventDate.day == today.day;
    }).toList();
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Schedule notifications for events that are 1 day away
  Future<void> scheduleEventNotifications(List<Event> allEvents) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    // Find events that are exactly 1 day away (tomorrow)
    final eventsOneDayAway = allEvents.where((event) {
      DateTime eventDate = DateTime.parse(event.date);
      return eventDate.year == tomorrow.year &&
          eventDate.month == tomorrow.month &&
          eventDate.day == tomorrow.day &&
          !event.isPastEvent;
    }).toList();

    //print('DEBUG: Found ${eventsOneDayAway.length} events happening tomorrow');

    // Schedule notifications for each event
    for (Event event in eventsOneDayAway) {
      // Create a unique ID for the notification based on event ID
      int notificationId = event.eventId.hashCode;
      
      // Schedule notification for 9:00 AM TODAY (to remind about tomorrow's event)
      DateTime notificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        9, // 9:00 AM today
      );

      // If it's already past 9:00 AM today, schedule for 9:00 AM tomorrow
      if (now.hour >= 9) {
        notificationTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          9, // 9:00 AM tomorrow
        );
      }

      // Create payload with event data for navigation
      final Map<String, String> eventData = {
       'eventId': event.eventId,
  'title': event.title,
  'location': event.location,
  'date': event.date,
  'time': event.time,
  'description': event.about,
  'ticketPrice': event.price.toString(),
  'isPastEvent': event.isPastEvent.toString(),
  'hostName': event.hostName,
  'latitude': event.coordinates[1].toString(),
  'longitude': event.coordinates[0].toString(),
  'userId': userId ?? '',
  'image': event.image,
  'eventTarget': event.eventTarget,
      };

      await FirebaseApi().scheduleEventNotificationWithData(
        id: notificationId,
        title: 'Event Tomorrow!',
        body: '${event.title} is happening tomorrow at ${event.time} in ${event.location}',
        scheduledDate: notificationTime,
        payload: eventData,
      );

      //print('DEBUG: Scheduled notification for tomorrow\'s event: ${event.title} at ${notificationTime}');
    }
  }

  Future<void> fetchRegisteredEvents() async {
    //print('DEBUG: fetchRegisteredEvents - userId before API call: $userId');
    if (userId != null && userId!.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$registered?userId=$userId'),
        );
        if (response.statusCode == 200) {
          final List<dynamic> registeredEventsData = json.decode(response.body);
          //print('DEBUG: Raw registered events data: $registeredEventsData');
          registeredEventIds = registeredEventsData.map((e) => e['_id'].toString()).toList();
          //print('DEBUG: fetchRegisteredEvents - registeredEventIds updated to: $registeredEventIds');
        }
      } catch (e) {
        //print('Error fetching registered events: $e');
      }
    }
  }

  Future<void> fetchEvents() async {
    await fetchRegisteredEvents();

    setState(() {
      isLoading = true;
    });

    String url = allevents;
    List<String> queryParams = [];

    if (selectedEventType != 'All event types') {
      queryParams.add('type=$selectedEventType');
    }

    if (selectedDate != null) {
      queryParams.add('date=${selectedDate!.toIso8601String()}');
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    //print('Fetching events from URL: $url');
    //print('User Type: $userType');
    //print('Membership: $membership');

    try {
      final response = await http.get(Uri.parse(url));
      //print('API Response Status: ${response.statusCode}');
      //print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        //print('Decoded Data (raw from API): $data');
        final allEvents = data.map((e) => Event.fromJson(e)).toList();
        //print('Parsed Events (after mapping): ${allEvents.length}');

        // Populate registeredEvents immediately from allEvents
        registeredEvents = allEvents
            .where((event) => registeredEventIds.contains(event.eventId))
            .toList();
        //print('Registered Events list size (after initial population): ${registeredEvents.length}');

        List<Event> filteredEvents = allEvents;

        // Apply location filtering
        if (selectedLocation != 'All locations') {
          filteredEvents = filteredEvents.where((event) =>
              event.location.toLowerCase().contains(selectedLocation.toLowerCase())).toList();
        }
         //print('Filtered Events (after location filter): ${filteredEvents.length}');

        // Filter events based on userType
        if (userType?.toLowerCase() == "student") {
          filteredEvents = filteredEvents
              .where((e) => e.eventTarget?.toLowerCase() == "student" || e.eventTarget?.toLowerCase() == "both")
              .toList();
        } else if (userType?.toLowerCase() == "professional") {
          filteredEvents = filteredEvents
              .where((e) => e.eventTarget?.toLowerCase() == "professional" || e.eventTarget?.toLowerCase() == "both")
              .toList();
        } else if (userType?.toLowerCase() == "admin") {
          filteredEvents = filteredEvents
              .where((e) => e.eventTarget?.toLowerCase() == "admin" || e.eventTarget?.toLowerCase() == "both")
              .toList();
        }

        // Filter out cancelled events
        filteredEvents = filteredEvents
            .where((e) => e.status?.toLowerCase() != "cancelled")
            .toList();
         //print('Filtered Events (after userType filter): ${filteredEvents.length}');

        // Additional filtering for non-members
        if (membership?.toLowerCase() == "non-member") {
          filteredEvents = filteredEvents
              .where((e) => e.eventTarget?.toLowerCase() != "admin")
              .toList();
        }
         //print('Filtered Events (after membership filter): ${filteredEvents.length}');

        // Increase prices by 10% for non-members
        if (membership?.toLowerCase() == "non-member") {
          filteredEvents = filteredEvents.map((event) {
            return Event(
              eventId: event.eventId,
              title: event.title,
              location: event.location,
              date: event.date,
              time: event.time,
              eventType: event.eventType,
              about: event.about,
              price: event.price * 1.1,
              isPastEvent: event.isPastEvent,
              hostName: event.hostName,
              coordinates: event.coordinates,
              image: event.image,
              eventTarget: event.eventTarget,
              status: event.status,
            );
          }).toList();
        }
         //print('Filtered Events (after price adjustment for non-members): ${filteredEvents.length}');

        setState(() {
          if (selectedDate != null) {
            final selectedDateOnly = DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
            );

            upcomingEvents = filteredEvents
                .where((e) =>
                    (e.eventType == "Seminar" ||
                        e.eventType == "Workshop" ||
                        e.eventType == "Webinar") &&
                    !e.isPastEvent &&
                    _isSameDate(DateTime.parse(e.date), selectedDateOnly))
                .toList();

            extraCurricularEvents = filteredEvents
                .where((e) =>
                    e.eventType == "Activity" &&
                    !e.isPastEvent &&
                    _isSameDate(DateTime.parse(e.date), selectedDateOnly))
                .toList();
          } else {
            upcomingEvents = filteredEvents
                .where((e) =>
                    (e.eventType == "Seminar" ||
                        e.eventType == "Workshop" ||
                        e.eventType == "Webinar") &&
                    !e.isPastEvent)
                .toList();

            extraCurricularEvents = filteredEvents
                .where((e) => e.eventType == "Activity" && !e.isPastEvent)
                .toList();
          }

          //print('DEBUG: fetchEvents - Upcoming Events list size: ${upcomingEvents.length}');
          //print('DEBUG: fetchEvents - Extra Curricular Events list size: ${extraCurricularEvents.length}');
          //print('DEBUG: fetchEvents - Registered Events list size: ${registeredEvents.length}');
          //print('DEBUG: fetchEvents - Current registeredEventIds before final setState: $registeredEventIds');

          checkTodayEvents([...upcomingEvents, ...extraCurricularEvents]);
          isLoading = false;
        });
        
        // Schedule notifications for events 1 day away (outside setState)
        await scheduleEventNotifications(allEvents);
      } else {
        setState(() {
          isLoading = false;
        });
        //print('Error fetching events: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      //print('Error fetching events: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('MMMM dd, yyyy').format(selectedDate!);
      });
      fetchEvents();
    }
  }

  Future<void> _checkAndGetLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionGranted = false;
        _currentCity = "";
        _currentCountry = "";
        _isGettingLocation = false;
      });
      //print("Location permission denied or denied forever.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _locationPermissionGranted = true;
          _currentCity = place.locality ?? "Unknown City";
          _currentCountry = place.country ?? "Unknown Country";
          _isGettingLocation = false;
        });
        //print("Location fetched: $_currentCity, $_currentCountry");
      } else {
        setState(() {
          _locationPermissionGranted = true;
          _currentCity = "Unknown Location";
          _currentCountry = "";
          _isGettingLocation = false;
        });
        //print("Could not find placemark for location.");
      }
    } catch (e) {
      setState(() {
        _locationPermissionGranted = true;
        _currentCity = "Error Getting Location";
        _currentCountry = "";
        _isGettingLocation = false;
      });
      //print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    //print('DEBUG: build method called. current registeredEventIds: $registeredEventIds');
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_locationPermissionGranted)
              const Icon(Icons.location_on, color: Colors.white),
            if (_locationPermissionGranted)
              const SizedBox(width: 8),
            if (_isGettingLocation)
              const SizedBox(
                 width: 20,
                 height: 20,
                 child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            else if (_locationPermissionGranted && _currentCity.isNotEmpty)
               Text(
                 "$_currentCity, $_currentCountry",
                 style: const TextStyle(
                   fontSize: 16,
                   color: Colors.white,
                   fontWeight: FontWeight.bold,
                 ),
               )
             else
               const SizedBox.shrink(),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _showSplash ? _buildHomeSplash() : isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (todayEvents.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.event_available, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Events",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "You have ${todayEvents.length} event${todayEvents.length > 1 ? 's' : ''} happening today!",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Filter Events",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: constraints.maxWidth / 2 - 6,
                                    child: _buildDropdown("Events"),
                                  ),
                                  SizedBox(
                                    width: constraints.maxWidth / 2 - 6,
                                    child: _buildDropdown("Location"),
                                  ),
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Date",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildDatePicker(),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                 
                    _buildSectionHeader("Upcoming Events", Icons.event),
                    const SizedBox(height: 16),
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 280,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        enlargeCenterPage: false,
                        padEnds: false,
                        autoPlay: false,
                      ),
                      items: upcomingEvents.isNotEmpty
                          ? upcomingEvents.map((event) {
                              //print('DEBUG: Upcoming EventPostcard - eventId: ${event.eventId}, isRegistered check: ${registeredEventIds.contains(event.eventId)}');
                              return Padding(
                                padding: EdgeInsets.zero,
                                child: EventPostcard(
                                  eventId: event.eventId,
                                  title: event.title,
                                  location: event.location,
                                  date: event.date,
                                  time: event.time,
                                  about: event.about,
                                  price: event.price,
                                  isPastEvent: event.isPastEvent,
                                  hostName: event.hostName,
                                  latitude: event.coordinates[1],
                                  longitude: event.coordinates[0],
                                  userId: userId ?? "",
                                  image: event.image,
                                  eventTarget: event.eventTarget,
                                  isRegistered: registeredEventIds.contains(event.eventId),
                                  eventType: event.eventType,
                                ),
                              );
                            }).toList()
                          : [_buildEmptyState("No upcoming events available")],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Extra Curricular Activities", Icons.sports_soccer),
                    const SizedBox(height: 16),
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 280,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        enlargeCenterPage: false,
                        padEnds: false,
                        autoPlay: false,
                      ),
                      items: extraCurricularEvents.isNotEmpty
                          ? extraCurricularEvents.map((event) {
                              //print('DEBUG: Extra Curricular EventPostcard - eventId: ${event.eventId}, isRegistered check: ${registeredEventIds.contains(event.eventId)}');
                              return Padding(
                                padding: EdgeInsets.zero,
                                child: EventPostcard(
                                  eventId: event.eventId,
                                  title: event.title,
                                  location: event.location,
                                  date: event.date,
                                  time: event.time,
                                  about: event.about,
                                  price: event.price,
                                  isPastEvent: event.isPastEvent,
                                  hostName: event.hostName,
                                  latitude: event.coordinates[1],
                                  longitude: event.coordinates[0],
                                  userId: userId ?? "",
                                  image: event.image,
                                  eventTarget: event.eventTarget,
                                  isRegistered: registeredEventIds.contains(event.eventId),
                                  eventType: event.eventType,
                                ),
                              );
                            }).toList()
                          : [_buildEmptyState("No activities available")],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
                      margin: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    List<DropdownMenuItem<String>> eventTypes = const [
      DropdownMenuItem(value: 'All event types', child: Text('All event types')),
      DropdownMenuItem(value: 'Seminar', child: Text('Seminar')),
      DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
      DropdownMenuItem(value: 'Webinar', child: Text('Webinar')),
      DropdownMenuItem(value: 'Activity', child: Text('Activity')),
    ];

    List<DropdownMenuItem<String>> locations = const [
      DropdownMenuItem(value: 'All locations', child: Text('All locations')),
      DropdownMenuItem(value: 'Caloocan', child: Text('Caloocan')),
      DropdownMenuItem(value: 'Las Piñas', child: Text('Las Piñas')),
      DropdownMenuItem(value: 'Makati', child: Text('Makati')),
      DropdownMenuItem(value: 'Malabon', child: Text('Malabon')),
      DropdownMenuItem(value: 'Mandaluyong', child: Text('Mandaluyong')),
      DropdownMenuItem(value: 'Manila', child: Text('Manila')),
      DropdownMenuItem(value: 'Marikina', child: Text('Marikina')),
      DropdownMenuItem(value: 'Muntinlupa', child: Text('Muntinlupa')),
      DropdownMenuItem(value: 'Navotas', child: Text('Navotas')),
      DropdownMenuItem(value: 'Parañaque', child: Text('Parañaque')),
      DropdownMenuItem(value: 'Pasay', child: Text('Pasay')),
      DropdownMenuItem(value: 'Pasig', child: Text('Pasig')),
      DropdownMenuItem(value: 'Quezon City', child: Text('Quezon City')),
      DropdownMenuItem(value: 'San Juan', child: Text('San Juan')),
      DropdownMenuItem(value: 'Taguig', child: Text('Taguig')),
      DropdownMenuItem(value: 'Valenzuela', child: Text('Valenzuela')),
      DropdownMenuItem(value: 'Pateros', child: Text('Pateros')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: hint == "Events" ? "Filter by event type" : hint == "Location" ? "Filter by location" : hint,
          child: Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          value: hint == "Events"
              ? selectedEventType
              : hint == "Location"
                  ? selectedLocation
                  : null,
          items: (hint == "Events" ? eventTypes : locations)
              .map((item) => DropdownMenuItem<String>(
                    value: item.value,
                    child: Semantics(
                      label: hint == "Events"
                          ? "Event type: ${item.value}"
                          : "Location: ${item.value}",
                      child: Text(item.child is Text ? (item.child as Text).data ?? '' : item.value ?? ''),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                if (hint == "Events") {
                  selectedEventType = value;
                } else if (hint == "Location") {
                  selectedLocation = value;
                }
              });
              fetchEvents();
            }
          },
        ),
      ],
    );
  }

Widget _buildDatePicker() {
  return GestureDetector(
    onTap: () => _selectDate(context),
    child: AbsorbPointer(
      child: TextField(
        controller: dateController,
        decoration: InputDecoration(
          hintText: 'Select date',
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70   // dark mode: lighter text
                : Colors.black54,  // light mode: darker text
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]   // dark background for dark mode
              : Colors.white,      // clean white for light mode
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[400]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[400]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
        ),
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
      ),
    ),
  );
}

}