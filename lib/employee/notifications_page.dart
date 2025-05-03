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
  }

  String _formatDateForGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy').format(notificationDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text("User not logged in."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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

          // Group notifications by date
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in notifications) {
            var data = doc.data() as Map<String, dynamic>;
            var timestamp = (data['time'] as Timestamp).toDate();

            String key = _formatDateForGroup(timestamp);
            if (!grouped.containsKey(key)) {
              grouped[key] = [];
            }
            grouped[key]!.add(data);
          }

          return ListView(
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...entry.value.map((data) {
                    var message = data['message'] ?? '';
                    var status = data['status'] ?? 'read';
                    var timestamp = (data['time'] as Timestamp).toDate();
                    var formattedTime = DateFormat('hh:mm a').format(timestamp);

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications_active,
                          color: status == 'new' ? Colors.red : Colors.grey,
                        ),
                        title: Text(message),
                        subtitle: Text(formattedTime),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
