import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:serategna/employee/Application_Detail.dart';
import 'package:serategna/firebase/firestore_user.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  late Stream<QuerySnapshot> _applicationsStream;

  @override
  void initState() {
    super.initState();
    _applicationsStream = FirestoreUser
        .getUserApplicationsStream(); // Set the stream for user applications
  }

  Color chooseStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color.fromARGB(255, 223, 203, 26);
      case 'INTERVIEW SCHEDULED':
        return Colors.blueAccent;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _applicationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No applications found.'));
          }

          var applications = snapshot.data!.docs.map((doc) {
            var applicationData = doc.data() as Map<String, dynamic>;
            applicationData['applicationId'] = doc.id; // Add applicationId
            return applicationData;
          }).toList();

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              var applicationData = applications[index];

              // Format the appliedAt date
              String appliedAtDate = 'Unknown';
              if (applicationData['appliedAt'] != null) {
                Timestamp timestamp = applicationData['appliedAt'];
                DateTime dateTime = timestamp.toDate();
                appliedAtDate = DateFormat('dd/MM/yyyy').format(dateTime);
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplicationDetailsPage(
                          applicationId: applicationData['applicationId']),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(11.0),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/black_logo_transparent-removebg-preview.png',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  applicationData['company'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Title: ${applicationData['title'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Applied at: $appliedAtDate',
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        // Status badge
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  chooseStatusColor(applicationData['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              applicationData['status']
                                      ?.toString()
                                      .toUpperCase() ??
                                  'PENDING',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
