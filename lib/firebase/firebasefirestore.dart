import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Firestore {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveUserData(String fullName, String phone, String email,
      String userType, User? user) async {
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'phone': phone,
          'email': email,
          'userType':
              userType, // Store whether the user is Employee or Employer
        });
        log("User data saved successfully.");
      } catch (e) {
        log("Error saving user data: $e");
      }
    }
  }

  static Future<void> addJob(
    String Companyname,
    String title,
    String location,
    String description,
  ) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        String companyName = userData['fullName'];
        await _firestore.collection('jobs').add({
          'title': title,
          'companyName': Companyname,
          'location': location,
          'description': description,
          'totalApplicants': 0,
          'status': 'active',
          'timeStamp': FieldValue.serverTimestamp(),
        });
        // Refresh job list
      }
    }
  }

  static Future<void> addJobToCompanyAndJobsCollection(User? user, String title,
      String location, String description, DateTime? deadline) async {
    String companyName = 'Anonymous';
    try {
      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          companyName = userData['fullName'];
        }
      }
      // Create a new job document in the 'jobs' collection
      DocumentReference jobRef =
          await FirebaseFirestore.instance.collection('jobs').add({
        'companyName': companyName,
        'title': title,
        'description': description,
        'deadline':
            deadline?.toIso8601String(), // Save the deadline as ISO8601 string

        'location': location,
        'totalApplicants': 0,
        'timeStamp': FieldValue.serverTimestamp(), // Optional, for timestamp
      });

      // Add the job to the 'jobsPost' subcollection of the company
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('jobsPost')
          .doc(jobRef.id) // Use the jobRef.id to ensure the same job is added
          .set({
        'companyName': companyName,
        'title': title,
        'description': description,
        'location': location,
        'totalApplicants': 0,
        'timeStamp': FieldValue.serverTimestamp(),
        // Store the job ID for reference
      });

      print('Job added successfully');
    } catch (e) {
      print('Error adding job: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserData(User? user) async {
    if (user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          return snapshot.data() as Map<String, dynamic>;
        } else {
          log("User data not found.");
          return null;
        }
      } catch (e) {
        log("Error retrieving user data: $e");
        return null;
      }
    } else {
      log("No user is currently logged in.");
      return null;
    }
  }

  static Future<List<String>> getUserSkills() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() ?? {};
        return List<String>.from(data['skills'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching skills: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserDocument(User? user) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection("users").doc(user?.uid).get();

      if (userSnapshot.exists) {
        return userSnapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  static Future<bool> applyForJob(
      String userId, String jobId, String about) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Reference to the applicant's document inside the job's applicants subcollection
      DocumentReference applicantRef = firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applicants')
          .doc(userId);

      // Check if the user has already applied
      DocumentSnapshot existingApplication = await applicantRef.get();
      if (existingApplication.exists) {
        print("You have already applied for this job.");
        return true; // Return true to indicate duplicate application
      }

      // Fetch user details
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception("User not found");

      String name = userDoc.get('fullName');
      String email = userDoc.get('email');
      String phone = userDoc.get('phone');

      // Fetch job details
      DocumentSnapshot jobDoc =
          await firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) throw Exception("Job not found");

      String company = jobDoc.get('companyName');
      String title = jobDoc.get('title');
      String description = jobDoc.get('description');

      // Firestore batch write to ensure atomic operation
      WriteBatch batch = firestore.batch();

      // Add applicant to job's applicants subcollection
      batch.set(applicantRef, {
        'fullName': name,
        'email': email,
        'phone': phone,
        'about': about,
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Add job to user's myApplications subcollection
      DocumentReference applicationRef = firestore
          .collection('users')
          .doc(userId)
          .collection('myApplications')
          .doc(jobId);

      batch.set(applicationRef, {
        'company': company,
        'title': title,
        'description': description,
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();
      print("Application successful!");
      // Return false to indicate a successful application
    } catch (e) {
      print("Error applying for job: $e");
      // Return true to indicate an error
    }
    return false;
  }
}
