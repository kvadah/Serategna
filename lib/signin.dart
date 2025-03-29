import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:serategna/email_verify_page.dart';
import 'package:serategna/employee/first_page.dart';
import 'package:serategna/employeer/main_employeer_page.dart';
import 'package:serategna/firebase/firebaseauth.dart';
import 'package:serategna/firebase/firestore_user.dart';
import 'package:serategna/signup.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _signIn() async {
    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      try {
        User? user = await Firebaseauth.signInUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          await user.reload(); // 🔴 Important: Refresh user data
          user = FirebaseAuth.instance.currentUser; // Get updated user data

          Map<String, dynamic>? data = await FirestoreUser.getUserData(user);

          if (user!.emailVerified) {
            // Now emailVerified will be up-to-date
            // Navigate based on user type
            if (data?['userType'] == 'Employee') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) =>  BottomNavScreen()),
                (Route<dynamic> route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => FirstEmployerPage ()),
                (Route<dynamic> route) => false,
              );
            }
          } else {
            Firebaseauth.sendVerificationEmail();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VerifyEmailPage()),
            );
          }
        } else {
          throw "Invalid credentials. Please try again.";
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error: ($e)")), // Remove .message since e might be a String
        );
      }
      setState(() => _isLoading = false);
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 110),
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, 'Email', Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField(_passwordController, 'Password', Icons.lock,
                        obscureText: true),
                    const SizedBox(height: 16),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.black,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Sign In",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password Link
                    TextButton(
                      onPressed: () {
                        // Add the functionality for forgot password here
                      },
                      child: const Text("Forgot Password?"),
                    ),

                    const SizedBox(height: 16),

                    // Sign Up Redirect
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()));
                      },
                      child: const Text("Don't have an account? Sign Up"),
                    ),
                    const SizedBox(height: 50),

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
