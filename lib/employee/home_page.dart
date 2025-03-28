import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serategna/employee/job_detail.dart';
import 'package:serategna/firebase/firebasefirestore.dart';
import 'package:serategna/skills.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late final List<String> userSkills;
  final List<String> expandedSkills = [];

  Stream<QuerySnapshot> _getJobStream() {
    return FirebaseFirestore.instance.collection('jobs').snapshots();
  }

  void _fetchUserSkills() async {
    List<String> skills = await Firestore.getUserSkills();
    setState(() {
      userSkills = skills;
      log(userSkills.toString());
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
              stream: _getJobStream(),
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
                for (var skill in userSkills) {
                  if (relatedSkills.containsKey(skill)) {
                    expandedSkills.addAll(relatedSkills[skill]!);
                  }
                }

                for (var job in allJobs) {
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
                  if (matchesSkill) {
                    matchedJobs.add(job);
                  } else if (relatesSkill) {
                    relatedJobs.add(job);
                  } else {
                    otherJobs.add(job);
                  }
                }
                matchedJobs.shuffle();
                otherJobs.shuffle();

                List<Map<String, dynamic>> jobsToDisplay = [
                  ...matchedJobs,
                  ...relatedJobs,
                  ...otherJobs
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
                                  child: Image.asset(
                                    'assets/images/black_logo_transparent-removebg-preview.png',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {},
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
