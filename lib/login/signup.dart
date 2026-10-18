
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUp extends StatefulWidget {
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  // FORM KEY
  final _formKey = GlobalKey<FormState>();

  // CONTROLLERS
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool isLoading = false;

  // CHECK PASSWORD
  bool passwordIsConfirmed() {
    return _passwordController.text ==
        _confirmPasswordController.text;
  }

  // SIGN UP
  Future<void> signUp() async {

    // 1. Create user in Firebase Authentication
    final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // 2. Save user details in Firestore
    await addUserDetails(
      userCredential.user!.uid,
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _emailController.text.trim(),
    );
  }

  // ADD USER DETAILS TO FIRESTORE
  Future<void> addUserDetails(
    String uid,
    String firstName,
    String lastName,
    String email,
  ) async {

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'first name': firstName,
      'last name': lastName,
      'email': email,
    });
  }

  // DISPOSE CONTROLLERS
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFDF3E4),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),

            child: Form(
              key: _formKey,

              child: Column(
                children: [

                  // IMAGE
                  Image.asset(
                    'assets/images/signup_pics/Reading.png',
                    height: 170.h,
                  ),

                  // TITLE
                  Text(
                    'Create Your Account',
                    style: GoogleFonts.dmSerifDisplay(
                      textStyle: TextStyle(
                        fontSize: 35.sp,
                        color: const Color(0xFF2A0A09),
                      ),
                    ),
                  ),

                  Text(
                    'Join Swap Shelf and start your',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: const Color(0xFF2A0A09),
                    ),
                  ),

                  Text(
                    'book-swapping journey',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: const Color(0xFF2A0A09),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // FIRST NAME
                  TextFormField(
                    controller: _firstNameController,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your first name';
                      }

                      return null;
                    },

                    decoration: InputDecoration(
                      hintText: 'First Name',
                      labelText: 'First Name',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF2A0A09),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // LAST NAME
                  TextFormField(
                    controller: _lastNameController,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your last name';
                      }

                      return null;
                    },

                    decoration: InputDecoration(
                      hintText: 'Last Name',
                      labelText: 'Last Name',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF2A0A09),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // EMAIL
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
                        caseSensitive: false,
                      ).hasMatch(value.trim())) {
                        return 'Please enter a valid @gmail.com email';
                      }

                      return null;
                    },

                    decoration: InputDecoration(
                      hintText: 'Name@gmail.com',
                      labelText: 'Email',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF2A0A09),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // PASSWORD
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },

                    decoration: InputDecoration(
                      hintText: 'Password',
                      labelText: 'Password',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF2A0A09),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // CONFIRM PASSWORD
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (!passwordIsConfirmed()) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },

                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      labelText: 'Confirm Password',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF2A0A09),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // SIGN UP BUTTON
                  InkWell(
                    onTap: isLoading
                        ? null
                        : () async {

                            if (_formKey.currentState!.validate()) {

                              setState(() {
                                isLoading = true;
                              });

                              try {

                                await signUp();

                                if (!mounted) return;

                                Navigator.pop(context);

                              } on FirebaseAuthException catch (e) {

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.message ?? 'Authentication failed',
                                    ),
                                  ),
                                );

                              } on FirebaseException catch (e) {

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Firestore error: ${e.message}',
                                    ),
                                  ),
                                );

                              } catch (e) {

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                  ),
                                );

                              } finally {

                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }

                              }
                            }
                          },

                    child: Container(
                      height: 50.h,
                      width: double.infinity,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: const Color(0xFF79432C),
                      ),

                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                ),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
