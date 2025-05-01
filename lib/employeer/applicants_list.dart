import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serategna/employeer/applicant_review_page.dart'; // For formatting date

class ApplicantsListPage extends StatelessWidget {
  final String jobId;

  const ApplicantsListPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("jobs")
            .doc(jobId)
            .collection("applicants")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No applicants yet."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var applicantData = doc.data() as Map<String, dynamic>;
              var applicantId = doc.id;

              String applicantName = applicantData['fullName'] ?? 'Unknown';
              String email = applicantData['email'] ?? 'Unknown';
              String phone = applicantData['phone'] ?? 'Unknown';
              String about = applicantData['about'] ?? 'No details';
              String appliedAtDate = '';
              Timestamp timestamp = applicantData['appliedAt'];
              DateTime dateTime = timestamp.toDate();
              appliedAtDate = DateFormat('dd/MM/yyyy').format(dateTime);

              return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ApplicantReviewPage(
                                applicationId: applicantId,
                                jobId: jobId,
                              )));
                  log(applicantId);
                   log(jobId);
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(11.0),
                    child: Column(
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
                              applicantName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Text('Email: $email',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Phone: $phone',
                            style: const TextStyle(fontSize: 14)),
                        Text('About: $about',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        Text('Applied at: $appliedAtDate',
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
