import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/signin.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = Firebaseauth.getCurrentUser();
  Map<String, dynamic>? companyData;

  void _signout() async {
    await Firebaseauth.signOut();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => SignIn()), (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();
  }

  Future<void> _fetchCompanyData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .get();
      if (doc.exists) {
        setState(() {
          companyData = doc.data() as Map<String, dynamic>?;
        });
      }
    } catch (error) {
      log("Error fetching company data: $error");
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          " Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: companyData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: companyData!["logo"] != null
                        ? NetworkImage(companyData!["logo"])
                        : null,
                    child: companyData!["logo"] == null
                        ? const Icon(Icons.business, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    companyData!["fullName"] ?? "No Name",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    companyData!["about"] ?? "about",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileCard(Icons.location_on, "Location",
                      companyData!["location"] ?? "No Location"),
                  _buildProfileCard(Icons.email, "Email",
                      companyData!["email"] ?? "No Email"),
                  _buildProfileCard(Icons.phone, "Phone",
                      companyData!["phone"] ?? "No Phone"),
                  const SizedBox(height: 30),
                  TextButton(
                      onPressed: () {
                        _signout();
                      },
                      child: const Text(
                        'LogOut',
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      ))
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(IconData icon, String title, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
