import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serategna/firebase/firestore_user.dart'; // where your fetchApplicationDetails function lives

class ApplicationDetailsPage extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailsPage({super.key, required this.applicationId});

  @override
  State<ApplicationDetailsPage> createState() => _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState extends State<ApplicationDetailsPage> {
  late Future<Map<String, dynamic>?> _applicationFuture;

  @override
  void initState() {
    super.initState();
    _applicationFuture =
        FirestoreUser.fetchApplicationDetails(widget.applicationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _applicationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Application not found.'));
          }

          final data = snapshot.data!;
          final profileImageUrl = data['logo'] ?? '';
          final companyName = data['company'] ?? 'Unknown';
          final jobTitle = data['title'] ?? 'Unknown';
          final status = data['status'] ?? 'PENDING';
          final Timestamp? appliedAtTimestamp = data['appliedAt'];
          final String appliedAt = appliedAtTimestamp != null
              ? DateFormat('dd/MM/yyyy').format(appliedAtTimestamp.toDate())
              : 'Unknown';
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Company Name
                  Text(
                    companyName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Job Title
                  Text(
                    'Job Title: $jobTitle',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'status: $status'.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Message From the Company",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data['message'] ?? 'no message.',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Applied Date
                  Text(
                    'Applied on: $appliedAt',
                    style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
