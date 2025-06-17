import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serategna/employeer/applicant_review_page.dart';
import 'package:serategna/firebase/firestore_user.dart'; // For formatting date

class ApplicantsListPage extends StatelessWidget {
  final String jobId;

  const ApplicantsListPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants",style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreUser.getJobApplicantsStreamWithProfiles(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No applicants yet."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var applicantData = snapshot.data![index];

              var applicantId = applicantData['uid'];

              String applicantName = applicantData['name'] ?? 'Unknown';
              String email = applicantData['Email'] ?? 'Unknown';
              String phone = applicantData['phoneNo'] ?? 'Unknown';
              String about = applicantData['about'] ?? 'No details';
              String? imageUrl = applicantData['imageUr'];
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
                                applicantId: applicantId,
                                jobId: jobId, userProfile: imageUrl,
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
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
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
