import 'package:final_project/screens/all_map_screen.dart';
import 'package:final_project/screens/eventlist_screen.dart';
import 'package:final_project/screens/home_screen.dart';
import 'package:final_project/screens/profile_screen.dart';
import 'package:flutter/material.dart';

class NavbarScreen extends StatefulWidget {
  const NavbarScreen({super.key});

  @override
  State<NavbarScreen> createState() => _NavbarScreenState();
}

class _NavbarScreenState extends State<NavbarScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const HomeScreen(),
    const EventListScreen(),
    const AllMapScreen(
      title: '',
      location: '',
      date: '',
      time: '',
      description: '',
      ticketPrice: 0.0,
      isPastEvent: false,
      hostName: '',
      eventId: '',
      latitude: 14.5995,
      longitude: 120.9842,
      userId: '',
      image: '',
      eventTarget: '',
    ),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, -2),
            ),
          ],
        ),
          child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
             icon: Icon(Icons.event),
              label: "Tickets"
            
                     
                    ),  
                
            
            const BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: "Map",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
          ),
        ),
      ),
    );
  }
}
