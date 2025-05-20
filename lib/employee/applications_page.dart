import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:serategna/employee/Application_Detail.dart';
import 'package:serategna/firebase/firebasefirestore.dart';
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
        return  const Color.fromARGB(255, 248, 227, 35);
      case 'INTERVIEW SCHEDULED':
        return Colors.blueAccent;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.green;
    }
  }
  Future<List<Map<String, dynamic>>> fetchApplicationsWithCompanyId() async {
  final snapshot = await FirestoreUser.getUserApplicationsStream().first;

  return await Future.wait(snapshot.docs.map((doc) async {
    var applicationData = doc.data() as Map<String, dynamic>;
    var jobId = doc.id;

    applicationData['applicationId'] = jobId;

    // Fetch the corresponding job document
    final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    final companyId = jobDoc.data()?['companyId'];

    applicationData['companyId'] = companyId;

    return applicationData;
  }));
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
  future: fetchApplicationsWithCompanyId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No applications found.'));
          }

          var applications = snapshot.data!;
            

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
                                  child: Image(
                                    image: (FirestoreJobs.fetchLogoFromCompany(applicationData['companyId']) != null &&
                                            FirestoreJobs.fetchLogoFromCompany(applicationData['companyId'])
                                                .toString()
                                                .isNotEmpty)
                                        ? NetworkImage(applicationData['logo'])
                                        : const AssetImage(
                                                'assets/images/black_logo_transparent-removebg-preview.png')
                                            as ImageProvider,
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
