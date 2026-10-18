
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:swapshelf_app/pages/location/swap_location.dart';

class SendRequestPage extends StatefulWidget {
  final String bookId;
  final String bookName;
  final String ownerId;

  const SendRequestPage({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.ownerId,
  });

  @override
  State<SendRequestPage> createState() => _SendRequestPageState();
}

class _SendRequestPageState extends State<SendRequestPage> {
  // ================= COLORS =================

  static const Color bg = Color(0xFFFFF8EF);
  static const Color brown = Color(0xFF713E29);
  static const Color dark = Color(0xFF30180F);
  static const Color peach = Color(0xFFEAC8B0);
  static const Color fieldColor = Color(0xFFFFFCF7);
  static const Color borderColor = Color(0xFFE8D8C7);

  // ================= FIREBASE =================

  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ================= SELECTED DATA =================

  final Set<String> offeredIds = {};

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedLocation;

  bool saving = false;

  // ================= MESSAGE =================

  void message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: brown,
      ),
    );
  }

  // ================= PICK DATE =================

  Future<void> pickDate() async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final value = await showDatePicker(
      context: context,
      initialDate: selectedDate != null &&
              !selectedDate!.isBefore(today)
          ? selectedDate!
          : today,
      firstDate: today,
      lastDate: today.add(
        const Duration(days: 365),
      ),
    );

    if (value != null && mounted) {
      setState(() {
        selectedDate = value;
      });
    }
  }

  // ================= PICK TIME =================

  Future<void> pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (value != null && mounted) {
      setState(() {
        selectedTime = value;
      });
    }
  }

  // ================= SEND REQUEST =================

  Future<void> sendRequest() async {
    if (saving) return;

    // Get current user

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      message('Please sign in first');
      return;
    }

    // Prevent requesting your own book

    if (user.uid == widget.ownerId) {
      message('You cannot request your own book');
      return;
    }

    // Validate fields

    if (selectedDate == null ||
        selectedTime == null ||
        selectedLocation == null ||
        offeredIds.isEmpty) {
      message(
        'Please complete all fields and offer at least one book',
      );
      return;
    }

    // Offer exactly one book

    if (offeredIds.length != 1) {
      message('Please choose exactly one book');
      return;
    }

    // Combine date and time

    final DateTime meeting = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // Meeting must be in the future

    if (!meeting.isAfter(DateTime.now())) {
      message('Please choose a future meeting time');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      // ================= REQUESTED BOOK =================

      final requestedBook = await db
          .collection('books')
          .doc(widget.bookId)
          .get();

      if (!requestedBook.exists) {
        throw Exception(
          'The requested book is no longer available',
        );
      }

      final requestedBookData = requestedBook.data()!;

      // Verify book owner

      if (requestedBookData['ownerId'] != widget.ownerId) {
        throw Exception(
          'The requested book owner has changed',
        );
      }

      // NEW: Prevent requesting a swapped book

      if (requestedBookData['isSwapped'] == true) {
        throw Exception(
          'This book has already been swapped',
        );
      }

      // ================= OFFERED BOOKS =================

      final List<String> ids = offeredIds.toList()..sort();

      for (final String id in ids) {
        final offeredBook = await db
            .collection('books')
            .doc(id)
            .get();

        if (!offeredBook.exists) {
          throw Exception(
            'One of your offered books is unavailable',
          );
        }

        final offeredBookData = offeredBook.data()!;

        // Verify ownership

        if (offeredBookData['ownerId'] != user.uid) {
          throw Exception(
            'You can only offer books from your own shelf',
          );
        }

        // NEW: Prevent offering swapped books

        if (offeredBookData['isSwapped'] == true) {
          throw Exception(
            'One of your offered books has already been swapped',
          );
        }
      }

      // ================= USER PROFILE =================

      final profileSnapshot = await db
          .collection('users')
          .doc(user.uid)
          .get();

      final Map<String, dynamic> profile =
          profileSnapshot.data() ?? {};

      final String senderName =
          '${profile['first name'] ?? ''} '
          '${profile['last name'] ?? ''}'.trim();

      // ================= LOCATION =================

      final place = findSwapLocation(
        selectedLocation!,
      );

      // ================= SAVE REQUEST =================

      await db.collection('requests').add({
        // Requested book

        'bookId': widget.bookId,

        'bookName':
            requestedBookData['bookName'] ?? widget.bookName,

        // Users

        'senderId': user.uid,

        'receiverId': widget.ownerId,

        'requesterName': senderName.isEmpty
            ? 'A reader'
            : senderName,

        // Offered books

        'offeredBookIds': ids,

        'selectedOfferedBookId': ids.single,

        // Original meeting

        'meetingDateTime': Timestamp.fromDate(meeting),

        'locationName': place.name,

        'locationArea': place.area,

        'locationMapUrl': place.mapUrl,

        // Request status

        'status': 'pending',

        'waitingForId': widget.ownerId,

        // Reschedule fields

        'proposedMeetingDateTime': null,

        'proposedLocationName': null,

        'proposedLocationArea': null,

        'proposedLocationMapUrl': null,

        'proposedBy': null,

        // ================= SWAP CONFIRMATION =================

        // Sender confirms after the physical exchange.

        'senderConfirmed': false,

        // Receiver confirms after the physical exchange.

        'receiverConfirmed': false,

        // Set only when BOTH users confirm.

        'completedAt': null,

        // ================= TIMESTAMPS =================

        'createdAt': FieldValue.serverTimestamp(),

        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      message('Swap request sent successfully!');

      Navigator.pop(context);
    }

    // ================= FIREBASE ERROR =================

    on FirebaseException catch (e) {
      message(
        'Firebase error: ${e.message ?? e.code}',
      );
    }

    // ================= GENERAL ERROR =================

    catch (e) {
      message(
        'Could not send request: $e',
      );
    }

    // ================= FINALLY =================

    finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ================= BOOK COVER =================

  Widget cover(dynamic value) {
    try {
      if (value is String && value.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.memory(
            base64Decode(value),
            width: 50.w,
            height: 65.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.menu_book,
                color: brown,
              );
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Book image error: $e');
    }

    return const Icon(
      Icons.menu_book,
      color: brown,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Send Swap Request',
          style: TextStyle(
            color: dark,
            fontSize: 21.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
      ),

      body: uid == null
          ? const Center(
              child: Text('Please sign in first'),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 20.h,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= HEADER =================

                  Text(
                    'Requesting: ${widget.bookName}',
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    'Choose your meeting details and offer '
                    'books from your shelf.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF8B7464),
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 25.h),

                  // ================= DATE =================

                  Text(
                    'Meeting Date',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  OutlinedButton.icon(
                    onPressed: saving ? null : pickDate,
                    icon: const Icon(
                      Icons.calendar_month,
                      color: brown,
                    ),
                    label: Text(
                      selectedDate == null
                          ? 'Choose Date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: const TextStyle(
                        color: brown,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // ================= TIME =================

                  Text(
                    'Meeting Time',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  OutlinedButton.icon(
                    onPressed: saving ? null : pickTime,
                    icon: const Icon(
                      Icons.access_time,
                      color: brown,
                    ),
                    label: Text(
                      selectedTime?.format(context) ??
                          'Choose Time',
                      style: const TextStyle(
                        color: brown,
                      ),
                    ),
                  ),

                  SizedBox(height: 25.h),

                  // ================= LOCATIONS =================

                  Text(
                    'Trusted Meeting Location',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    'Select one of our suggested public places.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF8B7464),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  ...swapLocations.map((place) {
                    final bool isSelected =
                        selectedLocation == place.name;

                    return Card(
                      margin: EdgeInsets.only(bottom: 9.h),

                      color: isSelected
                          ? peach
                          : Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14.r),
                        side: BorderSide(
                          color: isSelected
                              ? brown
                              : borderColor,
                        ),
                      ),

                      child: RadioListTile<String>(
                        activeColor: brown,

                        value: place.name,

                        groupValue: selectedLocation,

                        title: Text(
                          place.name,
                          style: TextStyle(
                            color: dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),

                        subtitle: Text(
                          place.area,
                          style: TextStyle(
                            fontSize: 12.sp,
                          ),
                        ),

                        onChanged: saving
                            ? null
                            : (value) {
                                setState(() {
                                  selectedLocation = value;
                                });
                              },
                      ),
                    );
                  }),

                  SizedBox(height: 25.h),

                  // ================= OFFER BOOKS =================

                  Text(
                    'Offer Your Books',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),

                  SizedBox(height: 7.h),

                  Text(
                    'Choose one available book. '
                    'This book will be offered in exchange.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF8B7464),
                    ),
                  ),

                  SizedBox(height: 15.h),

                  // ================= USER BOOKS =================

                  StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: db
                        .collection('books')
                        .where(
                          'ownerId',
                          isEqualTo: uid,
                        )
                        .snapshots(),

                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Error loading your books: ${snapshot.error}',
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: brown,
                          ),
                        );
                      }

                      // Hide swapped books from offered choices.

                      final books =
                          snapshot.data!.docs.where((book) {
                        final data = book.data();

                        return data['isSwapped'] != true;
                      }).toList();

                      if (books.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: fieldColor,
                            borderRadius:
                                BorderRadius.circular(14.r),
                            border: Border.all(
                              color: borderColor,
                            ),
                          ),
                          child: const Text(
                            'You have no available books to offer. '
                            'Please add a book to your shelf first.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Column(
                        children: books.map((book) {
                          final data = book.data();

                          final bool checked =
                              offeredIds.contains(book.id);

                          return Card(
                            margin:
                                EdgeInsets.only(bottom: 10.h),

                            color: checked
                                ? peach
                                : Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14.r),
                              side: BorderSide(
                                color: checked
                                    ? brown
                                    : borderColor,
                              ),
                            ),

                            child: CheckboxListTile(
                              activeColor: brown,

                              value: checked,

                              secondary: cover(
                                data['bookImage'],
                              ),

                              title: Text(
                                '${data['bookName'] ?? 'Book'}',
                                style: TextStyle(
                                  color: dark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),

                              subtitle: Text(
                                '${data['bookType'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                ),
                              ),

                              onChanged: saving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          offeredIds.clear();
                                          offeredIds.add(
                                            book.id,
                                          );
                                        } else {
                                          offeredIds.remove(
                                            book.id,
                                          );
                                        }
                                      });
                                    },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  SizedBox(height: 12.h),

                  Text(
                    '${offeredIds.length} / 1 book selected',
                    style: TextStyle(
                      color: brown,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // ================= SEND BUTTON =================

                  SizedBox(
                    width: double.infinity,
                    height: 55.h,

                    child: ElevatedButton(
                      onPressed:
                          saving ? null : sendRequest,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        disabledBackgroundColor:
                            brown.withOpacity(0.6),
                        foregroundColor: Colors.white,
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15.r),
                        ),
                      ),

                      child: saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
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
                                  Icons.send_outlined,
                                  size: 20.sp,
                                ),

                                SizedBox(width: 10.w),

                                Text(
                                  'Send Request',
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
    );
  }
}
