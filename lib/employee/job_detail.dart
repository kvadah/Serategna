import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firebasefirestore.dart';

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final String jobId;

  const JobDetailsPage({super.key, required this.job, required this.jobId});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  String? _cvFilePath;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isJobExpired = false;
  bool _isAppliying = false;

  final InternetConnectionChecker internetChecker =
      InternetConnectionChecker.createInstance();

  Future<void> _pickCV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _cvFilePath = result.files.single.name;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkJobDeadline();
  }

  void _checkJobDeadline() {
    Timestamp? deadlineTimestamp = widget.job['deadline'];
    if (deadlineTimestamp != null) {
      DateTime deadline = deadlineTimestamp.toDate();
      _isJobExpired = deadline.isBefore(DateTime.now());
      log(deadline.toString());
    } else {
      _isJobExpired = false; // If no deadline is set, assume it's valid
    }
  }

  Future<bool> _checkInternetConnection() async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Splash screen duration

    bool isConnected = await internetChecker.hasConnection;

    if (isConnected) {
      return true;
    }
    return false;
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
                // Retry checking
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _submitApplication() async {
    setState(() {
      _isAppliying = true;
    });
    bool isInternateActive = await _checkInternetConnection();
    if (!isInternateActive) {
      _showNoInternetDialog();
      setState(() {
        _isAppliying = false;
      });
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Please describe about yourself before applying.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      setState(() {
        _isAppliying = false;
      });
      return;
    }
    User? user = Firebaseauth.getCurrentUser();
    bool alreadyapplied = await FirestoreJobs.applyForJob(
        user!.uid, widget.jobId, _descriptionController.text.trim());
    log(widget.jobId);
    if (alreadyapplied) {
      Fluttertoast.showToast(
        msg: "You have already applied for this job!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: "Application submitted successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      _descriptionController.clear();
    }
    setState(() {
      _isAppliying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job['companyName']!,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Title
            Text(
              widget.job['title']!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // Company & Location
            Text('Company: ${widget.job['companyName']!}',
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            Text('Location: ${widget.job['location']!}',
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Job Description
            Text(widget.job['description']!,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Upload CV Section
            ElevatedButton.icon(
                onPressed: _pickCV,
                icon: const Icon(Icons.upload_file),
                label: _cvFilePath == null
                    ? const Text('Upload cv')
                    : Text(_cvFilePath!)),
            if (_cvFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Selected File: $_cvFilePath',
                    style: const TextStyle(fontSize: 14, color: Colors.green)),
              ),
            const SizedBox(height: 20),

            // Self Description Box
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                labelText: 'Describe about yourself',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            if (_isJobExpired)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Application deadline has passed.",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 30),

            // Apply Button
            Center(
              child: ElevatedButton.icon(
                  onPressed: () {
                    _isJobExpired ? null : _submitApplication();
                  },
                  icon: _isAppliying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ))
                      : const Icon(Icons.send),
                  label: const Text('Apply Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isJobExpired ? Colors.grey : null,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
