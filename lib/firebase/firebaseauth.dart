import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Firebaseauth {
  // Instance of FirebaseAuth
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current logged-in user
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Create a new user with email and password
  static Future<User?> createUser(String email, String password) async {
    try {
      // Create a new user using email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // User created successfully
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException;
      // Handle different FirebaseAuth exceptions
    } catch (e) {
      // Catch other exceptions
      print('Error: $e');
      return null;
    }
  }

  // Sign in with email and password
  static Future<User?> signInUser(String email, String password) async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Return the signed-in user
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // Sign out the current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }
   static Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
     
    } catch (e) {
     
    }
  }
}
