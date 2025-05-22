import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:serategna/employee/job_detail.dart';

class CompanyJobsPage extends StatefulWidget {
  final String companyId;
  final String companyName;
  const CompanyJobsPage(
      {Key? key, required this.companyId, required this.companyName})
      : super(key: key);

  @override
  State<CompanyJobsPage> createState() => _CompanyJobsPageState();
}

class _CompanyJobsPageState extends State<CompanyJobsPage> {
  Map<String, dynamic>? companyData;
  Stream<QuerySnapshot> getJobPostsStream() {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('jobsPost')
        .snapshots();
  }

  Future<void> _fetchCompanyData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("companies")
          .doc(widget.companyId)
          .get();
      if (doc.exists) {
        setState(() {
          companyData = doc.data() as Map<String, dynamic>?;
        });
      }
    } catch (error) {
      log("Error fetching company data: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
      ),
      body: companyData == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: getJobPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final jobs = snapshot.data?.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['jobId'] = doc.id;
                      return data;
                    }).toList() ??
                    [];

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // ✅ Company Info Header
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: companyData!["logo"] != null
                                ? NetworkImage(companyData!["logo"])
                                : null,
                            child: companyData!["logo"] == null
                                ? const Icon(Icons.business, size: 60)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${companyData?["fullName"] ?? "No Name"}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${companyData?["about"] ?? "No About"}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text(
                            "Jobs",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // ✅ Job Cards
                    if (jobs.isEmpty)
                      const Center(child: Text('No job posts found.')),
                    for (var jobData in jobs)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Text('Title: ${jobData['title'] ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text('Location: ${jobData['location'] ?? ''}',
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(
                                jobData['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    log(jobData['jobId']);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => JobDetailsPage(
                                          job: jobData,
                                          jobId: jobData['jobId'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
