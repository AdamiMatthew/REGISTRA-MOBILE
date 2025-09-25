import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:final_project/config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';

class CertificateScreen extends StatefulWidget {
  final String eventId;

  const CertificateScreen(
      {super.key, required this.eventId, required String userId});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? certificateTemplate;
  int selectedTemplateIndex = 0;
  String? selectedTemplateUrl;
  String? localPngPath;
  PdfViewerController pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    fetchCertificateTemplates();
  }

  Future<void> fetchCertificateTemplates() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // Replace with your API endpoint
      //print("ewan");

      final response =
          await http.get(Uri.parse('$certTemplate/${widget.eventId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        //print("TEMPLATES: ${data['template']['templates']}");
        if (data['template'] != null &&
            data['template']['templates'] is List &&
            data['template'].isNotEmpty) {
          setState(() {
            certificateTemplate = data['template'];
            selectedTemplateIndex = 0;
            selectedTemplateUrl = data['template']['templates'][0]['url'];
          });
          await _modifyAndSavePdf(selectedTemplateUrl!);
        } else {
          setState(() {
            errorMessage = "No certificate template available";
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to load certificate templates";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _modifyAndSavePdf(String pdfUrl) async {
    try {
      setState(() {
        isLoading = true;
        localPngPath = null;
      });

      // Get user's name from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('fullName') ?? 'User';

      final pngUrl = pdfUrl.replaceAll('.pdf', '.png');

      //print('Downloading PNG from: $pngUrl');
      final response = await http.get(Uri.parse(pngUrl));
      //print('PNG status code: ${response.statusCode}');
      //print('PNG response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          //print('Error: Downloaded PNG body is empty.');
          setState(() {
            errorMessage = "Downloaded certificate image is empty.";
            isLoading = false;
          });
          return;
        }

        // Decode the downloaded image bytes
        ui.Codec codec = await ui.instantiateImageCodec(response.bodyBytes);
        ui.FrameInfo frameInfo = await codec.getNextFrame();
        ui.Image originalImage = frameInfo.image;

        // Create a new canvas to draw on
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Draw the original image onto the canvas
        canvas.drawImage(originalImage, ui.Offset.zero, ui.Paint());

        // Define text style for drawing
        final textStyle = ui.TextStyle(
          fontSize: 48,
          fontWeight: ui.FontWeight.bold,
          color: ui.Color(0xFF2C3E50),
          letterSpacing: 1.2,
          height: 1.2,
          shadows: [
            ui.Shadow(
              offset: ui.Offset(1, 1),
              blurRadius: 2,
              color: ui.Color.fromARGB(66, 0, 0, 0),
            ),
          ],
        );

        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          fontSize: 48,
          fontWeight: ui.FontWeight.bold,
          fontStyle: ui.FontStyle.normal,
          textAlign: ui.TextAlign.center,
        ))
          ..pushStyle(textStyle)
          ..addText(userName)
          ..pop();

        final paragraph = paragraphBuilder.build();
        paragraph.layout(ui.ParagraphConstraints(width: originalImage.width.toDouble()));

        // Calculate text position - slightly above center
        final textX = (originalImage.width - paragraph.width) / 2;
        final textY = (originalImage.height / 2) - (paragraph.height / 2) - 100; // Adjust -100 to lift it up

        canvas.drawParagraph(paragraph, ui.Offset(textX, textY));

        // Convert the canvas content to an image
        final img = await recorder.endRecording().toImage(
              originalImage.width,
              originalImage.height,
            );
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        final newPngBytes = byteData!.buffer.asUint8List();

        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/certificate_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(newPngBytes); // Save the modified PNG bytes
        //print('PNG saved to temporary path: ${file.path}');

        setState(() {
          localPngPath = file.path;
          isLoading = false;
        });
      } else {
        // print(
        //     'Error: Failed to load certificate PNG with status code ${response.statusCode}');
        setState(() {
          errorMessage = "Failed to load certificate PNG";
          isLoading = false;
        });
      }
    } catch (e) {
      //print('Error loading PNG: $e');
      setState(() {
        errorMessage = "Error loading PNG: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _downloadCertificate() async {
    if (localPngPath == null) return;

    try {
      setState(() => isLoading = true);

      // Request necessary permissions
      PermissionStatus photosStatus = await Permission.photos.status;
      PermissionStatus storageStatus = await Permission.storage.status;
      PermissionStatus manageExternalStorageStatus =
          await Permission.manageExternalStorage.status;

      if (photosStatus.isDenied) {
        photosStatus = await Permission.photos.request();
      }
      if (storageStatus.isDenied) {
        storageStatus = await Permission.storage.request();
      }
      if (manageExternalStorageStatus.isDenied) {
        manageExternalStorageStatus =
            await Permission.manageExternalStorage.request();
      }

      //print('Photos permission status: ${photosStatus}');
      //print('Storage permission status: ${storageStatus}');
      // print(
      //     'Manage external storage permission status: ${manageExternalStorageStatus}');

      bool allGranted = photosStatus.isGranted ||
          storageStatus.isGranted ||
          manageExternalStorageStatus.isGranted;

      if (!allGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Storage permission denied. Please enable it in app settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get the Downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        //print('Error: Could not access Downloads directory'); // Debugging
        throw Exception('Could not access Downloads directory');
      }

      //print('Downloads directory: ${directory.path}'); // Debugging

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Certificate_$timestamp.png';
      final newFilePath = path.join(directory.path, fileName);

      //print('New file path: $newFilePath'); // Debugging
      // print(
      //     'Attempting to save to: $newFilePath'); // Debugging: Confirming final save path

      // Copy the file to Downloads directory
      final file = File(localPngPath!);
      if (await file.exists()) {
        //print('Local PDF file exists: ${localPngPath}'); // Debugging
        await file.copy(newFilePath);

        // Save to gallery and notify media scanner
        await Gal.putImage(newFilePath, album: 'Certificates');

        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Certificate saved to Downloads!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fileName,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('OK', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        //print('Local PDF file not found: ${localPngPath}'); // Debugging
        throw Exception('Certificate file not found');
      }
    } catch (e) {
      //print('Error during certificate download: $e'); // Debugging
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = certificateTemplate?['templates'] ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text("Certificate Preview")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : templates.isEmpty
                  ? const Center(
                      child: Text("No certificate template available"))
                  : Column(
                      children: [
                        // Certificate Preview
                        Expanded(
                          child: localPngPath != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(localPngPath!),
                                      fit: BoxFit.contain,
                                    ),
                                    Positioned(
                                      top: 200.0,
                                      left: 0,
                                      right: 0,
                                      child: FutureBuilder<String>(
                                        future: SharedPreferences.getInstance()
                                            .then((prefs) =>
                                                prefs.getString('') ??
                                                ''),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) return const SizedBox();
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 40),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                snapshot.data!,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2C3E50),
                                                  letterSpacing: 1.2,
                                                  height: 1.2,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(1, 1),
                                                      blurRadius: 2,
                                                      color: Colors.black26,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Text(
                                      "No certificate png template available")),
                        ),
                        // Template Thumbnails
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: templates.length,
                            itemBuilder: (context, idx) {
                              final tpl = templates[idx];
                              final pdfUrl = tpl['url'] as String;
                              final pngUrl = pdfUrl
                                  .replaceAll('.pdf', '.png')
                                  .replaceAll('/upload/', '/upload/w_120/');
                              return GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    selectedTemplateIndex = idx;
                                    selectedTemplateUrl = pdfUrl;
                                    isLoading = true;
                                  });
                                  await _modifyAndSavePdf(pdfUrl);
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selectedTemplateIndex == idx
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: CachedNetworkImage(
                                          imageUrl: pngUrl,
                                          width: 90,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.picture_as_pdf,
                                                  size: 40, color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (tpl['templateId'] as String? ?? 'Template').trim(),
                                        style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Download Button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _downloadCertificate();
                            },
                            icon: const Icon(Icons.download),
                            label: const Text(
                              "Download Certificate",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
