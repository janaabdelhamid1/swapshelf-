
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  // ================= COLORS =================

  static const Color backgroundColor = Color(0xFFFFF8EF);
  static const Color primaryBrown = Color(0xFF713E29);
  static const Color darkBrown = Color(0xFF30180F);
  static const Color peachColor = Color(0xFFEAC8B0);
  static const Color fieldColor = Color(0xFFFFFCF7);
  static const Color borderColor = Color(0xFFE8D8C7);

  // ================= CONTROLLERS =================

  final TextEditingController bookNameController =
      TextEditingController();

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final ImagePicker imagePicker = ImagePicker();

  // ================= VARIABLES =================

  Uint8List? bookImage;
  String? selectedBookType;

  bool isPickingImage = false;
  bool isSaving = false;

  final List<String> bookTypes = [
    'Fiction',
    'Romance',
    'Fantasy',
    'Science Fiction',
    'Non-Fiction',
    'Mystery',
    'History',
    'Science',
    'Self Development',
    'Educational',
    'Other',
  ];

  // ================= SNACKBAR =================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryBrown,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ================= PICK IMAGE =================

  Future<void> pickBookImage() async {
    if (isPickingImage || isSaving) return;

    setState(() {
      isPickingImage = true;
    });

    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxWidth: 300,
        maxHeight: 400,
      );

      // User cancelled image selection.
      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        showMessage('The selected image is empty');
        return;
      }

      if (!mounted) return;

      setState(() {
        bookImage = bytes;
      });
    } catch (e, stackTrace) {
      debugPrint('PICK IMAGE ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      showMessage('Could not select image');
    } finally {
      if (mounted) {
        setState(() {
          isPickingImage = false;
        });
      }
    }
  }

  // ================= ADD BOOK =================

  Future<void> addBook() async {
    if (isSaving || isPickingImage) return;

    // Validate the Form safely.
    final bool isValid =
        formKey.currentState?.validate() ?? false;

    if (!isValid) {
      debugPrint('ADD BOOK: Form validation failed');
      return;
    }

    // Check book type.
    final String? bookType = selectedBookType;

    if (bookType == null || bookType.isEmpty) {
      showMessage('Please select a book type');
      return;
    }

    // Check image without using !.
    final Uint8List? selectedImage = bookImage;

    if (selectedImage == null || selectedImage.isEmpty) {
      showMessage('Please upload a book cover');
      return;
    }

    // Check current user.
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please sign in first');
      return;
    }

    final String bookName =
        bookNameController.text.trim();

    if (bookName.isEmpty) {
      showMessage('Please enter the book name');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      debugPrint('ADD BOOK: Starting...');

      // Convert image to Base64.
      final String imageBase64 =
          base64Encode(selectedImage);

      debugPrint(
        'ADD BOOK: Image length = ${imageBase64.length}',
      );

      // Avoid saving oversized image data.
      if (imageBase64.length > 500000) {
        throw Exception(
          'Image is too large. Please choose a smaller image.',
        );
      }

      debugPrint('ADD BOOK: User ID = ${user.uid}');

      // Save book in Firestore.
      await FirebaseFirestore.instance
          .collection('books')
          .add({
        'bookName': bookName,
        'bookType': bookType,
        'bookImage': imageBase64,
        'ownerId': user.uid,

        // Swap status
        'isSwapped': false,
        'swappedAt': null,
        'swapRequestId': null,

        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ADD BOOK: Saved successfully');

      if (!mounted) return;

      // Clear fields after successful saving.
      bookNameController.clear();

      setState(() {
        bookImage = null;
        selectedBookType = null;
      });

      showMessage('Book added successfully!');
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('FIREBASE ERROR CODE: ${e.code}');
      debugPrint('FIREBASE ERROR MESSAGE: ${e.message}');
      debugPrint('STACK TRACE: $stackTrace');

      showMessage(
        'Firebase error: ${e.message ?? e.code}',
      );
    } catch (e, stackTrace) {
      debugPrint('ADD BOOK ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      showMessage('Failed to add book: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ================= INPUT DECORATION =================

  InputDecoration customInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    OutlineInputBorder inputBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: color),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF9D8B7C),
        fontSize: 14.sp,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryBrown,
        size: 21.sp,
      ),
      filled: true,
      fillColor: fieldColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 17.h,
      ),
      border: inputBorder(borderColor),
      enabledBorder: inputBorder(borderColor),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(
          color: primaryBrown,
          width: 1.5,
        ),
      ),
      errorBorder: inputBorder(Colors.redAccent),
      focusedErrorBorder: inputBorder(Colors.redAccent),
    );
  }

  // ================= BOOK COVER =================

  Widget buildBookCover() {
    return GestureDetector(
      onTap: isPickingImage || isSaving
          ? null
          : pickBookImage,
      child: Container(
        width: double.infinity,
        height: 215.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF7EADC),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: const Color(0xFFD9BCA6),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: isPickingImage
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryBrown,
                ),
              )
            : bookImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 65.w,
                        height: 65.w,
                        decoration: BoxDecoration(
                          color: peachColor,
                          borderRadius:
                              BorderRadius.circular(17.r),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32.sp,
                          color: primaryBrown,
                        ),
                      ),
                      SizedBox(height: 13.h),
                      Text(
                        'Upload Book Cover',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        'Tap to choose a photo from gallery',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF8B7464),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.memory(
                        bookImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Icon(
                            Icons.broken_image_outlined,
                            color: primaryBrown,
                            size: 50,
                          );
                        },
                      ),
                      Positioned(
                        bottom: 10.h,
                        right: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBrown,
                            borderRadius:
                                BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 15.sp,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                'Change Cover',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    bookNameController.dispose();
    super.dispose();
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: darkBrown,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Add New Book',
          style: TextStyle(
            color: darkBrown,
            fontSize: 23.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 20.h,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Next Great Read',
                  style: TextStyle(
                    color: darkBrown,
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  'Add your book to your shelf and let others discover it.',
                  style: TextStyle(
                    color: const Color(0xFF8B7464),
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 27.h),

                // BOOK COVER

                Text(
                  'Book Cover',
                  style: TextStyle(
                    color: darkBrown,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12.h),

                buildBookCover(),

                SizedBox(height: 27.h),

                // BOOK NAME

                Text(
                  'Book Name',
                  style: TextStyle(
                    color: darkBrown,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12.h),

                TextFormField(
                  controller: bookNameController,
                  enabled: !isSaving,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: customInputDecoration(
                    hint: 'Enter book title...',
                    icon: Icons.menu_book_outlined,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter the book name';
                    }

                    return null;
                  },
                ),

                SizedBox(height: 27.h),

                // BOOK TYPE

                Text(
                  'Book Type',
                  style: TextStyle(
                    color: darkBrown,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12.h),

                DropdownButtonFormField<String>(
                  value: selectedBookType,
                  isExpanded: true,
                  dropdownColor: fieldColor,
                  decoration: customInputDecoration(
                    hint: 'Select book category',
                    icon: Icons.category_outlined,
                  ),
                  items: bookTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: isSaving
                      ? null
                      : (value) {
                          setState(() {
                            selectedBookType = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a book type';
                    }

                    return null;
                  },
                ),

                SizedBox(height: 38.h),

                // ADD BOOK BUTTON

                SizedBox(
                  width: double.infinity,
                  height: 55.h,
                  child: ElevatedButton(
                    onPressed: isSaving || isPickingImage
                        ? null
                        : addBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBrown,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primaryBrown.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15.r),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 21.sp,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Add Book',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 25.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
