
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swapshelf_app/pages/send_reques.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const bg = Color(0xFFFFF8EF);
  static const brown = Color(0xFF713E29);
  static const dark = Color(0xFF30180F);
  static const peach = Color(0xFFEAC8B0);

  final db = FirebaseFirestore.instance;
  final searchController = TextEditingController();

  String search = '';

  Widget cover(dynamic value) {
    try {
      if (value is String && value.isNotEmpty) {
        return Image.memory(
          base64Decode(value),
          width: double.infinity,
          height: 165.h,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.menu_book, size: 55),
        );
      }
    } catch (_) {}

    return const Center(
      child: Icon(
        Icons.menu_book,
        size: 55,
        color: brown,
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in first')),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: bg,
        title: Text(
          'SwapShelf',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            color: dark,
            fontSize: 25.sp,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.h),
            Text(
              'Discover Your Next Read',
              style: TextStyle(
                color: dark,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            const Text(
              'Explore books shared by other readers.',
              style: TextStyle(color: brown),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  search = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for a book...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: brown,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            SizedBox(height: 22.h),
            Text(
              'Available Books',
              style: TextStyle(
                fontSize: 18.sp,
                color: dark,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: db.collection('books').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: brown,
                      ),
                    );
                  }

                  final books = snapshot.data!.docs.where((doc) {
                    final data = doc.data();

                    // Hide swapped books from Home.
                    if (data['isSwapped'] == true) {
                      return false;
                    }

                    final name =
                        '${data['bookName'] ?? ''}'.toLowerCase();

                    final type =
                        '${data['bookType'] ?? ''}'.toLowerCase();

                    return name.contains(search) ||
                        type.contains(search);
                  }).toList();

                  if (books.isEmpty) {
                    return const Center(
                      child: Text('No available books found'),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.only(bottom: 20.h),
                    itemCount: books.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 315.h,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 14.h,
                    ),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final data = book.data();

                      final name =
                          '${data['bookName'] ?? 'Book'}';

                      final type =
                          '${data['bookType'] ?? 'Other'}';

                      final ownerId =
                          '${data['ownerId'] ?? ''}';

                      final isMine = ownerId == user.uid;

                      return Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(18.r),
                          border: Border.all(
                            color: const Color(0xFFE8D8C7),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 165.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7EADC),
                                borderRadius:
                                    BorderRadius.circular(12.r),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: cover(data['bookImage']),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: dark,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: brown),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 42.h,
                              child: ElevatedButton(
                                onPressed:
                                    isMine || ownerId.isEmpty
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    SendRequestPage(
                                                  bookId: book.id,
                                                  bookName: name,
                                                  ownerId: ownerId,
                                                ),
                                              ),
                                            );
                                          },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brown,
                                  disabledBackgroundColor: peach,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: dark,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  isMine
                                      ? 'Your Book'
                                      : 'Send Request',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
