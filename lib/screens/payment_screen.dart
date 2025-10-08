import 'dart:io';
import 'package:final_project/config.dart';
import 'package:final_project/screens/navbar_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart'; // ✅ Added for date formatting

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.ticketPrice,
    required this.eventName,
    required this.eventDate,
    required this.eventTime,
    this.registrationId,
  });

  final String eventId;
  final double ticketPrice;
  final String eventName;
  final String eventDate;
  final String eventTime;
  final String? registrationId; // If resubmitting for an existing registration

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _accountNameController =
      TextEditingController(text: "SAMPLE ACCOUNT NAME");
  final TextEditingController _mobileNumberController =
      TextEditingController(text: "0969 469 9669");

  XFile? _image;
  String? imageUrl;
  final ImagePicker _picker = ImagePicker();
  String userName = ""; // To store the fetched username
  final Set<String> _uploadedFilePaths = <String>{}; // Prevent duplicate uploads

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('fullName') ?? "User";
    });
  }

  // ✅ Format event date to "Month Day, Year"
  String _formatEventDate(String rawDate) {
    try {
      DateTime parsedDate;

      if (rawDate.contains('-')) {
        // Example: "2025-09-24"
        parsedDate = DateTime.parse(rawDate);
      } else {
        // Example: "September 24, 2025"
        parsedDate = DateFormat("MMMM d, yyyy").parse(rawDate);
      }

      return DateFormat("MMMM d, yyyy").format(parsedDate);
    } catch (e) {
      return rawDate; // fallback if parsing fails
    }
  }

  // ================= Calendar =================
  Future<void> _addToGoogleCalendar() async {
    try {
      DateTime eventDateTime =
          _parseEventDateTime(widget.eventDate, widget.eventTime);
      DateTime endDateTime = eventDateTime.add(const Duration(hours: 2));

      List<String> calendarUrls = [
        'https://calendar.google.com/calendar/render?'
            'action=TEMPLATE'
            '&text=${Uri.encodeComponent(widget.eventName)}'
            '&dates=${eventDateTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]|\.\d{3}'), '')}/${endDateTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]|\.\d{3}'), '')}'
            '&details=${Uri.encodeComponent("Event: ${widget.eventName}\nDate: ${_formatEventDate(widget.eventDate)}\nTime: ${widget.eventTime}\nPrice: ₱${widget.ticketPrice.toStringAsFixed(2)}")}'
            '&location=${Uri.encodeComponent("Event Location")}'
            '&sf=true'
            '&output=xml',
        'calshow://',
        'content://com.android.calendar/time/${eventDateTime.millisecondsSinceEpoch}'
            '?title=${Uri.encodeComponent(widget.eventName)}'
            '&description=${Uri.encodeComponent("Event: ${widget.eventName}\nDate: ${_formatEventDate(widget.eventDate)}\nTime: ${widget.eventTime}\nPrice: ₱${widget.ticketPrice.toStringAsFixed(2)}")}'
            '&location=${Uri.encodeComponent("Event Location")}'
            '&beginTime=${eventDateTime.millisecondsSinceEpoch}'
            '&endTime=${endDateTime.millisecondsSinceEpoch}',
      ];

      bool launched = false;
      for (String url in calendarUrls) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      }

      if (launched && mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Calendar Event Added"),
              content: const Text(
                "The event has been opened in your calendar app. Please save it to add it to your calendar.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Calendar Error"),
              content: const Text(
                "Unable to open calendar app. Please manually add the event to your calendar.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  DateTime _parseEventDateTime(String date, String time) {
    try {
      DateTime parsedDate;
      if (date.contains('-')) {
        parsedDate = DateTime.parse(date);
      } else {
        parsedDate = DateFormat("MMMM d, yyyy").parse(date);
      }

      int hour, minute;
      if (time.contains('AM') || time.contains('PM')) {
        String cleanTime = time.replaceAll(' ', '');
        bool isPM = cleanTime.contains('PM');
        String timeOnly =
            cleanTime.replaceAll('AM', '').replaceAll('PM', '');
        List<String> timeParts = timeOnly.split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      } else {
        List<String> timeParts = time.split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  // ================= Upload Receipt =================
  void _uploadReceipt() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      if (_uploadedFilePaths.contains(pickedImage.path)) {
        _showErrorSnackbar(
            "You already uploaded this image. Please select a different file.");
        return;
      }
      setState(() {
        _image = pickedImage;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Uploading image..."),
                ],
              ),
            ),
          );
        },
      );

      await Future.delayed(const Duration(seconds: 5));

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dqbnc38or/image/upload'),
        );

        request.fields['upload_preset'] = 'event_preset';
        request.files
            .add(await http.MultipartFile.fromPath('file', _image!.path));

        var response = await request.send();

        Navigator.pop(context);

        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var result = jsonDecode(String.fromCharCodes(responseData));

          if (result.containsKey('secure_url')) {
            setState(() {
              imageUrl = result['secure_url'];
            });
            _uploadedFilePaths.add(pickedImage.path);
          } else {
            _showErrorSnackbar("Upload failed: No image URL returned.");
          }
        } else {
          _showErrorSnackbar("Upload failed with status: ${response.statusCode}");
        }
      } catch (e) {
        Navigator.pop(context);
        _showErrorSnackbar("Error uploading image.");
      }
    }
  }

  // ================= Register =================
  void _registerGCash() async {
    // Block same-day registration
    try {
      DateTime parsedDate;
      if (widget.eventDate.contains('-')) {
        parsedDate = DateTime.parse(widget.eventDate);
      } else {
        parsedDate = DateFormat("MMMM d, yyyy").parse(widget.eventDate);
      }
      final now = DateTime.now();
      final isSameDay = parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day;
      if (isSameDay) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Registration Closed"),
              content: const Text("Same-day registrations are not allowed for this event."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }
    } catch (_) {}

    // Prevent multiple registrations on the same day across different events
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('_id');
      if (userId != null && userId.isNotEmpty) {
        final resp = await http.get(Uri.parse('$registered?userId=$userId'));
        if (resp.statusCode == 200) {
          final List<dynamic> events = json.decode(resp.body);

          DateTime parseDate(dynamic dateVal) {
            if (dateVal == null) return DateTime.fromMillisecondsSinceEpoch(0);
            final String dateStr = dateVal.toString();
            if (dateStr.contains('-')) {
              return DateTime.parse(dateStr);
            }
            return DateFormat('MMMM d, yyyy').parse(dateStr);
          }

          final DateTime current = parseDate(widget.eventDate);
          final bool sameDayExists = events.any((e) {
            try {
              final DateTime d = parseDate(e['date']);
              final bool sameDay = d.year == current.year && d.month == current.month && d.day == current.day;
              return sameDay && (e['_id']?.toString() != widget.eventId);
            } catch (_) {
              return false;
            }
          });

          if (sameDayExists) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Registration Blocked"),
                  content: const Text("You are already registered for another event on this date."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
            return;
          }
        }
      }
    } catch (_) {}

    if (imageUrl == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Upload Required"),
            content: const Text(
                "Please upload your payment receipt before registering."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? fullName = prefs.getString('fullName');
    String? email = prefs.getString('email');
    String? token = prefs.getString('token');
    String? userId = prefs.getString('_id');

    if (fullName == null || email == null || userId == null) {
      _showErrorSnackbar("User not logged in or missing information.");
      return;
    }

    final bool isResubmission = widget.registrationId != null && widget.registrationId!.isNotEmpty;

    Map<String, dynamic> reqBody;
    if (isResubmission) {
      // Only update existing registration's receipt to avoid duplicates
      reqBody = {
        "registrationId": widget.registrationId,
        "receipt": imageUrl,
      };
    } else {
      reqBody = {
        "eventId": widget.eventId,
        "userId": userId,
        "fullName": fullName,
        "email": email,
        "paymentStatus": "pending",
        "ticketQR": "",
        "receipt": imageUrl,
      };
    }

    try {
      var response = await http.post(
        Uri.parse(register),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(reqBody),
      );

      if (response.statusCode == 200) {
        if (isResubmission) {
          _showResubmissionSuccessDialog();
        } else {
          _showRegistrationSuccessDialog();
        }
      } else {
        _showErrorSnackbar("Failed to register: ${response.body}");
      }
    } catch (e) {
      _showErrorSnackbar("Error registering to event.");
    }
  }

  void _showResubmissionSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Receipt Submitted"),
          content: const Text(
              "Your receipt has been resubmitted for review. You'll be notified once it's re-verified."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const NavbarScreen()),
                  (route) => false,
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showRegistrationSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // prevents tapping outside to close
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // disables back button & swipe back
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Registration Successful"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "You have successfully registered. Your ticket is in the ticket navigation bar."),
              const SizedBox(height: 16),
              const Text(
                "Would you like to add this event to your Google Calendar?",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NavbarScreen(),
                  ),
                );
              },
              child: const Text("Skip"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _addToGoogleCalendar();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NavbarScreen(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Add to Calendar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}


  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.transparent,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              SvgPicture.asset('assets/images/Gcash Logo Vector.svg', height: 100),
              const SizedBox(height: 8),
              const Text(
                "Send your payment through GCash",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/peso.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.ticketPrice.toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // ✅ Display Event Details with formatted date
              Text(
                widget.eventName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatEventDate(widget.eventDate)} at ${widget.eventTime}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              // GCash Payment Details
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "GCash Payment Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField("Account Name", _accountNameController,
                          isReadOnly: true),
                      const SizedBox(height: 16),
                      _buildInputField("Mobile Number", _mobileNumberController,
                          isReadOnly: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bank Payment Details
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bank Payment Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                          "Bank Name", TextEditingController(text: "ICPEP"),
                          isReadOnly: true),
                      const SizedBox(height: 16),
                      _buildInputField(
                          "Bank Account Number",
                          TextEditingController(text: "1234 5678 9101 1121"),
                          isReadOnly: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upload Receipt Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload Payment Receipt",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Please upload a clear image of your payment receipt for verification.",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                          "SELECT AND UPLOAD IMAGE",
                          _uploadReceipt,
                          Colors.blue.shade600),
                      if (_image != null) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_image!.path),
                                width: 150, height: 150, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "File: ${File(_image!.path).path.split('/').last}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              _buildActionButton(
                  (widget.registrationId != null && widget.registrationId!.isNotEmpty)
                      ? "RESEND RECEIPT"
                      : "COMPLETE REGISTRATION",
                  _registerGCash,
                  Colors.green.shade700),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: isReadOnly
                ? Colors.grey.shade100
                : const Color(0xFFF5F4FA),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
