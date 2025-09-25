import 'dart:io';
import 'package:final_project/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String userType;
  final String contactNumber;
  final String icpepId;
  final String aboutMe;
  final String profileImage;

  const EditProfileScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.userType,
    required this.contactNumber,
    required this.icpepId,
    required this.aboutMe,
    required this.profileImage,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController fullNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController aboutMeController;
  String? phoneError;

  XFile? _image;
  String? profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.fullName);
    phoneNumberController = TextEditingController(text: widget.contactNumber);
    aboutMeController = TextEditingController(text: widget.aboutMe);
    profileImageUrl =
        widget.profileImage; // Initialize with the current profile image
  }

  Future<void> _uploadProfileImage() async {
  final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedImage != null) {
    setState(() {
      _image = pickedImage;
    });

    // Show loading dialog
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

    // Wait for 5 seconds before uploading
    await Future.delayed(const Duration(seconds: 5));

    // Upload image to Cloudinary
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dqbnc38or/image/upload'),
      );

      request.fields['upload_preset'] = 'event_preset'; // Cloudinary preset
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var response = await request.send();

      Navigator.pop(context); // Close the loading dialog

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var result = jsonDecode(String.fromCharCodes(responseData));

        setState(() {
          profileImageUrl = result['secure_url'];
        });

        //print("Image uploaded successfully: $profileImageUrl");
      } else {
        //print("Failed to upload image: ${response.statusCode}");
        _showErrorSnackbar("Failed to upload image");
      }
    } catch (e) {
      Navigator.pop(context); // Close the loading dialog if error occurs
      //print("Error uploading image: $e");
      _showErrorSnackbar("Error uploading image");
    }
  }
}

void _showErrorSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}


  Future<void> updateProfile() async {
    // Add phone number validation before updating
  

    try {
      final response = await http.post(
        Uri.parse(update),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'fullName': fullNameController.text.trim(),
          'contactNumber': phoneNumberController.text.trim(),
          'aboutMe': aboutMeController.text.trim(),
          'profileImage':
              profileImageUrl, // Include the uploaded profile image URL
        }),
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', fullNameController.text.trim());
        await prefs.setString(
            'contactNumber', phoneNumberController.text.trim());
        await prefs.setString('aboutMe', aboutMeController.text.trim());
        await prefs.setString('profileImage', profileImageUrl ?? '');

        // Show success message in a floating dialog (card)
        _showSuccessDialog();

        // Wait for 3 seconds before navigating to HomeScreen
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushNamedAndRemoveUntil(
              context, '/navbar', (route) => false);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (error) {
      //print('Update error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 40),
                SizedBox(height: 16),
                Text(
                  'Profile updated successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploadProfileImage, // Trigger image upload on tap
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : const NetworkImage('https://via.placeholder.com/150'),
                child:
                    const Icon(Icons.camera_alt, size: 30, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: widget.userType,
                hintText: widget.userType,
                border: const OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: widget.email,
                hintText: widget.email,
                border: const OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: widget.icpepId,
                hintText: widget.icpepId,
                border: const OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                filled: true,
                hintText: '09XXXXXXXXX',
                errorText: phoneError
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                setState(() {
                  phoneError = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aboutMeController,
              decoration: const InputDecoration(
                labelText: 'About Me',
                border: OutlineInputBorder(),
                filled: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Update', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16), // Add spacing between buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to ResetPasswordScreen or trigger reset password logic
                  Navigator.pushNamed(context,
                      '/edit_resetpassword'); // Replace with your route
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: const BorderSide(color: Colors.red), // Red border color
                  backgroundColor: Colors.red, // Red background color
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(
                      fontSize: 16, color: Colors.white), // White text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
