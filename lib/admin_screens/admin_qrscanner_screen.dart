import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:convert/convert.dart';
import 'package:final_project/config.dart';

class AdminQrscannerScreen extends StatefulWidget {
  const AdminQrscannerScreen({super.key});

  @override
  State<AdminQrscannerScreen> createState() => _AdminQrscannerScreenState();
}

class _AdminQrscannerScreenState extends State<AdminQrscannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _showSuccessCard = false;
  bool _showErrorCard = false; // New boolean for error card
  String _errorMessage = ''; // Store error message

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // AES decryption function
  String decryptAES256CBC(String encryptedHex, String ivHex) {
    const String keyHex = '51bb1a88531b1f163af82f0b4d7f33267e492f694c3235d8ffbe79e0cc197e5f';

    final key = encrypt.Key(Uint8List.fromList(hex.decode(keyHex)));
    final iv = encrypt.IV(Uint8List.fromList(hex.decode(ivHex)));

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encryptedBytes = Uint8List.fromList(hex.decode(encryptedHex));
    final encryptedData = encrypt.Encrypted(encryptedBytes);

    final decrypted = encrypter.decrypt(encryptedData, iv: iv);

    return decrypted;
  }

  void _handleQRCode(String code) async {
    try {
      final Map<String, dynamic> encrypted = jsonDecode(code);
      final String encryptedData = encrypted['data'];
      final String iv = encrypted['iv'];

      final decryptedJson = decryptAES256CBC(encryptedData, iv);
      final Map<String, dynamic> payload = jsonDecode(decryptedJson);
      final String? id = payload['id'];
      final String? fullName = payload['fullName'];
      final String? userType = payload['userType'];

      if (id != null && !_isProcessing) {
        setState(() {
          _isProcessing = true;
        });

        _controller.stop();

        // Proceed with attendance update (server will check if event is past)
        final response = await http.put(
          Uri.parse(attendanceUpdate),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': id}),
        );

        final responseBody = jsonDecode(response.body);
        // debugPrint('Status Code: ${response.statusCode}');
        // debugPrint('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          // Attendance updated successfully
          setState(() {
            _showSuccessCard = true;
          });
        } else if (response.statusCode == 400) {
          // Handle different error cases
          String errorMsg = responseBody['message'] ?? 'Unknown error';
          
          if (errorMsg.contains('already ended') || errorMsg.contains('past events')) {
            _errorMessage = 'Event Already Ended!';
          } else if (errorMsg.contains('already been used')) {
            _errorMessage = 'QR Code Already Used!';
          } else {
            _errorMessage = 'Registration Failed!';
          }
          
          setState(() {
            _showErrorCard = true;
          });
        } else {
          // Other errors
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('An error occurred. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _showSuccessCard = false;
              _showErrorCard = false; // Hide error card
              _errorMessage = '';
            });
            _controller.start();
          }
        });
      } else {
        // debugPrint('Invalid or missing ID in QR code');
      }
    } catch (e) {
      // debugPrint('Error decoding QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('QR Scanner', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture barcodeCapture) {
              if (!_isProcessing) {
                final Barcode? barcode = barcodeCapture.barcodes.first;
                final String? code = barcode?.rawValue;

                if (code != null) {
                  // debugPrint('QR Code found: $code');
                  _handleQRCode(code);
                }
              }
            },
          ),
          // Scan area overlay
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 3),
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Align the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccessCard)
            _ResultCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              message: 'Registration Successful!',
            ),
          if (_showErrorCard)
            _ResultCard(
              icon: Icons.cancel,
              iconColor: Colors.red,
              message: _errorMessage.isNotEmpty ? _errorMessage : 'QR Code Already Used!',
            ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  const _ResultCard({
    required this.icon,
    required this.iconColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 80),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}