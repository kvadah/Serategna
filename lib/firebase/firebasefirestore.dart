import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreJobs {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot> getJobStream() {
    return FirebaseFirestore.instance.collection('jobs').snapshots();
  }

  static Future<void> addJob(
    String companyName,
    String title,
    String location,
    String description,
  ) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        //String companyName = userData['fullName'];
        await _firestore.collection('jobs').add({
          'title': title,
          'companyName': companyName,
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
            await _firestore.collection('companies').doc(user.uid).get();
        if (userData.exists) {
          companyName = userData['fullName'];
        }
      }
      // Create a new job document in the 'jobs' collection
      DocumentReference jobRef =
          await FirebaseFirestore.instance.collection('jobs').add({
        'companyName': companyName,
        'title': title,
        'companyId':user!.uid,
        'description': description,
        'deadline':
            deadline?.toIso8601String(), // Save the deadline as ISO8601 string

        'location': location,
        'totalApplicants': 0,
        'timeStamp': FieldValue.serverTimestamp(), // Optional, for timestamp
      });

      // Add the job to the 'jobsPost' subcollection of the company
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.uid)
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

      log('Job added successfully');
    } catch (e) {
      log('Error adding job: $e');
    }
  }

  /*Future<List<String>> removeSkill(String skill) {
    User? user = Firebaseauth.getCurrentUser();
    if (user == null) return;

    _firestore.collection("users").doc(user!.uid).update({
      "skills": FieldValue.arrayRemove([skill])
    });
  }*/

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
        log("You have already applied for this job.");
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
      log("Application successful!");
      // Return false to indicate a successful application
    } catch (e) {
      log("Error applying for job: $e");
      // Return true to indicate an error
    }
    return false;
  }

  static Stream<QuerySnapshot> getCompaniesPostStream(String userId) {
    // Access the user's document in the 'users' collection and fetch their 'myApplications' subcollection
    return FirebaseFirestore.instance
        .collection('companies') // Reference to the 'users' collection
        .doc(userId) // Document for the current user
        .collection('jobsPost') // Subcollection with the user's applications
        .snapshots(); // Stream of documents in that subcollection
  }
}
