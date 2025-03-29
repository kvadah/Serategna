import 'package:flutter/material.dart';
import 'package:serategna/employee/home_page.dart';
import 'package:serategna/employeer/add_job.dart';
import 'package:serategna/employeer/aplicants_page.dart';
import 'package:serategna/employeer/profile_page.dart';

class FirstEmployerPage extends StatefulWidget {
  const FirstEmployerPage({super.key});

  @override
  State<FirstEmployerPage> createState() => _FirstEmployerPageState();
}

class _FirstEmployerPageState extends State<FirstEmployerPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const ApplicantsPage(),
    const AddJobPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Highlighted item color
        unselectedItemColor: Colors.grey, // Make unselected items visible
        backgroundColor:
            Colors.white, // Ensure background isn't blending with text
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Applicants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Post Job',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
