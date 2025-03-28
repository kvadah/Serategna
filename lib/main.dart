import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:serategna/splash_screeen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures Firebase is initialized before the app starts
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
