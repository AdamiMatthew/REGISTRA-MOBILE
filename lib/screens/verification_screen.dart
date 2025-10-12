import 'package:final_project/config.dart';
import 'package:final_project/screens/navbar_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

class VerificationScreen extends StatefulWidget {
  final String token;

  const VerificationScreen({super.key, required this.token});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> controllers =
      List.generate(4, (index) => TextEditingController());
  String errorMessage = "";
  late String email;
  bool isResendDisabled = false;
  int timerSeconds = 40;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    email = jwtDecodedToken['email'];
  }

  void startTimer() {
    setState(() {
      isResendDisabled = true;
      timerSeconds = 40;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timerSeconds > 0) {
          timerSeconds--;
        } else {
          isResendDisabled = false;
          countdownTimer?.cancel();
        }
      });
    });
  }

  void verifyOTP() async {
    String otpCode = controllers.map((controller) => controller.text).join();

    if (otpCode.length == 4) {
      var reqBody = {
        "email": email,
        "otp": otpCode,
        "token": widget.token,
      };
      print(reqBody);
      try {
        var response = await http.post(
          Uri.parse(verification),
          headers: {"Content-Type": "application/json"}, 
          body: jsonEncode(reqBody),
        );

        var jsonResponse = jsonDecode(response.body);

        if (response.statusCode == 200 && jsonResponse['status'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavbarScreen()),
          );
        } else {
          setState(() {
            errorMessage = jsonResponse['message'] ?? "Invalid OTP";
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = "An error occurred. Please try again.";
        });
      }
    } else {
      setState(() {
        errorMessage = "Please enter the full OTP";
      });
    }
  }

  void resendOTP() async {
    startTimer();

    try {
      var response = await http.post(
        Uri.parse(resendOtpUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        //print("OTP resent successfully.");
      } else {
        setState(() {
          errorMessage = jsonResponse['message'] ?? "Failed to resend OTP";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred. Please try again.";
      });
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Verification",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "We've sent you the verification code on Email",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 55,
                    child: TextField(
                      controller: controllers[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: verifyOTP,
              child: const Text("CONTINUE",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: isResendDisabled ? null : resendOTP,
              child: Text(
                isResendDisabled
                    ? "Resend OTP in $timerSeconds seconds"
                    : "Resend OTP",
                style: TextStyle(
                    color:
                        isResendDisabled ? Colors.grey : Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
