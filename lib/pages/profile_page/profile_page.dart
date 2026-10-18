
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  bool isPickingImage = false;
  bool isUploading = false;

  Uint8List? selectedImage;

  final Color backgroundColor = const Color(0xFFFDF3E4);
  final Color orangeColor = Color(0xfff2A0A09);
  final Color darkColor = const Color(0xFF3D3027);

  // =========================
  // PICK IMAGE AND SAVE IT
  // =========================

  Future<void> pickAndSaveImage() async {
    if (isPickingImage || isUploading) return;

    setState(() {
      isPickingImage = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        isUploading = true;
      });

      final Uint8List imageBytes = await image.readAsBytes();

      // Convert image to Base64
      final String base64Image = base64Encode(imageBytes);

      // Firestore document maximum size is approximately 1 MiB.
      // Keep the profile image much smaller than that.
      if (base64Image.length > 500000) {
        throw Exception(
          'Image is too large. Please choose a smaller image.',
        );
      }

      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('User is not logged in');
      }

      // Save image in the existing user's document
      await _firestore.collection('users').doc(user.uid).set(
        {
          'profileImage': base64Image,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        selectedImage = imageBytes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image saved successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isPickingImage = false;
          isUploading = false;
        });
      }
    }
  }

  // =========================
  // CONVERT FIRESTORE IMAGE
  // =========================

  Uint8List? getImageFromFirestore(dynamic imageData) {
    if (imageData == null) return null;

    try {
      if (imageData is String && imageData.isNotEmpty) {
        return base64Decode(imageData);
      }
    } catch (e) {
      debugPrint('Image decoding error: $e');
    }

    return null;
  }

  // =========================
  // INFORMATION CARD
  // =========================

  Widget informationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 15.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 45.w,
            width: 45.w,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              icon,
              color: orangeColor,
              size: 23.sp,
            ),
          ),

          SizedBox(width: 13.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),

                SizedBox(height: 5.h),

                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // PROFILE IMAGE
  // =========================

  Widget profileImageWidget(Uint8List? firestoreImage) {
    final Uint8List? image = selectedImage ?? firestoreImage;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 125.w,
          width: 125.w,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(0xfff2A0A09),
              width: 3,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xfff2A0A09),
            backgroundImage:
                image != null ? MemoryImage(image) : null,
            child: image == null
                ? Icon(
                    Icons.person,
                    size: 65.sp,
                    color: Color(0xfff2A0A09),
                  )
                : null,
          ),
        ),

        Positioned(
          bottom: 3,
          right: 0,
          child: GestureDetector(
            onTap: (isPickingImage || isUploading)
                ? null
                : pickAndSaveImage,
            child: Container(
              height: 38.w,
              width: 38.w,
              decoration: BoxDecoration(
                color: Color(0xfff2A0A09),
                shape: BoxShape.circle,
                border: Border.all(
                  color: backgroundColor,
                  width: 3,
                ),
              ),
              child: (isPickingImage || isUploading)
                  ? Padding(
                      padding: EdgeInsets.all(8.w),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 19.sp,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: Text('Please sign in first'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: darkColor,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: orangeColor,
              ),
            );
          }

          final Map<String, dynamic> data =
              snapshot.data!.data() ?? {};

          // These match your Firestore field names.
          final String firstName =
              (data['first name'] ?? '').toString();

          final String lastName =
              (data['last name'] ?? '').toString();

          final String email =
              (data['email'] ?? user.email ?? '').toString();

          final String fullName =
              '$firstName $lastName'.trim();

          final Uint8List? firestoreImage =
              getImageFromFirestore(data['profileImage']);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 20.h,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // PROFILE IMAGE
                profileImageWidget(firestoreImage),

                SizedBox(height: 18.h),

                // FULL NAME
                Text(
                  fullName.isEmpty ? 'User' : fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),

                SizedBox(height: 7.h),

                // EMAIL
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),

                SizedBox(height: 35.h),

                // PERSONAL INFORMATION TITLE
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                ),

                SizedBox(height: 17.h),

                informationCard(
                  icon: Icons.person_outline,
                  title: 'First Name',
                  value: firstName,
                ),

                informationCard(
                  icon: Icons.person_outline,
                  title: 'Last Name',
                  value: lastName,
                ),

                informationCard(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value: email,
                ),

                SizedBox(height: 20.h),

               

                SizedBox(height: 14.h),

                // LOG OUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _auth.signOut();

                      // Your auth listener in main.dart should
                      // display the Sign In page automatically.
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xfff2A0A09),
                      side: const BorderSide(
                        color: Color(0xfff2A0A09),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 25.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
