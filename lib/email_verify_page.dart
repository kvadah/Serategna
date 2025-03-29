import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:serategna/employee/users_additional_info.dart';
import 'package:serategna/employeer/home_page.dart';
import 'package:serategna/employeer/main_employeer_page.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firestore_user.dart';
import 'package:serategna/signup.dart';

class VerifyEmailPage extends StatefulWidget {
  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isVerified = false;
  Timer? timer;
  User? user;

  @override
  void initState() {
    super.initState();

    // Check if email is verified every 3 seconds
    timer =
        Timer.periodic(const Duration(seconds: 1), (_) => checkEmailVerified());
  }

  Future<void> checkEmailVerified() async {
    await Firebaseauth.getCurrentUser()?.reload();
    setState(() {
      isVerified = Firebaseauth.getCurrentUser()?.emailVerified ?? false;
    });

    if (isVerified) {
      timer?.cancel();
      user = Firebaseauth.getCurrentUser(); // Get updated user data

      Map<String, dynamic>? data = await FirestoreUser.getUserData(user);

      if (user!.emailVerified) {
        // Now emailVerified will be up-to-date
        // Navigate based on user type
        if (data?['userType'] == 'Employee') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => SkillSelectionPage(
                    userId: FirebaseAuth.instance.currentUser!.uid)),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const FirstEmployerPage()),
            (route) => false,
          );
        }
      }
    } else {
      Firebaseauth.sendVerificationEmail();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> sendVerificationEmail() async {
    try {
     
      await Firebaseauth.sendVerificationEmail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verification email sent! Check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send email. Try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Your Email"),
        // backgroundColor: const Color.fromARGB(255, 249, 251, 252),
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 50,
            ),
            const Text(
              "You Email is not Verified yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 50,
            ),
            const Text(
              "A verification email has been sent to your email.check your inbox and click the link to verify.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                onPressed: () {
                  Firebaseauth.sendVerificationEmail();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.black, // Elegant black
                ),
                child: const Text("Resend Email",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                      (route) => false);
                },
                child: const Text("don't have an account? register"))
            //Spacer(),
          ],
        ),
      ),
    );
  }
}
