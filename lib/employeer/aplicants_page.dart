import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:serategna/employeer/applicants_list.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firebasefirestore.dart';

class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  // Fetch the user's applications from Firestore
  List<Map<String, dynamic>> rawJobs = [];
  bool isloading = true;

  Future<void> loadApplications() async {
    String userId = Firebaseauth.getCurrentUser()!.uid;
    final jobs = await FirestoreJobs.getCompaniesPosts(userId);
    log(jobs.toString()); // Your own function

    setState(() {
      rawJobs = jobs;
      isloading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isloading
          ? const Center(child: CircularProgressIndicator())
          : rawJobs.isEmpty
              ? const Center(child: Text('No applications found.'))
              : ListView.builder(
                  itemCount: rawJobs.length,
                  itemBuilder: (context, index) {
                    var jobData = rawJobs[index];

                    // Format the appliedAt date
                    String appliedAtDate = 'Unknown';
                    if (jobData['timeStamp'] != null) {
                      Timestamp timestamp = jobData['timeStamp'];
                      DateTime dateTime = timestamp.toDate();
                      appliedAtDate = DateFormat('dd/MM/yyyy').format(dateTime);
                    }

                    return StreamBuilder(
                        stream: FirestoreJobs.listenToNewApplicantsForJob(
                            jobData['jobid']),
                        builder: (context, snapshot) {
                          int newApplicants = snapshot.data ?? 0;

                          return Stack(children: [
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 20.0, bottom: 10, left: 8, top: 8),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ApplicantsListPage(
                                                  jobId: jobData['jobid']),
                                        ),
                                      ).then((_) {
                                        FirestoreJobs
                                            .changeApplicantStatusAsRead(
                                                jobData['jobid']);
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Title: ${jobData['title'] ?? 'Unknown'}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            jobData['description'] ??
                                                'No description',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 10),
                                        Text('Posted at: $appliedAtDate',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if ((newApplicants) > 0)
                              Positioned(
                                right: 12,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$newApplicants',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ]);
                        });
                  },
                ),
    );
  }
}
