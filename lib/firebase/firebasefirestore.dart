import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreJobs {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot> getJobStream() {
    return _firestore.collection('jobs').snapshots();
  }

  static Future<void> addJobToCompanyAndJobsCollection(
      User? user,
      String title,
      String jobType,
      String location,
      String description,
      DateTime? deadline) async {
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
        'jobType': jobType,
        'companyId': user!.uid,
        'description': description,
        'deadline': deadline != null ? Timestamp.fromDate(deadline) : null,
        'location': location,
        'totalApplicants': 0,
        'timeStamp': FieldValue.serverTimestamp(), // Optional, for timestamp
      });

      // Add the job to the 'jobsPost' subcollection of the company
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.uid)
          .collection('jobsPost')
          .doc(jobRef.id)
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

  static Future<bool> applyForJob(
      String userId, String jobId, String cvUrl,String cvName, String about) async {
    try {
      // Reference to the applicant's document inside the job's applicants subcollection
      DocumentReference applicantRef = _firestore
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
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception("User not found");

      // Fetch job details
      DocumentSnapshot jobDoc =
          await _firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) throw Exception("Job not found");

      String company = jobDoc.get('companyName');
      String title = jobDoc.get('title');
      String description = jobDoc.get('description');

      // Firestore batch write to ensure atomic operation
      WriteBatch batch = _firestore.batch();

      // Add applicant to job's applicants subcollection
      batch.set(applicantRef, {
        'about': about,
        'status': 'new',
        'cvUrl':cvUrl,
        'cvname':cvName,
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Add job to user's myApplications subcollection
      DocumentReference applicationRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('myApplications')
          .doc(jobId);

      batch.set(applicationRef, {
        'company': company,
        'title': title,
        'status': 'Pending',
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

  static Future<List<Map<String, dynamic>>> getCompaniesPosts(
      String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('jobsPost')
        .get();

    // Add jobId to each document data
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['jobid'] = doc.id;
      return data;
    }).toList();
  }

  static Stream<QuerySnapshot> getJobApplicantsStream(String jobId) {
    return _firestore
        .collection("jobs")
        .doc(jobId)
        .collection("applicants")
        .snapshots();
  }

  static Future<Map<String, dynamic>?> getCompanyData(String? uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection("companies").doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (error) {
      log("Error fetching company data: $error");
    }
    return null;
  }

  static Future<void> changeApplicantStatusAsRead(String jobId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applicants')
          .where('status', isEqualTo: 'new')
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }

      // Commit all updates in a single batch
      await batch.commit();
      log('Marked ${snapshot.docs.length} applicants as read.');
    } catch (e) {
      log('Error marking applicants as read: $e');
    }
  }

  static Stream<int> listenToNewApplicantsForJob(String jobId) {
    return _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('applicants')
        .where('status', isEqualTo: 'new')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> saveImageUrlToJobDocument(String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("No user is currently logged in.");
    }

    final userDocRef =
        FirebaseFirestore.instance.collection('companies').doc(user.uid);

    await userDocRef.update({
      'logo': imageUrl,
    });
  }

  static Future<String?> fetchLogoFromCompany(String? companyId) async {
    try {
      if (companyId != null) {
        if (companyId.isEmpty) return null;
        final doc = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .get();
        final data = doc.data();
        if (data != null &&
            data['logo'] != null &&
            data['logo'].toString().isNotEmpty) {
          return data['logo'];
        }
        return null;
      }
    } catch (e) {
      log('Error fetching logo: $e');
      return null;
    }
    return null;
  }
}
