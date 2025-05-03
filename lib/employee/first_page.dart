import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:serategna/employee/applications_page.dart';
import 'package:serategna/employee/home_page.dart';
import 'package:serategna/employee/notifications_page.dart';
import 'package:serategna/employee/profile_page.dart';
import 'package:serategna/firebase/firebaseauth.dart';

class EmployeeFirstPage extends StatefulWidget {
  const EmployeeFirstPage({super.key});

  @override
  State<EmployeeFirstPage> createState() => _EmployeeFirstPageState();
}

class _EmployeeFirstPageState extends State<EmployeeFirstPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const ApplicationsPage(),
    const NotificationsPage(),
    const Profile(),
  ];

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      await _markNotificationsAsRead();
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final userId = Firebaseauth.getCurrentUser()?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('status', isEqualTo: 'new')
          .get();

      for (final doc in snapshot.docs) {
        doc.reference.update({'status': 'read'});
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  int _newNotificationCount = 0;
  @override
  void initState() {
    super.initState();
    _listenToNewNotifications();
  }

  void _listenToNewNotifications() {
    final userId = Firebaseauth.getCurrentUser()?.uid;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('status', isEqualTo: 'new')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _newNotificationCount = snapshot.docs.length;
        });
      });
    }
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'applications',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notification_add),
                if (_newNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_newNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
