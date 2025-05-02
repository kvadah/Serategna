import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApplicationDetailsPage extends StatelessWidget {
  final String applicationId;

  const ApplicationDetailsPage({Key? key, required this.applicationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('applications').doc(applicationId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Application not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String companyName = data['company'] ?? 'N/A';
          final String jobTitle = data['title'] ?? 'N/A';
          final String status = data['status'] ?? 'N/A';
          final String appliedTime = data['appliedAat'] ?? 'N/A';
          final String profileImageUrl = data['profileImageUrl'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Avatar at the top
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 24),

                // Application Details
                DetailRow(label: 'Company Name', value: companyName),
                DetailRow(label: 'Job Title', value: jobTitle),
                DetailRow(label: 'Status', value: status),
                DetailRow(label: 'Applied Time', value: appliedTime),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({Key? key, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
