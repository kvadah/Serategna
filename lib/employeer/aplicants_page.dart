import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:serategna/employeer/applicants_list.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firebasefirestore.dart';
import 'package:serategna/firebase/firestore_user.dart';

class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  late Stream<QuerySnapshot> _applicationsStream;

  // Fetch the user's applications from Firestore
  void _fetchUserApplicationsStream() {
  User? user = Firebaseauth.getCurrentUser();
  if (user != null) {
    _applicationsStream = FirestoreJobs.getCompaniesPostStream(user.uid);
  } else {
    log("User is null. Unable to fetch applications.");
  }
}


  @override
  void initState() {
    super.initState();
    _fetchUserApplicationsStream(); // Set the stream for user applications
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants',
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
            var jobData = doc.data() as Map<String, dynamic>;
            jobData['jobid'] = doc.id; // Add applicationId
            return jobData;
          }).toList();

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              var jobData = applications[index];

              // Format the appliedAt date
              String appliedAtDate = 'Unknown';
              if (jobData['timeStamp'] != null) {
                Timestamp timestamp = jobData['timeStamp'];
                DateTime dateTime = timestamp.toDate();
                appliedAtDate = DateFormat('dd/MM/yyyy').format(dateTime);
              }

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 20.0, bottom: 10, left: 8, top: 8),
                  child: InkWell(
                    onTap: () {
                      log(jobData['jobid']);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ApplicantsListPage(jobId: jobData['jobid'])));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Title: ${jobData['title'] ?? 'Unknown'}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(
                            'description: ${jobData['description'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 14)),
                        //const SizedBox(height: 8),
                        /*Text(jobData['description'] ?? 'No description',
                            maxLines: 2, overflow: TextOverflow.ellipsis),*/
                        const SizedBox(height: 10),
                        Text('Posted at: $appliedAtDate',
                            style: const TextStyle(
                                fontSize: 14, fontStyle: FontStyle.italic)),
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
