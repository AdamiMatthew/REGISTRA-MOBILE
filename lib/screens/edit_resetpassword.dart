import 'package:final_project/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EditResetpassword extends StatefulWidget {
  
  const EditResetpassword({super.key});

  @override
  State<EditResetpassword> createState() => _EditResetpasswordState();
}

class _EditResetpasswordState extends State<EditResetpassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false; // To show a loading indicator while updating password

  // Function to validate if passwords match
  bool _doPasswordsMatch() {
    return _passwordController.text.trim() == _confirmPasswordController.text.trim();
  }
   
  // Function to update password
 Future<void> _updatePassword() async {
  final password = _passwordController.text.trim();
  final confirmPassword = _confirmPasswordController.text.trim();

  if (password.isEmpty || confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both password fields')),
    );
    return;
  }

  if (!_doPasswordsMatch()) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Passwords do not match'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please login again.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse(resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );

    final responseBody = jsonDecode(response.body);
    //print(responseBody); // Debugging line to check the response
    if (response.statusCode == 200 && responseBody['status'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: const Text('Password updated successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseBody['error'] ?? 'Failed to update password')),
       
      );
       //print(responseBody['error']);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An error occurred. Please try again.')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please enter your new password and confirm it to reset',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Enter your new password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Confirm your new password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _updatePassword, // Disable button while loading
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'UPDATE PASSWORD',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_right_alt, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
