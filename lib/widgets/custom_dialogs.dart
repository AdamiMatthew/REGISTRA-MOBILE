import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';


class CustomDialogs {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  static void customOptionDialog(BuildContext context,
      {required String title,
      required String content,
      required Function onYes}) {
    AlertDialog alertDialog = AlertDialog(
      title: Text(title, style: TextStyle(fontSize: 30.sp)),
      content: Text(content),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onYes();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Yes'),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
  }

  static void customShowImageDialog(BuildContext context,
      {required String imageUrl}) {
    AlertDialog alertDialog = AlertDialog(
      content: SizedBox(
        height: 300.h,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                CircularProgressIndicator(
              color: Colors.blue,
              value: downloadProgress.progress,
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.error,
              size: 100.sp,
            ),
          ),
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
    
  }
  static void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
              
            ),
          ],
        );
      },
    );
  }
  

  static void showSuccessRegisterDialog(BuildContext context, String message, {VoidCallback? onConfirmed}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onConfirmed != null) {
                onConfirmed();
              }
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}

  


