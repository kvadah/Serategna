import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:serategna/employee/home_page.dart';
import 'package:serategna/employeer/add_job.dart';
import 'package:serategna/employeer/aplicants_page.dart';
import 'package:serategna/employeer/profile_page.dart';
import 'package:serategna/firebase/firebaseauth.dart';

class FirstEmployerPage extends StatefulWidget {
  const FirstEmployerPage({super.key});

  @override
  State<FirstEmployerPage> createState() => _FirstEmployerPageState();
}

class _FirstEmployerPageState extends State<FirstEmployerPage> {
  int _selectedIndex = 0;
  int _newApplicants = 0;
  final List<StreamSubscription> _subscriptions = [];

  final List<Widget> _screens = [
    const HomePage(),
    const ApplicantsPage(),
    const AddJobPage(),
    const ProfilePage(),
  ];
 

  void listenToNewApplicantsNumber() async {
    String companyId = Firebaseauth.getCurrentUser()!.uid;

    final Map<String, int> jobApplicantCounts = {};

    final jobsSub = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('jobsPost')
        .snapshots()
        .listen((jobPostsSnapshot) {
      for (var jobDoc in jobPostsSnapshot.docs) {
        String jobId = jobDoc.id;

        final applicantSub = FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .collection('applicants')
            .where('status', isEqualTo: 'new')
            .snapshots()
            .listen((applicantsSnapshot) {
          jobApplicantCounts[jobId] = applicantsSnapshot.docs.length;

          setState(() {
            _newApplicants =
                jobApplicantCounts.values.fold(0, (sum, val) => sum + val);
          });
        });

        _subscriptions.add(applicantSub);
      }
    });

    _subscriptions.add(jobsSub);
  }

  @override
  void initState() {
    super.initState();
    listenToNewApplicantsNumber();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, 
        unselectedItemColor: Colors.grey, 
        backgroundColor:
            Colors.white,
        type: BottomNavigationBarType.fixed, 
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.history),
                if (_newApplicants > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_newApplicants',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Applicants',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Post Job',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
