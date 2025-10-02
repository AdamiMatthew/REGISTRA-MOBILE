import 'dart:convert';
import 'package:final_project/config.dart';
import 'package:final_project/screens/certificate_screen.dart';
import 'package:final_project/screens/edit_profile_screen.dart';
import 'package:final_project/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:final_project/screens/feedbackform_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = "Loading...";
  String email = "Loading...";
  String userType = "Loading...";
  String contactNumber = "Loading...";
  String icpepId = "Loading...";
  String aboutMe = "Loading...";
  String profileImage = "No Image";
  String membership = "Loading...";
  String? userId = "Loading...";
  List<dynamic> pastEvents = [];
  List<dynamic> certificates = [];
  bool isLoadingPastEvents = true;
  bool isLoadingCertificates = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchPastEvents();
    fetchCertificates();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? "Guest User";
      email = prefs.getString('email') ?? "No Email";
      userType = prefs.getString('userType') ?? "No User Type";
      contactNumber = prefs.getString('contactNumber') ?? "No Contact Number";
      icpepId = prefs.getString('icpepId') ?? "No ICPEP ID";
      aboutMe = prefs.getString('aboutMe') ?? "No Information";
      profileImage = prefs.getString('profileImage') ?? "No Image";
      membership = prefs.getString('membership') ?? "No Membership";
      userId =
          prefs.getString('_id') ?? "No User ID"; // Use the correct key (_id)

      // Print the userId for debugging
      //print("User ID: $userId");
    });
  }

  Future<void> fetchPastEvents() async {
    setState(() => isLoadingPastEvents = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('_id');

    if (userId == null) {
      //print("User ID not found in SharedPreferences");
      setState(() => isLoadingPastEvents = false);
      return;
    }

    //print("Fetching past events for User ID: $userId");

    final url = Uri.parse('$registeredPast?userId=$userId');
    //print("API URL: $url");

    try {
      final response = await http.get(url);
      //print("Response status code: ${response.statusCode}");
     //print("Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Defensive filter: ensure only events where the user's registration is paid and attended
        final filtered = data.where((event) {
          try {
            final regs = event['registrations'] as List<dynamic>?;
            if (regs == null) return false;
            final match = regs.firstWhere(
              (r) => r['userId'] == userId,
              orElse: () => null,
            );
            if (match == null) return false;
            final status = (match['paymentStatus'] ?? '').toString().toLowerCase();
            final attended = match['attended'] == true;
            return status == 'paid' && attended == true;
          } catch (_) {
            return false;
          }
        }).toList();
        //print("Number of events received: ${data.length}");

        if (data.isEmpty) {
          //print("No events found for User ID: $userId");
        }

        setState(() {
          pastEvents = filtered;
          isLoadingPastEvents = false;
        });

        // Optionally debug events here
      } else {
        //print("Failed to load events: ${response.body}");
        setState(() => isLoadingPastEvents = false);
      }
    } catch (e) {
      //print("Error fetching events: $e");
      setState(() => isLoadingPastEvents = false);
    }
  }

  Future<void> fetchCertificates() async {
    setState(() => isLoadingCertificates = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('_id');
    String? token = prefs.getString('token');

    if (userId == null || token == null) {
      //print("User ID or token not found in SharedPreferences");
      setState(() => isLoadingCertificates = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$certificateUser/$userId'),
        headers: {
          'x-auth-token': token,
          'Content-Type': 'application/json',
        },
      );

      //print('Debug: Certificate API Response Status: ${response.statusCode}');
      //print('Debug: Certificate API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            certificates = data['certificates'] ?? [];
            isLoadingCertificates = false;
          });
        } else {
          //print("Failed to load certificates: ${data['message']}");
          setState(() => isLoadingCertificates = false);
        }
      } else {
        //print("Failed to load certificates: ${response.body}");
        setState(() => isLoadingCertificates = false);
      }
    } catch (e) {
      //print("Error fetching certificates: $e");
      setState(() => isLoadingCertificates = false);
    }
  }

  

  Future<bool> checkFeedbackSubmitted(String userId, String eventId) async {
    final url = Uri.parse('$feedbackCheck?userId=$userId&eventId=$eventId');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.get(
        url,
        headers: {
          'x-auth-token': token ?? '',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //print('Feedback Check Response: ${response.body}');
        //print('Feedback Check Response: ${data['hasSubmitted']}');
        return data['hasSubmitted'] == true;
      } else {
        //print('Failed to check feedback submission: ${response.body}');
        return false;
      }
    } catch (e) {
      //print('Error checking feedback submission: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Profile"),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: (profileImage != "No Image" &&
                                profileImage.isNotEmpty)
                            ? NetworkImage(profileImage)
                            : null,
                        child:
                            (profileImage == "No Image" || profileImage.isEmpty)
                                ? const Icon(Icons.person, size: 40)
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(userType),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        fullName: fullName,
                        email: email,
                        userType: userType,
                        contactNumber: contactNumber,
                        icpepId: icpepId,
                        aboutMe: aboutMe,
                        profileImage: profileImage,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "About Me",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              aboutMe,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),

            const SizedBox(height: 24),

            const Text(
              "Past Events",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            isLoadingPastEvents
                ? const Center(child: CircularProgressIndicator())
                : pastEvents
                        .where((event) => event['hasCertificate'] == false)
                        .isEmpty
                    ? const Center(child: Text('No past events found.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pastEvents
                            .where((event) => event['hasCertificate'] == false)
                            .length,
                        itemBuilder: (context, index) {
                          var event = pastEvents
                              .where(
                                  (event) => event['hasCertificate'] == false)
                              .toList()[index];
                          String? image = event['image'];
                          String? dateStr = event['date'];
                          String? hostName = event['hostName'];

                          String formattedDate = '';
                          if (dateStr != null && dateStr.isNotEmpty) {
                            try {
                              DateTime eventDate = DateTime.parse(dateStr);
                              formattedDate =
                                  '${DateFormat('MMMM').format(eventDate)}, ${eventDate.day}, ${eventDate.year}';
                            } catch (e) {
                              formattedDate = 'Invalid date';
                            }
                          }

                          return InkWell(
                            onTap: () async {
                              String? eventId = event['_id'];
                              if (eventId == null || userId == null) return;

                              bool submitted = await checkFeedbackSubmitted(
                                  userId!, eventId);

                              if (submitted) {
                                //print(
                                   // "Feedback submission status for event $eventId: $submitted");

                                // Navigate directly to Certificate view, or you can show the certificate if available
                                // You can pass the certificate data or just eventId and userId
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CertificateScreen(
                                      eventId: eventId,
                                      userId: userId!,
                                    ),
                                  ),
                                );
                              } else {
                               // print(
                                    //"nothing submitted  $eventId: $submitted");
                                // Navigate to feedback form
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FeedbackForm(
                                      eventId: eventId,
                                      userId: userId!,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 8),
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
                                      child: image != null && image.isNotEmpty
                                          ? Image.network(
                                              image,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                      Icons.broken_image,
                                                      size: 30,
                                                      color: Colors.grey),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: 100,
                                              height: 100,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          if (hostName != null &&
                                              hostName.isNotEmpty)
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
                                                  event['location'] ??
                                                      'No Location',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (formattedDate.isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_month,
                                                    size: 14,
                                                    color: Colors.grey),
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

            // Certificate Section
            const SizedBox(height: 24),
            if (pastEvents.where((event) => event['hasCertificate'] == true).isNotEmpty) ...[
              const Text(
                "Certificates",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              isLoadingPastEvents
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pastEvents
                          .where((event) => event['hasCertificate'] == true)
                          .length,
                      itemBuilder: (context, index) {
                        var event = pastEvents
                            .where((event) => event['hasCertificate'] == true)
                            .toList()[index];

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'] ?? 'Certificate',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Held on: ${DateFormat('MMMM dd, yyyy').format(DateTime.parse(event['date']))}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          String? eventId = event['_id'];
                                          //print(eventId);
                                          //print("object");
                                          //print(userId);

                                          if (eventId == null ||
                                              userId == null) return;

                                          // Navigate directly to Certificate view, or you can show the certificate if available
                                          // You can pass the certificate data or just eventId and userId
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CertificateScreen(
                                                eventId: eventId,
                                                userId: userId!,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                        ),
                                        child: const Text('View Certificate'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
