import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:serategna/employee/first_page.dart';
import 'package:serategna/employeer/main_employeer_page.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firestore_user.dart';
import 'package:serategna/signin.dart';
import 'package:serategna/signup.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // <Map<String, dynamic>?> data ;

  final InternetConnectionChecker internetChecker =
      InternetConnectionChecker.createInstance();

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  void _checkInternetConnection() async {
    await Future.delayed(const Duration(seconds: 1)); // Splash screen duration

    bool isConnected = await internetChecker.hasConnection;

    if (isConnected) {
      _navigateToHome();
    } else {
      _showNoInternetDialog();
    }
  }

  Future<void> _navigateToHome() async {
    User? user = Firebaseauth.getCurrentUser();
    log(user.toString());
    if (user == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => SignUpPage()), // Navigate to SignUpPage
        (Route<dynamic> route) => false, // Remove all routes from the stack
      );
    } else {
      if (user.emailVerified) {
        Map<String, dynamic>? data = await FirestoreUser.getUserData(user);
        if (data?['userType'] == 'Employee') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) =>
                   const BottomNavScreen()), // Navigate to SignUpPage
            (Route<dynamic> route) => false, // Remove all routes from the stack
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) =>
                   const FirstEmployerPage()), // Navigate to SignUpPage
            (Route<dynamic> route) => false, // Remove all routes from the stack
          );
        }

        log('message');
      } else {
        Firebaseauth.sendVerificationEmail();
        Future.delayed(const Duration(seconds: 1));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => SignIn()), // Navigate to SignUpPage
          (Route<dynamic> route) => false, // Remove all routes from the stack
        );
      }
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("No Internet Connection"),
          content: const Text(
              "Please check your internet connection and try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkInternetConnection(); // Retry checking
              },
              child: const Text("Retry"),
            ),
            TextButton(
              onPressed: () {
                _exitApp(); // Properly exit the app
              },
              child: const Text("Exit"),
            ),
          ],
        );
      },
    );
  }

  void _exitApp() {
    SystemNavigator.pop(); // Exits the app properly
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 126, 171, 231),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Serategna',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const ClipOval(
              child: Image(
                image: AssetImage(
                    'assets/images/black_logo_transparent-removebg-preview.png'),
                width: 200, // Adjust as needed
                height:
                    150, // Ensure height is equal to width to keep it circular
                fit: BoxFit
                    .cover, // Ensures the image fits well inside the circle
              ),
            ),

            //const SizedBox(height: 20),
            _loadingAnimation(),
          ],
        ),
      ),
    );
  }

  Widget _loadingAnimation() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 5),
        ),
        SizedBox(width: 5),
        //  Text("Loading...",
        //  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
