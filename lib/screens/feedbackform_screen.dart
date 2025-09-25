import 'package:final_project/screens/certificate_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/config.dart';

class FeedbackForm extends StatefulWidget {
  final String eventId;
  final String userId;

  const FeedbackForm({super.key, required this.eventId, required this.userId});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  late Future<Map<String, dynamic>> feedbackFormFuture;
  final Map<dynamic, dynamic> answers = {};
  List<dynamic> questions = [];
  String? formId;
  bool isSubmitting = false;
  bool hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    checkFeedbackSubmission();
    feedbackFormFuture = fetchFeedbackForm(widget.eventId);
  }

  Future<void> checkFeedbackSubmission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        //print('No token found');
        return;
      }

      final response = await http.get(
        Uri.parse('$feedbackCheck?eventId=${widget.eventId}&userId=${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      //print('Debug: Check submission response status: ${response.statusCode}');
      //print('Debug: Check submission response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hasSubmitted = data['hasSubmitted'] ?? false;
        });

        if (hasSubmitted) {
          // If feedback is already submitted, navigate to certificate screen
          Future.delayed(Duration.zero, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CertificateScreen(
                  eventId: widget.eventId,
                  userId: widget.userId,
                ),
              ),
            );
          });
        }
      } else {
        //print('Error checking submission status: ${response.body}');
      }
    } catch (e) {
      //print('Error checking submission status: $e');
    }
  }

  Future<Map<String, dynamic>> fetchFeedbackForm(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$feedbackGet/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        questions = data['questions'] ?? [];
        formId = data['_id'];
        
        // Check if there are no questions in the feedback form
        if (questions.isEmpty) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('No Feedback Form'),
              content: const Text('Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          throw Exception('No feedback form available');
        }
        
        return data;
      } else if (response.statusCode == 404) {
        // No feedback form exists for this event
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('No Feedback Available'),
            content: const Text('There is currently no feedback form for this event.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        throw Exception('No feedback form found (404)');
      } else {
        throw Exception('Failed to load feedback form: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching feedback form: $e');
    }
  }

  bool validateAnswers() {
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final type = question['type'];

      if (type == 'Likert') {
        final statements = (question['statements'] ?? []) as List;
        for (int j = 0; j < statements.length; j++) {
          String key = "$i-$j";
          if (answers[key] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please answer all Likert scale questions')),
            );
            return false;
          }
        }
      } else if (answers[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer all questions')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> submitFeedback() async {
    if (!validateAnswers()) {
      return;
    }

    if (formId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback form ID not found')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      // Debug //prints
      //print('Debug: Submitting feedback to URL: $feedbackSubmit/$formId');
      //print('Debug: User ID: ${widget.userId}');
      //print('Debug: Form ID: $formId');

      List<Map<String, dynamic>> structuredAnswers = [];

      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final type = question['type'];

        if (type == 'Likert') {
          List<Map<String, dynamic>> likertResponses = [];
          final statements = (question['statements'] ?? []) as List;

          for (int j = 0; j < statements.length; j++) {
            String key = "$i-$j";
            final selectedValue = answers[key];
            if (selectedValue != null) {
              likertResponses.add({
                "statement": statements[j],
                "value": selectedValue,
              });
            }
          }

          structuredAnswers.add({
            "questionText": question['text'] ?? question['label'] ?? 'Likert Question',
            "answers": likertResponses
          });
        } else {
          if (answers[i] != null) {
            structuredAnswers.add({
              "questionText": question['text'] ?? question['label'] ?? 'Untitled Question',
              "answer": answers[i]
            });
          }
        }
      }

      // Match the backend's expected structure
      final requestBody = {
        'answers': structuredAnswers,
        'userId': widget.userId,
      };

      //print('Debug: Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$feedbackSubmit/$formId'), // formId is sent in URL params
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      //print('Debug: API Response Status: ${response.statusCode}');
      //print('Debug: API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Feedback submitted successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CertificateScreen(
                        eventId: widget.eventId,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${errorData['message'] ?? response.body}')),
        );
      }
    } catch (e) {
      //print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Widget buildQuestion(Map<String, dynamic> question, int index) {
    final String type = question['type'] ?? '';
    final String label =
        question['label'] ?? question['text'] ?? 'Untitled Question';
    final List<dynamic> options = question['options'] ?? [];
    final List<dynamic> statements = question['statements'] ?? [];

    switch (type) {
      case 'Choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(options.length, (i) {
                final option = options[i];
                return ChoiceChip(
                  label: Text(option),
                  selected: answers[index] == option,
                  onSelected: (selected) {
                    setState(() {
                      answers[index] = selected ? option : null;
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: answers[index] == option
                        ? Colors.blue.shade900
                        : Colors.black87,
                    fontWeight: answers[index] == option
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                      color: answers[index] == option
                          ? Colors.blue
                          : Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 1,
                );
              }),
            ),
          ],
        );

      case 'Text':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) {
                setState(() {
                  answers[index] = value;
                });
              },
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter your answer",
                filled: true,
                fillColor: Colors.blue.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
              ),
            ),
          ],
        );

      case 'Rating':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      answers[index] = i + 1;
                    });
                  },
                  icon: Icon(
                    Icons.star,
                    size: 36,
                    color: (answers[index] ?? 0) >= i + 1
                        ? Colors.amber.shade700
                        : Colors.grey.shade400,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 24,
                );
              }),
            ),
          ],
        );

      case 'Likert':
        final likertOptions = options.isNotEmpty
            ? options
            : [
                'Very Unsatisfied',
                'Unsatisfied',
                'Neutral',
                'Satisfied',
                'Very Satisfied'
              ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 120),
                ...likertOptions.map((option) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            ...statements.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final rowLabel = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(rowLabel,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87)),
                    ),
                    ...List.generate(likertOptions.length, (colIndex) {
                      final key = '$index-$rowIndex';
                      final value = colIndex + 1;
                      return Expanded(
                        child: Center(
                          child: Radio<int>(
                            value: value,
                            groupValue: answers[key],
                            onChanged: (selectedValue) {
                              setState(() {
                                answers[key] = selectedValue;
                              });
                            },
                            activeColor: Colors.blue.shade700,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            const Divider(height: 20, thickness: 1),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Feedback',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: feedbackFormFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load the feedback form.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              feedbackFormFuture = fetchFeedbackForm(widget.eventId);
                            });
                          },
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          } else {
            final form = snapshot.data!;
            final title = form['title'] ?? 'Feedback Form';

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        ...questions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final question = entry.value as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              margin: EdgeInsets.zero,
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: buildQuestion(question, index)),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text("SUBMIT",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
