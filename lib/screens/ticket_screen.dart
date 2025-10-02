import 'dart:convert';
import 'package:final_project/config.dart';
import 'package:final_project/screens/navbar_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TicketScreen extends StatefulWidget {
  final String title;
  final String location;
  final String? ticketQR;
  final String registrationsId;
  final String image;
  final String eventDate;
  final String eventTime;
  final bool scanned;

  const TicketScreen({
    super.key,
    required this.title,
    required this.ticketQR,
    required this.location,
    required this.registrationsId,
    required this.image,
    required this.eventDate,
    required this.eventTime,
    this.scanned = false,
  });

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  String? ticketQR;
  String userName = "";
  bool attended = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    fetchTicketQR();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.scanned) {
        _onTicketScannedSuccess();
      }
    });
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('fullName') ?? "User";
    });
  }
Future<void> _onTicketScannedSuccess() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Welcome!"),
      content: const Text("Welcome to the event 🎉"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // close dialog
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const NavbarScreen()), // your HomeScreen
              (route) => false,
            );
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

  Future<void> fetchTicketQR() async {
    try {
      //print("Fetching ticket QR for registrationsId: ${widget.registrationsId}");
      final url = Uri.parse('$ticket?registrationsId=${widget.registrationsId}');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"registrationsId": widget.registrationsId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          final fullQR = data['ticketQR'] ?? '';
          ticketQR = fullQR.isNotEmpty ? fullQR.split(',').last : '';
          attended = (data['attended'] == true);
        });
        if (mounted && attended) {
          // Show welcome once when attended is true
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onTicketScannedSuccess();
          });
        }
        //print("Fetched Ticket QR: $ticketQR");

        // Notification removed; handled centrally elsewhere
      } else {
        //print("Failed to fetch ticket QR: ${response.body}");
      }
    } catch (e) {
      //print("Error fetching ticket QR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrImage = ticketQR != null && ticketQR!.isNotEmpty
        ? Image.memory(
            base64Decode(ticketQR!),
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.qr_code, size: 200, color: Colors.grey);
            },
          )
        : const Icon(Icons.qr_code, size: 100, color: Colors.grey);

    // Format the date
    String formattedDate = '';
    try {
      DateTime date = DateTime.parse(widget.eventDate);
      formattedDate = DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      //print('Error parsing or formatting date: $e');
      formattedDate = widget.eventDate;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: widget.image.isNotEmpty
                          ? Image.network(
                              widget.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported,
                                      size: 40, color: Colors.grey),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported,
                                  size: 40, color: Colors.grey),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person,
                          size: 20, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: qrImage,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event,
                          size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.location,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '$formattedDate at ${widget.eventTime}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
