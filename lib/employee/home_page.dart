import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serategna/employee/job_detail.dart';
import 'package:serategna/employeer/company_detail.dart';
import 'package:serategna/firebase/firebasefirestore.dart';
import 'package:serategna/firebase/firestore_user.dart';
import 'package:serategna/skills.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> userSkills = [];
  final List<String> expandedSkills = [];

  void _fetchUserSkills() async {
    List<String> skills = await FirestoreUser.getUserSkills();
    setState(() {
      userSkills = skills;
    });
  }

  @override
  void initState() {
    _fetchUserSkills();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreJobs.getJobStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No jobs found'));
                }

                var allJobs = snapshot.data!.docs.map((doc) {
                  var jobData = doc.data() as Map<String, dynamic>;
                  jobData['jobId'] = doc.id; // Add jobId to the job data
                  return jobData;
                }).toList();

                List<Map<String, dynamic>> matchedJobs = [];
                List<Map<String, dynamic>> otherJobs = [];
                List<Map<String, dynamic>> relatedJobs = [];
                List<Map<String, dynamic>> matchedExpiredJobs = [];
                List<Map<String, dynamic>> relatedExpiredJobs = [];
                List<Map<String, dynamic>> otherExpiredJobs = [];
                final now = DateTime.now();
                for (var skill in userSkills) {
                  if (relatedSkills.containsKey(skill)) {
                    expandedSkills.addAll(relatedSkills[skill]!);
                  }
                }

                for (var job in allJobs) {
                  Timestamp? deadlineTimestamp = job['deadline'];
                  DateTime deadline = DateTime.now();
                  if (deadlineTimestamp != null) {
                    deadline = deadlineTimestamp.toDate();
                    log(deadline.toString());
                  }

                  bool matchesSkill = userSkills.any((skill) =>
                      job['title']
                          .toLowerCase()
                          .contains(skill.toLowerCase()) ||
                      job['description']
                          .toLowerCase()
                          .contains(skill.toLowerCase()));
                  bool relatesSkill = expandedSkills.any((skill) =>
                      job['title']
                          .toLowerCase()
                          .contains(skill.toLowerCase()) ||
                      job['description']
                          .toLowerCase()
                          .contains(skill.toLowerCase()));
                  if (matchesSkill && deadline.isBefore(now)) {
                    matchedExpiredJobs.add(job);
                  } else if (matchesSkill && deadline.isAfter(now)) {
                    matchedJobs.add(job);
                  } else if (relatesSkill && deadline.isBefore(now)) {
                    relatedExpiredJobs.add(job);
                  } else if (relatesSkill && deadline.isAfter(now)) {
                    relatedJobs.add(job);
                  } else if (deadline.isAfter(now)) {
                    relatedJobs.add(job);
                  } else {
                    otherExpiredJobs.add(job);
                  }
                }
                matchedJobs.shuffle();
                otherJobs.shuffle();
                matchedExpiredJobs.shuffle();
                log(matchedExpiredJobs.toString());
                List<Map<String, dynamic>> jobsToDisplay = [
                  ...matchedJobs,
                  ...relatedJobs,
                  ...otherJobs,
                  ...matchedExpiredJobs,
                  ...relatedExpiredJobs,
                  ...otherExpiredJobs,
                ];

                jobsToDisplay = jobsToDisplay.where((job) {
                  return job['title'].toLowerCase().contains(_searchQuery) ||
                      job['companyName'].toLowerCase().contains(_searchQuery) ||
                      job['location'].toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: jobsToDisplay.length,
                  itemBuilder: (context, index) {
                    var jobData = jobsToDisplay[index];
                    String companyId = jobData['companyId'] ?? "";

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image(
                                    image: (jobData['logo'] != null &&
                                            jobData['logo']
                                                .toString()
                                                .isNotEmpty)
                                        ? NetworkImage(jobData['logo'])
                                        : const AssetImage(
                                                'assets/images/black_logo_transparent-removebg-preview.png')
                                            as ImageProvider,
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CompanyJobsPage(
                                          companyId: companyId,
                                          companyName: jobData['companyName'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    jobData['companyName']!,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            Text('Title: ${jobData['title']!}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Job Type: ${jobData['jobType']!}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Location: ${jobData['location']!}',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(jobData['description']!,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
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
                                            )),
                                  );
                                },
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
