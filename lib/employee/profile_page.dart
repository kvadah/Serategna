import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firestore_user.dart';
import 'package:serategna/signin.dart';
import 'package:serategna/skills.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user = Firebaseauth.getCurrentUser();
  String bio = "No Bio Available";
  String profileImageUrl = "";
  List<dynamic> skills = [];
  bool _isloggingOut = false;

  void _signout() async {
    setState(() {
      _isloggingOut = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    await Firebaseauth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => SignIn()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      //future builder
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirestoreUser.getUserDocument(user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user data found"));
          }

          final userData = snapshot.data!;
          bio = userData["bio"] ?? "No Bio Available";
          profileImageUrl = userData["profileImage"] ?? "";
          skills = userData["skills"] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image Section
                GestureDetector(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Bio Section
                BioSection(
                  initialBio: bio,
                  onBioUpdated: _updateBio,
                ),

                // Full Name
                _buildProfileCard(Icons.person, "Full Name",
                    userData["fullName"] ?? "No Name"),
                // Email
                _buildProfileCard(
                    Icons.email, "Email", userData["email"] ?? "No Email"),
                // Phone
                _buildProfileCard(
                    Icons.phone, "Phone", userData["phone"] ?? "No Phone"),

                // Skills Section
                SkillsSection(
                  skills: List<String>.from(skills),
                  onSkillAdded: _addSkill,
                  onSkillRemoved: _removeSkill,
                ),
                TextButton(
                    onPressed: () {
                      _signout();
                    },
                    child: _isloggingOut
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Log out',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ))
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateBio(String newBio) {
    if (user == null) return;

    _firestore
        .collection("users")
        .doc(user!.uid)
        .update({"bio": newBio}).then((_) {
      setState(() {
        bio = newBio;
      });
    }).catchError((error) {
      log("Error updating bio: $error");
    });
  }

  void _addSkill(String newSkill) {
    if (user == null) return;

    _firestore.collection("users").doc(user!.uid).update({
      "skills": FieldValue.arrayUnion([newSkill])
    }).then((_) {
      setState(() {
        skills.add(newSkill);
      });
    }).catchError((error) {
      log("Error adding skill: $error");
    });
  }

  void _removeSkill(String skill) {
    if (user == null) return;

    _firestore.collection("users").doc(user!.uid).update({
      "skills": FieldValue.arrayRemove([skill])
    }).then((_) {
      setState(() {
        skills.remove(skill);
      });
    }).catchError((error) {
      log("Error removing skill: $error");
    });
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

class BioSection extends StatefulWidget {
  final String initialBio;
  final Function(String) onBioUpdated;

  const BioSection(
      {required this.initialBio, required this.onBioUpdated, Key? key})
      : super(key: key);

  @override
  State<BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends State<BioSection> {
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.info, color: Colors.black),
        title: const Text("Bio", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.initialBio),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: () => _editBioDialog(context),
        ),
      ),
    );
  }

  void _editBioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Bio"),
          content: TextField(
            controller: bioController,
            decoration: const InputDecoration(hintText: "Enter new bio"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                widget.onBioUpdated(bioController.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}

class SkillsSection extends StatelessWidget {
  final List<String> skills;
  final Function(String) onSkillAdded;
  final Function(String) onSkillRemoved;

  const SkillsSection({
    required this.skills,
    required this.onSkillAdded,
    required this.onSkillRemoved,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.code, color: Colors.black),
                    SizedBox(width: 8),
                    Text("Skills",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black),
                  onPressed: () => _addSkillDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: skills.map((skill) {
                return Chip(
                  label:
                      Text(skill, style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.black,
                  deleteIcon: const Icon(Icons.close, color: Colors.white),
                  onDeleted: () => onSkillRemoved(skill),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _addSkillDialog(BuildContext context) {
    FocusScope.of(context).unfocus(); // Unfocus any active input field

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select a Skill"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allSkills.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(allSkills[index]),
                  onTap: () {
                    onSkillAdded(allSkills[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
