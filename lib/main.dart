import 'package:final_project/admin_screens/admin_home_screen.dart';
import 'package:final_project/firebase_Api/firebase_api.dart';
import 'package:final_project/firebase_options.dart';
import 'package:final_project/screens/edit_resetpassword.dart';
import 'package:final_project/screens/eventlist_screen.dart';
import 'package:final_project/screens/home_screen.dart';
import 'package:final_project/screens/navbar_screen.dart';
import 'package:final_project/screens/profile_screen.dart';
import 'package:final_project/screens/register_screen.dart';
import 'package:final_project/screens/resetpassword_screen.dart';
import 'package:final_project/screens/detail_screen.dart';
import 'package:final_project/screens/ticket_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:final_project/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // print('User granted permission: ${settings.authorizationStatus}');

  await messaging.subscribeToTopic("allUsers");
  // print('Subscribed to topic: allUsers');

  await FirebaseApi().initNotifications();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: FirebaseApi.navigatorKey, // ✅ global key for navigation
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/eventlist': (context) => const EventListScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/resetpassword': (context) => const ResetPasswordScreen(),
        '/navbar': (context) => const NavbarScreen(),
        '/edit_resetpassword': (context) => const EditResetpassword(),
        '/admin_homescreen': (context) => const AdminHomeScreen(),
        
        '/event-detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DetailScreen(
            eventId: args['eventId'] ?? '',
            title: args['title'] ?? '',
            location: args['location'] ?? '',
            date: args['date'] ?? '',
            time: args['time'] ?? '',
            description: args['description'] ?? '',
            ticketPrice: double.tryParse(args['ticketPrice'].toString()) ?? 0.0,
            isPastEvent: args['isPastEvent'] == 'true' || args['isPastEvent'] == true,
            hostName: args['hostName'] ?? '',
            latitude: double.tryParse(args['latitude'].toString()) ?? 0.0,
            longitude: double.tryParse(args['longitude'].toString()) ?? 0.0,
            userId: args['userId'] ?? '',
            image: args['image'] ?? '',
            eventTarget: args['eventTarget'] ?? '',
          );
        },
        '/ticket-screen': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TicketScreen(
            title: args['title'] ?? '',
            location: args['location'] ?? '',
            ticketQR: args['ticketQR'] ?? '',
            registrationsId: args['registrationsId'] ?? '',
            image: args['image'] ?? '',
            eventDate: args['eventDate'] ?? '',
            eventTime: args['eventTime'] ?? '',
          );
        },
      },
    );
  }
}
