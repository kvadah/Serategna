import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firestore_user.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String? userId;
  int newNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    userId = Firebaseauth.getCurrentUser()?.uid;
    _fetchNewNotificationCount();
  }

  void _fetchNewNotificationCount() async {
    if (userId != null) {
      int count = await FirestoreUser.getUnreadNotificationCount(userId!);
      setState(() {
        newNotificationCount = count;
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text("User not logged in."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (newNotificationCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 12),
              child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 12,
                child: Text(
                  newNotificationCount.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreUser.getUserNotificationsStream(userId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications."));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var data = notifications[index].data() as Map<String, dynamic>;
              var message = data['message'] ?? '';
              var status = data['status'] ?? 'read';
              var timestamp = (data['time'] as Timestamp).toDate();
              var formattedTime = DateFormat('dd MMM yyyy – hh:mm a').format(timestamp);

              return ListTile(
                leading: Icon(
                  status == 'new' ? Icons.notifications_active : Icons.notifications_none,
                  color: status == 'new' ? Colors.red : Colors.grey,
                ),
                title: Text(message),
                subtitle: Text(formattedTime),
              );
            },
          );
        },
      ),
    );
  }
}
