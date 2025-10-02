import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;

import 'package:final_project/widgets/custom_dialogs.dart';
import 'package:final_project/screens/login_screen.dart';
import 'package:final_project/config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController icpepIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool agreedToTerms = false; // Track terms agreement
  String membership = "non-member"; // Default to Non-Member
  String userType = "student"; // Default to Student

  // Password strength criteria
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasSpecialChar = false;
  bool _hasValidLength = false;

  // Field-specific error states
  bool fullNameError = false;
  bool emailError = false;
  bool contactNumberError = false;
  bool passwordError = false;
  bool confirmPasswordError = false;
  bool icpepIdError = false;
  bool userTypeError = false;
  bool membershipError = false;
  bool termsError = false;
  
  String fullNameErrorMessage = "";
  String emailErrorMessage = "";
  String contactNumberErrorMessage = "";
  String passwordErrorMessage = "";
  String confirmPasswordErrorMessage = "";
  String icpepIdErrorMessage = "";
  String userTypeErrorMessage = "";
  String membershipErrorMessage = "";
  String termsErrorMessage = "";
  String generalErrorMessage = "";

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
 @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    icpepIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showTermsAndConditions();
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showTermsAndConditions();
      };
  }
  void _updatePasswordCriteria(String value) {
    setState(() {
      _hasLowercase = RegExp(r"[a-z]").hasMatch(value);
      _hasUppercase = RegExp(r"[A-Z]").hasMatch(value);
      _hasSpecialChar = RegExp(r"[^A-Za-z0-9]").hasMatch(value);
      _hasValidLength = value.length >= 8 && value.length <= 16;
    });
  }

  void registerUser() async {
    String fullName = fullNameController.text.trim();
    String email = emailController.text.trim();
    String contactNumber = contactNumberController.text.trim();
    String icpepId = icpepIdController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // Clear previous errors
    setState(() {
      fullNameError = false;
      emailError = false;
      contactNumberError = false;
      passwordError = false;
      confirmPasswordError = false;
      icpepIdError = false;
      userTypeError = false;
      membershipError = false;
      termsError = false;
      fullNameErrorMessage = "";
      emailErrorMessage = "";
      contactNumberErrorMessage = "";
      passwordErrorMessage = "";
      confirmPasswordErrorMessage = "";
      icpepIdErrorMessage = "";
      userTypeErrorMessage = "";
      membershipErrorMessage = "";
      termsErrorMessage = "";
      generalErrorMessage = "";
    });

    // Validate required fields
    bool hasErrors = false;
    
    if (fullName.isEmpty) {
      setState(() {
        fullNameError = true;
        fullNameErrorMessage = "Full name is required";
      });
      hasErrors = true;
    }
    
    if (email.isEmpty) {
      setState(() {
        emailError = true;
        emailErrorMessage = "Email is required";
      });
      hasErrors = true;
    }
    
    if (contactNumber.isEmpty) {
      setState(() {
        contactNumberError = true;
        contactNumberErrorMessage = "Contact number is required";
      });
      hasErrors = true;
    }
    
    if (password.isEmpty) {
      setState(() {
        passwordError = true;
        passwordErrorMessage = "Password is required";
      });
      hasErrors = true;
    }
    
    if (confirmPassword.isEmpty) {
      setState(() {
        confirmPasswordError = true;
        confirmPasswordErrorMessage = "Confirm password is required";
      });
      hasErrors = true;
    }
    
    if (membership == "member" && icpepId.isEmpty) {
      setState(() {
        icpepIdError = true;
        icpepIdErrorMessage = "ICPEP ID is required for Members";
      });
      hasErrors = true;
    }
    
    if (!agreedToTerms) {
      setState(() {
        termsError = true;
        termsErrorMessage = "You must agree to the terms and conditions";
      });
      hasErrors = true;
    }
    
    if (hasErrors) {
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        emailError = true;
        emailErrorMessage = "Please enter a valid email address";
      });
      return;
    }

    if (contactNumber.length != 11 || !RegExp(r'^\d{11}$').hasMatch(contactNumber)) {
      setState(() {
        contactNumberError = true;
        contactNumberErrorMessage = "Contact number must be exactly 11 digits";
      });
      return;
    }

    // Add validation for number starting with 0
    if (!contactNumber.startsWith('0')) {
      setState(() {
        contactNumberError = true;
        contactNumberErrorMessage = "Contact number must start with 0";
      });
      return;
    }

    if (password.length < 8 || password.length > 16) {
      setState(() {
        passwordError = true;
        passwordErrorMessage = "Password must be 8-16 characters long";
      });
      return;
    }

    // Enforce password strength (length, lowercase, uppercase, special character)
    final bool meetsStrength =
        password.length >= 8 && password.length <= 16 &&
        RegExp(r"[a-z]").hasMatch(password) &&
        RegExp(r"[A-Z]").hasMatch(password) &&
        RegExp(r"[^A-Za-z0-9]").hasMatch(password);

    if (!meetsStrength) {
      setState(() {
        passwordError = true;
        passwordErrorMessage = "Password must include lowercase, uppercase, and special character";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        confirmPasswordError = true;
        confirmPasswordErrorMessage = "Passwords do not match";
      });
      return;
    }

    // Check if email already exists
    try {
      var emailCheckResponse = await http.post(
        Uri.parse(checkEmailExists),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (emailCheckResponse.statusCode == 200) {
        var emailCheckBody = jsonDecode(emailCheckResponse.body);
        if (emailCheckBody['exists'] == true) {
          setState(() {
            emailError = true;
            emailErrorMessage = "This email is already associated with an account";
          });
          return;
        }
      } else {
        setState(() {
          generalErrorMessage = "Failed to check email. Please try again.";
        });
        return;
      }
    } catch (e) {
      setState(() {
        generalErrorMessage = "An error occurred while checking the email. Please check your internet connection.";
      });
      return;
    }

    // Proceed with registration if email does not exist
    var regBody = {
      "fullName": fullName,
      "contactNumber": contactNumber,
      "email": email,
      "password": password,
      "confirmPassword": confirmPassword,
      "userType": userType,
      "membership": membership,
      "icpepId": membership == "member" ? icpepId : "", // Include icpepId only for Members
    };

    try {
      var response = await http.post(
        Uri.parse(registration),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody),
      );

      if (response.statusCode == 200) {
        CustomDialogs.showSuccessRegisterDialog(
          context,
          "Registration Successful!",
          onConfirmed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        );
      } else {
        var responseBody = jsonDecode(response.body);
        String errorMessage = responseBody['message'] ?? "Registration failed. Please try again.";
        String? field = responseBody['field'];
        
        // Set field-specific error based on server response
        if (field != null) {
          switch (field) {
            case 'fullName':
              setState(() {
                fullNameError = true;
                fullNameErrorMessage = errorMessage;
              });
              break;
            case 'email':
              setState(() {
                emailError = true;
                emailErrorMessage = errorMessage;
              });
              break;
            case 'contactNumber':
              setState(() {
                contactNumberError = true;
                contactNumberErrorMessage = errorMessage;
              });
              break;
            case 'password':
              setState(() {
                passwordError = true;
                passwordErrorMessage = errorMessage;
              });
              break;
            case 'confirmPassword':
              setState(() {
                confirmPasswordError = true;
                confirmPasswordErrorMessage = errorMessage;
              });
              break;
            case 'icpepId':
              setState(() {
                icpepIdError = true;
                icpepIdErrorMessage = errorMessage;
              });
              break;
            case 'userType':
              setState(() {
                userTypeError = true;
                userTypeErrorMessage = errorMessage;
              });
              break;
            case 'membership':
              setState(() {
                membershipError = true;
                membershipErrorMessage = errorMessage;
              });
              break;
            default:
              setState(() {
                generalErrorMessage = errorMessage;
              });
          }
        } else {
          setState(() {
            generalErrorMessage = errorMessage;
          });
        }
      }
    } catch (e) {
      setState(() {
        generalErrorMessage = "An error occurred. Please check your connection and try again.";
      });
    }
  }

  // Show Terms and Conditions Dialog
  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'By using Registra, you agree to the following terms and conditions:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Account Registration:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '• You must provide accurate and complete information during registration\n'
                  '• You are responsible for maintaining the confidentiality of your account\n'
                 
                ),
                const SizedBox(height: 8),
                const Text(
                  '2. Event Registration:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '• Event registrations are subject to availability\n'
             
                ),
                const SizedBox(height: 8),
                const Text(
                  '3. Data Privacy:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '• We collect and process your personal data for event management\n'
                  '• Your data is stored securely and used only for app functionality\n'
                  '• We do not share your personal information with third parties\n'
                  
                ),
                const SizedBox(height: 8),
                const Text(
                  '4. User Conduct:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '• You agree to use the app for lawful purposes only\n'
                  '• You will not attempt to gain unauthorized access to the system\n'
                  '• You will not interfere with the app\'s functionality\n',
                ),
                const SizedBox(height: 8),
                const Text(
                  '5. Limitation of Liability:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '• Registra is not liable for any damages arising from app use\n'
                  '• We reserve the right to modify or discontinue services\n'
                  '• Event organizers are responsible for their own events\n',
                ),
                const SizedBox(height: 8),
                const Text(
                  '6. Contact Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'For questions about these terms or data privacy, contact us at:\n'
                  'Email: support@registra.com\n'
                  'Phone: +63 969 469 9669',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Text("Sign up", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  hintText: "Full name",
                  labelText: "Full name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: fullNameError ? fullNameErrorMessage : null,
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Email",
                  labelText: "Email address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: emailError ? emailErrorMessage : null,
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: contactNumberController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone),
                  hintText: "Contact number",
                  labelText: "Contact number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  counterText: "",
                  errorText: contactNumberError ? contactNumberErrorMessage : null,
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: userType,
                items: ["student", "professional"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    userType = newValue!;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.work_outline),
                  labelText: 'User type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: userTypeError ? userTypeErrorMessage : null,
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: membership,
                items: ["member", "non-member"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    membership = newValue!;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: 'Membership',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: membershipError ? membershipErrorMessage : null,
                ),
              ),
              const SizedBox(height: 15),

              if (membership == "member")
                TextField(
                  controller: icpepIdController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge),
                    hintText: "ICPEP ID",
                    labelText: "ICPEP ID",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: icpepIdError ? icpepIdErrorMessage : null,
                  ),
                ),
              if (membership == "member") const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Your password",
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: passwordError ? passwordErrorMessage : null,
                  suffixIcon: Semantics(
                    label: isPasswordVisible ? 'Hide password' : 'Show password',
                    button: true,
                    child: IconButton(
                      tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                onChanged: _updatePasswordCriteria,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Confirm password",
                  labelText: "Confirm password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: confirmPasswordError ? confirmPasswordErrorMessage : null,
                  suffixIcon: Semantics(
                    label: isConfirmPasswordVisible ? 'Hide password' : 'Show password',
                    button: true,
                    child: IconButton(
                      tooltip: isConfirmPasswordVisible ? 'Hide password' : 'Show password',
                      icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Password strength helper (moved below confirm password)
              Builder(
                builder: (context) {
                  final bool allMet = _hasValidLength && _hasLowercase && _hasUppercase && _hasSpecialChar;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!allMet)
                        const Text(
                          'Password too weak',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _hasValidLength ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: _hasValidLength ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contains 8-16 characters',
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasValidLength ? Colors.green : Colors.black87,
                              fontWeight: _hasValidLength ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            _hasLowercase ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: _hasLowercase ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contains a lowercase letter (a-z)',
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasLowercase ? Colors.green : Colors.black87,
                              fontWeight: _hasLowercase ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            _hasUppercase ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: _hasUppercase ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contains an uppercase letter (A-Z)',
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasUppercase ? Colors.green : Colors.black87,
                              fontWeight: _hasUppercase ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            _hasSpecialChar ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: _hasSpecialChar ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contains a special character (!@#…)',
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasSpecialChar ? Colors.green : Colors.black87,
                              fontWeight: _hasSpecialChar ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              // General error message display
              if (generalErrorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    generalErrorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 12),

              // Terms and Conditions Checkbox
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: 'Agree to terms and privacy policy',
                        child: Checkbox(
                          value: agreedToTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              agreedToTerms = value ?? false;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms and Conditions',
                                recognizer: _termsRecognizer,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                recognizer: _privacyRecognizer,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Terms error message
                  if (termsError)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Text(
                        termsErrorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: registerUser,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    child: const Text("Sign in", style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

 