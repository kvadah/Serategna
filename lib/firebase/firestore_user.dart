import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:serategna/firebase/firebaseauth.dart';

class FirestoreUser{
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  //save user date on register
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


// additional user data
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
      log("Error fetching user data: $e");
    }
    return null;
  }

  //get users applications list
  
  static Stream<QuerySnapshot> getUserApplicationsStream() {
    var userId = Firebaseauth.getCurrentUser()?.uid; // Get the current user ID

    // Access the user's document in the 'users' collection and fetch their 'myApplications' subcollection
    return FirebaseFirestore.instance
        .collection('users') // Reference to the 'users' collection
        .doc(userId) // Document for the current user
        .collection(
            'myApplications') // Subcollection with the user's applications
        .snapshots(); // Stream of documents in that subcollection
  }
}