import 'dart:convert';
import 'package:final_project/config.dart';
import 'package:final_project/screens/resetpassword_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'verification_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

late SharedPreferences prefs;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();

    // Check if user is already logged in
    String? token = prefs.getString('token');
    String? savedEmail = prefs.getString('saved_email');
    String? savedPassword = prefs.getString('saved_password');

    if (token != null && token.isNotEmpty) {
      // User is already logged in, navigate directly
      String? userType = prefs.getString('userType');
      
      if (mounted) {
        if (userType == "admin" || userType == "superadmin") {
          Navigator.pushReplacementNamed(context, '/admin_homescreen');
          return;
        } else {
          Navigator.pushReplacementNamed(context, '/navbar');
          return;
        }
      }
    } else if (savedEmail != null && savedPassword != null) {
      // Load saved credentials for manual login
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      setState(() {
        rememberMe = true;
      });
    }

    // Splash/loading duration before showing login UI
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() {
        isInitializing = false;
      });
    }
  }

  bool rememberMe = false;
  bool isPasswordVisible = false;
  bool isInitializing = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool emailError = false;
  bool passwordError = false;
  String emailErrorMessage = "";
  String passwordErrorMessage = "";
  String generalErrorMessage = "";

void loginUser() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  // Clear previous errors
  setState(() {
    emailError = false;
    passwordError = false;
    emailErrorMessage = "";
    passwordErrorMessage = "";
    generalErrorMessage = "";
  });

  // Validate email format
  bool isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  
  if (email.isEmpty) {
    setState(() {
      emailError = true;
      emailErrorMessage = "Email is required";
    });
    return;
  } else if (!isValidEmail) {
    setState(() {
      emailError = true;
      emailErrorMessage = "Please enter a valid email address";
    });
    return;
  }

  if (password.isEmpty) {
    setState(() {
      passwordError = true;
      passwordErrorMessage = "Password is required";
    });
    return;
  } else if (password.length < 8 || password.length > 16) {
    setState(() {
      passwordError = true;
      passwordErrorMessage = "Password must be 8-16 characters";
    });
    return;
  }

  var reqBody = {
    "email": email,
    "password": password,
  };

  try {
    var response = await http.post(
      Uri.parse(login),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(reqBody),
    );
    // print("login");

    var jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonResponse['status'] == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (rememberMe) {
        await prefs.setString('saved_email', emailController.text.trim());
        await prefs.setString('saved_password', passwordController.text.trim());
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }

      // Save user data
      String id = jsonResponse['_id'] ?? "No ID Found";
      String fullName = jsonResponse['fullName'] ?? "Guest User";
      String email = jsonResponse['email'] ?? "No Email";
      String userType = jsonResponse['userType'] ?? "No User Type";
      String token = jsonResponse['token'] ?? "";
      String icpepId = jsonResponse['icpepId'] ?? "No ID";
      String contactNumber =
          jsonResponse['contactNumber']?.toString() ?? "No Phone Number";
      String aboutMe = jsonResponse['aboutMe'] ?? "No About Me";
      String profileImage = jsonResponse['profileImage'] ?? "No Profile Image";
      String membership = jsonResponse['membership'] ?? "No Membership";

      await prefs.setString('_id', id);
      await prefs.setString('fullName', fullName);
      await prefs.setString('email', email);
      await prefs.setString('token', token);
      await prefs.setString('icpepId', icpepId);
      await prefs.setString('contactNumber', contactNumber);
      await prefs.setString('aboutMe', aboutMe);
      await prefs.setString('profileImage', profileImage);
      await prefs.setString('membership', membership);
      await prefs.setString('userType', userType);

      // 👇 Redirect based on user type
      if (userType == "admin" || userType == "superadmin") {
        Navigator.pushReplacementNamed(context, '/admin_homescreen');
      } else if (jsonResponse['isVerified'] == true) {
        Navigator.pushReplacementNamed(context, '/navbar');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(token: token),
          ),
        );
      }
    } else if (response.statusCode == 401) {
      // Use generic message for security - don't reveal if it's email or password
      setState(() {
        generalErrorMessage = "Incorrect email or password";
      });
    } else if (response.statusCode == 403) {
      setState(() {
        generalErrorMessage = jsonResponse['message'] ?? "Account disabled";
      });
    } else {
      setState(() {
        generalErrorMessage = "Incorrect email or password";
      });
    }
  } catch (e) {
    // print("Error: $e");
    setState(() {
      generalErrorMessage = "An error occurred. Please try again.";
    });
  }
}



  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App splash logo
             SvgPicture.asset(
  'assets/images/icpeplogolatest.svg',
  width: 160,
  height: 160,
  fit: BoxFit.contain,
),
              const SizedBox(height: 16),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loading...',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    children: [
                      TextSpan(text: "Regis"),
                      TextSpan(
                          text: "tra", style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Sign in",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Email TextField
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Email",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  errorText: emailError ? emailErrorMessage : null,
                ),
              ),
              const SizedBox(height: 15),

              // Password TextField
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Your password",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  errorText: passwordError ? passwordErrorMessage : null,
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),

              if (generalErrorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(generalErrorMessage,
                      style: const TextStyle(color: Colors.red)),
                ),

              // Remember Me & Forgot Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: rememberMe,
                        activeColor: Colors.amber,
                        onChanged: (bool value) {
                          setState(() {
                            rememberMe = value;
                          });
                        },
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: loginUser,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("SIGN IN",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_right_alt, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign Up Navigation
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text("Sign up",
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
