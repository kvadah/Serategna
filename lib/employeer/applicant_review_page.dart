import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:serategna/firebase/firestore_user.dart';

class ApplicantReviewPage extends StatefulWidget {
  final String applicantId;
  final String jobId;

  const ApplicantReviewPage({
    super.key,
    required this.applicantId,
    required this.jobId,
  });

  @override
  State<ApplicantReviewPage> createState() => _ApplicantReviewPageState();
}

class _ApplicantReviewPageState extends State<ApplicantReviewPage> {
  String profileImageUrl = "";
  String? selectedStatus;
  String companyName = 'kk';
  String title = 'll';
  String message = '';
  bool isSendingMessage = false;
  bool isLoadingStatus = true;
  TextEditingController messageController = TextEditingController();

  final List<String> statusOptions = [
    'Pending',
    'Interview Scheduled',
    'Rejected',
    'Hired',
  ];

  void showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void fetchTitleandCompany() async {
    final result = await FirestoreUser.getTitleAndCompany(
        widget.applicantId, widget.jobId);

    if (result != null) {
      title = result['title']!;
      companyName = result['company']!;
      log('title $title company $companyName');
    }
  }

  Future<void> _fetchStatus() async {
    final status = await FirestoreUser.getStatusFromUserAndApplication(
      widget.applicantId,
      widget.jobId,
    );

    setState(() {
      selectedStatus = status ?? 'Pending'; // default if null
      isLoadingStatus = false;
    });
  }

  String _buildApplicationStatusNotification({
    required String companyName,
    required String jobTitle,
    required String? status,
  }) {
    String statusMessage;

    switch (status?.toLowerCase()) {
      case 'pending':
        statusMessage = 'is currently pending review';
        break;
      case 'rejected':
        statusMessage = 'has been rejected';
        break;
      case 'hired':
        statusMessage = 'has been marked as hired 🎉';
        break;
      case 'interview scheduled':
        statusMessage = 'has an interview scheduled';
        break;
      default:
        statusMessage = 'has been updated';
    }

    return 'Your application for "$jobTitle" at $companyName $statusMessage. '
        'Please check your application for more details.';
  }

  void sendMessageToUser(
      String applicantId, String jobId, String message) async {
    try {
      await FirestoreUser.sendMessageToUser(applicantId, jobId, message);
      showToast('message sent successfully', Colors.green);
      messageController.clear();
    } catch (e) {
      showToast('could not send the message', Colors.red);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTitleandCompany();
    _fetchStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Applicant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('jobs')
                  .doc(widget.jobId)
                  .collection('applicants')
                  .doc(widget.applicantId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No data found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${data['fullName'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${data['email'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "About the Applicant",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['about'] ?? 'No additional information.',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Status: ",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          DropdownButton<String>(
                            value: selectedStatus,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedStatus = value);
                                FirestoreUser.updateStatusInUserAndApplications(
                                  widget.applicantId,
                                  widget.jobId,
                                  value,
                                );
                              }
                              setState(() {
                                message = _buildApplicationStatusNotification(
                                    companyName: companyName,
                                    jobTitle: title,
                                    status: selectedStatus);
                              });
                              FirestoreUser.sendStatusChangeNotification(
                                  widget.applicantId, message);
                            },
                            items: statusOptions
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        maxLines: 5,
                        controller: messageController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your message...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          sendMessageToUser(widget.applicantId, widget.jobId,
                              messageController.text);
                        },
                        icon: const Icon(Icons.send),
                        label: const Text("Send"),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
