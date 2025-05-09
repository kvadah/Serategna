import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:serategna/email_verify_page.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firestore_user.dart';
import 'package:serategna/signin.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _userType = 'Employee';
  bool _isLoading = false;

  void _signUp() async {
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      User? user;
      try {
        user = await Firebaseauth.createUser(
            _emailController.text.trim(), _passwordController.text.trim());
      } catch (e) {
        log(e.toString());
        setState(() {
          _isLoading = false;
        });
      }
      if (user != null) {
        FirestoreUser.saveUserData(
            _fullNameController.text.trim(),
            _phoneController.text.trim(),
            _emailController.text.trim(),
            _userType,
            user);
      }
      setState(() {
        _isLoading = false;
      });

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => VerifyEmailPage()));
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No rounded corners
          ),
          margin: EdgeInsets.zero, // No extra margin
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Start from the top
                children: [
                  const SizedBox(
                    height: 110,
                  ),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _fullNameController,
                      _userType == 'Employer' ? 'Company Name' : 'Full Name',
                      Icons.person),
                  _buildTextField(
                      _phoneController,
                      _userType == 'Employer'
                          ? 'Company Phone Number'
                          : 'Phone Number',
                      Icons.phone,
                      keyboardType: TextInputType.phone),
                  _buildTextField(
                      _emailController,
                      _userType == 'Employer' ? 'Company Email' : 'Email',
                      Icons.email,
                      keyboardType: TextInputType.emailAddress),
                  _buildTextField(_passwordController, 'Password', Icons.lock,
                      obscureText: true),
                  const SizedBox(height: 16),

                  // User Type Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Sign up as: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Radio<String>(
                        value: 'Employee',
                        groupValue: _userType,
                        onChanged: (String? value) {
                          setState(() => _userType = value!);
                        },
                      ),
                      const Text("Employee"),
                      Radio<String>(
                        value: 'Employer',
                        groupValue: _userType,
                        onChanged: (String? value) {
                          setState(() => _userType = value!);
                        },
                      ),
                      const Text("Employer"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.black, // Elegant black
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text("Sign Up",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sign In Redirect
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => SignIn()));
                    },
                    child: const Text("Already have an account? Sign In"),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.github,
                          color: Colors.black,
                          size: 40,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.linkedin,
                          color: Colors.blue,
                          size: 40,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.instagram,
                          color: Color.fromARGB(195, 245, 34, 45),
                          size: 40,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
