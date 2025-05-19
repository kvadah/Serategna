import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:serategna/firebase/firebaseauth.dart';

class FirestoreUser {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //save user data on register
  static Future<void> saveUserData(String fullName, String phone, String email,
      String userType, User? user) async {
    if (user != null) {
      try {
        if (userType == 'Employee') {
          await _firestore.collection('users').doc(user.uid).set({
            'fullName': fullName,
            'phone': phone,
            'email': email,
            'userType':
                userType, // Store whether the user is Employee or Employer
          });
        } else {
          await _firestore.collection('companies').doc(user.uid).set({
            'fullName': fullName,
            'phone': phone,
            'email': email,
            'userType':
                userType, // Store whether the user is Employee or Employer
          });
        }

        log("User data saved successfully.");
      } catch (e) {
        log("Error saving user data: $e");
      }
    }
  }

// additional user data
//let users add bio,skills on register
  static Future<void> saveAdditionalUserData(
      String userId, String bio, List<String> selectedSkills) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'bio': bio,
        'skills': selectedSkills,
      });

      // ignore: empty_catches
    } catch (e) {}
  }

//retrieve user data
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

// get user skills to filter out jobs

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
      log("Error fetching skills: $e");
      return [];
    }
  }

//user document for profile page
  static Future<Map<String, dynamic>?> getUserDocument(User? user) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection("users").doc(user?.uid).get();

      if (userSnapshot.exists) {
        return userSnapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      log("Error fetching user data: $e");
    }
    return null;
  }

  //get users applications list for application page
  static Stream<QuerySnapshot> getUserApplicationsStream() {
    var userId = Firebaseauth.getCurrentUser()?.uid; // Get the current user ID

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('myApplications')
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }

//get a specif application detail for further look
  static Future<Map<String, dynamic>?> fetchApplicationDetails(
      String applicationId) async {
    var userId = Firebaseauth.getCurrentUser()?.uid;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users') // Reference to the 'users' collection
          .doc(userId) // Document for the current user
          .collection('myApplications')
          .doc(applicationId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        log('No application found for ID: $applicationId');
        return null;
      }
    } catch (e) {
      log('Error fetching application details: $e');
      return null;
    }
  }

// to change user's application status as the company changes
  static Future<void> updateStatusInUserAndApplications(
      String userId, String applicationId, String newStatus) async {
    try {
      // Update the status in the 'my applications' sub-collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('myApplications')
          .doc(applicationId)
          .update({
        'status': newStatus,
      });

      log('message sent successfully!');
    } catch (e) {
      log('Error sending  message: $e');
    }
  }

  // when a company sends a message to a user to a specific application
  static Future<void> sendMessageToUser(
      String userId, String applicationId, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('myApplications')
          .doc(applicationId)
          .set({'message': message}, SetOptions(merge: true));

      log('Status updated successfully!');
    } catch (e) {
      log('Error updating status: $e');
    }
  }

  static Future<String?> getStatusFromUserAndApplication(
      String userId, String applicationId) async {
    try {
      // Fetch the status from the 'my applications' sub-collection
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('myApplications')
          .doc(applicationId)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data['status']; // Return the status
      } else {
        log('No document found for application ID: $applicationId');
        return null; // Return null if document doesn't exist
      }
    } catch (e) {
      log('Error getting status: $e');
      return null; // Return null if an error occurs
    }
  }

  static Stream<QuerySnapshot> getUserNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots();
  }

  static Future<int> getUnreadNotificationCount(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('status', isEqualTo: 'new')
        .get();

    return query.docs.length;
  }

  static Future<void> markNotificationsAsRead() async {
    final userId = Firebaseauth.getCurrentUser()?.uid;
    if (userId == null) return;

    try {
      await Future.delayed(const Duration(seconds: 1));
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('status', isEqualTo: 'new')
          .get();

      for (final doc in snapshot.docs) {
        doc.reference.update({'status': 'read'});
      }
    } catch (e) {
      log('Error marking notifications as read: $e');
    }
  }

  static int listenToNewNotifications(dynamic snapshot) {
    final userId = Firebaseauth.getCurrentUser()?.uid;
    //QuerySnapshot<Map<String, dynamic>> snapshot;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('status', isEqualTo: 'new')
          .snapshots()
          .listen((snapshot) {});
    }
    return snapshot.docs.length;
  }

  static Future<void> sendStatusChangeNotification(
      String uid, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        'message': message,
        'status': 'new',

        'time': FieldValue.serverTimestamp(), // Optional, for timestamp
      });

      log('notification sent');
    } catch (e) {
      log('cound not send notificaion: $e');
    }
  }

  static Future<Map<String, String>?> getTitleAndCompany(
      String userId, String applicationId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('myApplications')
          .doc(applicationId)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        String title = data['title'] ?? '';
        String company = data['company'] ?? '';
        log('title $title company $company');

        return {'title': title, 'company': company};
      } else {
        log('No document found for application ID: $applicationId');
        return null;
      }
    } catch (e) {
      log('Error getting title and company: $e');
      return null;
    }
  }

  static Future<void> saveImageUrlToUserDocument(String imageUrl) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception("No user is currently logged in.");
  }

  final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

  await userDocRef.update({
    'imageUrl': imageUrl,
  });
}


  static Stream<List<Map<String, dynamic>>> getJobApplicantsStreamWithProfiles(String jobId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('jobs')
        .doc(jobId)
        .collection('applicants')
        .snapshots()
        .asyncMap((applicantsSnapshot) async {
          List<Map<String, dynamic>> applicantsWithProfiles = [];

          for (var applicantDoc in applicantsSnapshot.docs) {
            String uid = applicantDoc.id;
            Map<String, dynamic> applicantData = applicantDoc.data();

            // Fetch user profile
            final userDoc = await firestore.collection('users').doc(uid).get();
            final userData = userDoc.data();

            if (userData != null) {
              // Add imageUrl from user profile
              applicantData['imageUr'] = userData['imageUrl'];
               applicantData['name'] = userData['fullName'];
                applicantData['Email'] = userData['email'];
                 applicantData['phoneNo'] = userData['phone'];

            }

            applicantData['uid'] = uid;

            applicantsWithProfiles.add(applicantData);
          }

          return applicantsWithProfiles;
        });
  }

}
