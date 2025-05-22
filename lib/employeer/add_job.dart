import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firebasefirestore.dart';

class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deadlineController =
      TextEditingController(); // Controller for deadline
  DateTime? _selectedDeadline;
  final List<String> jobTypes = ['Full-time', 'Part-time', 'Internship'];
  String? selectedJobType;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
  }

  // Function to pick the deadline date
  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text =
            "${picked.toLocal()}".split(' ')[0]; // Formatting the date
      });
    }
  }

  void postAjob() async {
    setState(() {
      _isPosting = true;
    });
    User? user = Firebaseauth.getCurrentUser();
    await FirestoreJobs.addJobToCompanyAndJobsCollection(
      user,
      _titleController.text,
      selectedJobType!,
      _locationController.text,
      _descriptionController.text,
      _selectedDeadline, // Add the deadline date
    );
    _titleController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _deadlineController.clear();
    setState(() {
      selectedJobType = null;
    });

    Fluttertoast.showToast(
      msg: "job posted successfully.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    setState(() {
      _isPosting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Job')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /*TextField(
                controller: _CompanyNameController,
                decoration: InputDecoration(labelText: 'Company name'),
              ),*/
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  // border: OutlineInputBorder(),
                ),
                value: selectedJobType,
                items: jobTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedJobType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a job type' : null,
              ),

              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Job Description'),
              ),
              const SizedBox(height: 20),
              // Deadline field
              TextField(
                controller: _deadlineController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  hintText: 'Select the deadline date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDeadline(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isPosting
                    ? null
                    : () async {
                        if (_selectedDeadline == null) {
                          // Show an error if deadline is not selected
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a deadline')));
                          return;
                        }
                        postAjob();
                      },
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Post Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
