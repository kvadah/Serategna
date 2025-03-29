import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:serategna/employee/first_page.dart';
import 'package:serategna/firebase/firestore_user.dart';
import 'package:serategna/skills.dart';

class SkillSelectionPage extends StatefulWidget {
  final String userId;

  const SkillSelectionPage({super.key, required this.userId});

  @override
  State<SkillSelectionPage> createState() => _SkillSelectionPageState();
}

class _SkillSelectionPageState extends State<SkillSelectionPage> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillSearchController = TextEditingController();

  List<String> filteredSkills = [];
  List<String> selectedSkills = [];
  File? _image;

  @override
  void initState() {
    super.initState();
    filteredSkills = allSkills;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveUserData() async {
    FirestoreUser.saveAdditionalUserData(widget.userId, _bioController.text, selectedSkills);
   /* try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'bio': _bioController.text,
        'skills': selectedSkills,
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Skills")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : const AssetImage(
                            'assets/images/black_logo_transparent-removebg-preview.png')
                        as ImageProvider,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                  labelText: "Bio", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _skillSearchController,
              onChanged: (value) {
                setState(() {
                  filteredSkills = allSkills
                      .where((skill) =>
                          skill.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: const InputDecoration(
                  labelText: "Search Skills", border: OutlineInputBorder()),
            ),
            Wrap(
              children: selectedSkills
                  .map((skill) => Chip(
                        label: Text(skill),
                        onDeleted: () {
                          setState(() {
                            selectedSkills.remove(skill);
                          });
                        },
                      ))
                  .toList(),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredSkills.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredSkills[index]),
                    onTap: () {
                      setState(() {
                        if (!selectedSkills.contains(filteredSkills[index])) {
                          selectedSkills.add(filteredSkills[index]);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BottomNavScreen()),
                          (route) => false);
                    },
                    child: const Text("Skip")),
                ElevatedButton(
                    onPressed: () {
                      _saveUserData();
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>const  BottomNavScreen()),
                          (route) => false);
                    },
                    child: const Text("Save")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
