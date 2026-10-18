
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swapshelf_app/pages/swap_completion.dart';
import 'package:url_launcher/url_launcher.dart';

class MyShelfPage extends StatefulWidget {
  const MyShelfPage({super.key});

  @override
  State<MyShelfPage> createState() => _MyShelfPageState();
}

class _MyShelfPageState extends State<MyShelfPage> {
  static const bg = Color(0xFFFFF8EF);
  static const brown = Color(0xFF713E29);
  static const dark = Color(0xFF30180F);
  static const peach = Color(0xFFEAC8B0);

  final db = FirebaseFirestore.instance;

  int tab = 0;
  String? busyId;
  final Map<String, String> selectedBooks = {};

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget cover(dynamic value, {double width = 65}) {
    try {
      if (value is String && value.isNotEmpty) {
        return Image.memory(
          base64Decode(value),
          width: width,
          height: 85,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.menu_book),
        );
      }
    } catch (_) {}

    return SizedBox(
      width: width,
      height: 85,
      child: const Icon(Icons.menu_book, color: brown),
    );
  }

  Future<void> openMap(dynamic url) async {
    if (url is! String || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> perform(
    String id,
    Future<void> Function() action,
  ) async {
    if (busyId != null) return;

    setState(() => busyId = id);

    try {
      await action();
      message('Updated successfully');
    } catch (e) {
      message('Could not update request: $e');
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }

  Future<void> rejectRequest(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = db.collection('requests').doc(id);

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Request not found');

      final d = snap.data()!;

      if (d['waitingForId'] != uid ||
          (d['status'] != 'pending' &&
              d['status'] != 'reschedule_proposed')) {
        throw Exception('You cannot reject this request now');
      }

      tx.update(ref, {
        'status': 'rejected',
        'waitingForId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> acceptRequest(
    String id,
    String? chosenBookId,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = db.collection('requests').doc(id);

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Request not found');

      final d = snap.data()!;
      final sender = d['senderId'] as String;
      final receiver = d['receiverId'] as String;
      final status = d['status'];

      if (d['waitingForId'] != uid ||
          (status != 'pending' &&
              status != 'reschedule_proposed')) {
        throw Exception('It is not your turn');
      }

      if (uid != sender && uid != receiver) {
        throw Exception('Not authorized');
      }

      final String? selected =
          d['selectedOfferedBookId'] as String? ??
              (uid == receiver ? chosenBookId : null);

      final offered =
          List<String>.from(d['offeredBookIds'] ?? []);

      if (selected == null || !offered.contains(selected)) {
        throw Exception('Choose one of the offered books');
      }

      final requestedRef =
          db.collection('books').doc(d['bookId'] as String);

      final offeredRef =
          db.collection('books').doc(selected);

      final requestedSnap = await tx.get(requestedRef);
      final offeredSnap = await tx.get(offeredRef);

      if (!requestedSnap.exists ||
          !offeredSnap.exists ||
          requestedSnap.data()?['ownerId'] != receiver ||
          offeredSnap.data()?['ownerId'] != sender ||
          requestedSnap.data()?['isSwapped'] == true ||
          offeredSnap.data()?['isSwapped'] == true) {
        throw Exception('One of the books is unavailable');
      }

      final Map<String, dynamic> update = {
        'status': 'accepted',
        'selectedOfferedBookId': selected,
        'senderConfirmed': false,
        'receiverConfirmed': false,
        'completedAt': null,
        'waitingForId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'reschedule_proposed') {
        if (d['proposedBy'] == uid) {
          throw Exception('You cannot accept your own proposal');
        }

        update.addAll({
          'meetingDateTime': d['proposedMeetingDateTime'],
          'locationName': d['proposedLocationName'],
          'locationArea': d['proposedLocationArea'],
          'locationMapUrl': d['proposedLocationMapUrl'],
          'proposedMeetingDateTime': null,
          'proposedLocationName': null,
          'proposedLocationArea': null,
          'proposedLocationMapUrl': null,
          'proposedBy': null,
        });
      }

      tx.update(ref, update);
    });
  }

  Widget myBooks(String uid) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('books')
          .where('ownerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: brown),
          );
        }

        final books = snapshot.data!.docs;

        if (books.isEmpty) {
          return const Center(
            child: Text('Your shelf is empty'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final d = books[index].data();
            final swapped = d['isSwapped'] == true;

            return Card(
              color: Colors.white,
              margin: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    cover(d['bookImage']),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${d['bookName'] ?? 'Book'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dark,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text('${d['bookType'] ?? ''}'),
                          SizedBox(height: 9.h),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: swapped
                                  ? const Color(0xFFDCEEDC)
                                  : peach,
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                            child: Text(
                              swapped ? '✓ Swapped' : 'Available',
                              style: TextStyle(
                                color: swapped
                                    ? const Color(0xFF286B36)
                                    : dark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget offeredBooks(
    Map<String, dynamic> request,
    String requestId,
    bool canChoose,
  ) {
    final ids =
        List<String>.from(request['offeredBookIds'] ?? []);

    final fixedId =
        request['selectedOfferedBookId'] as String?;

    final selected = fixedId ?? selectedBooks[requestId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Offered books:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...ids.map((id) {
          return FutureBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            future: db.collection('books').doc(id).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final book = snapshot.data!.data()!;

              return RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${book['bookName'] ?? 'Book'}'),
                subtitle: Text('${book['bookType'] ?? ''}'),
                secondary: cover(
                  book['bookImage'],
                  width: 38,
                ),
                value: id,
                groupValue: selected,
                activeColor: brown,
                onChanged: canChoose && fixedId == null
                    ? (value) {
                        setState(() {
                          selectedBooks[requestId] = value!;
                        });
                      }
                    : null,
              );
            },
          );
        }),
      ],
    );
  }

  Widget requestCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String uid,
  ) {
    final d = doc.data();

    final status = '${d['status'] ?? 'pending'}';
    final isSender = d['senderId'] == uid;
    final isReceiver = d['receiverId'] == uid;

    final canRespond =
        d['waitingForId'] == uid &&
        (status == 'pending' ||
            status == 'reschedule_proposed');

    final senderConfirmed =
        d['senderConfirmed'] == true;

    final receiverConfirmed =
        d['receiverConfirmed'] == true;

    final myConfirmed = isSender
        ? senderConfirmed
        : receiverConfirmed;

    final proposed =
        status == 'reschedule_proposed';

    final dateValue = proposed
        ? d['proposedMeetingDateTime']
        : d['meetingDateTime'];

    final location = proposed
        ? d['proposedLocationName']
        : d['locationName'];

    final mapUrl = proposed
        ? d['proposedLocationMapUrl']
        : d['locationMapUrl'];

    String dateText = 'Not specified';

    if (dateValue is Timestamp) {
      final date = dateValue.toDate();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      dateText =
          '${date.day}/${date.month}/${date.year} '
          '$hour:$minute';
    }

    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 14.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${d['bookName'] ?? 'Book'}',
              style: TextStyle(
                color: dark,
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 7.h),
            Text('Status: $status'),
            SizedBox(height: 5.h),
            Text('Meeting: $dateText'),
            SizedBox(height: 5.h),
            Text('Location: ${location ?? 'Not selected'}'),
            TextButton.icon(
              onPressed: () => openMap(mapUrl),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open Map'),
            ),
            const Divider(),
            offeredBooks(
              d,
              doc.id,
              canRespond && isReceiver,
            ),
            SizedBox(height: 10.h),

            if (status == 'completed')
              const Text(
                '✓ Swap completed successfully!',
                style: TextStyle(
                  color: Color(0xFF286B36),
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (status == 'rejected')
              const Text('This request was rejected.'),

            if (status == 'accepted') ...[
              Text(
                'Your confirmation: '
                '${myConfirmed ? 'Confirmed ✓' : 'Pending'}',
              ),
              SizedBox(height: 5.h),
              Text(
                'Other person: '
                '${(isSender ? receiverConfirmed : senderConfirmed) ? 'Confirmed ✓' : 'Pending'}',
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: myConfirmed || busyId != null
                      ? null
                      : () => perform(
                            doc.id,
                            () => SwapCompletion.confirmSwap(
                              doc.id,
                            ),
                          ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    myConfirmed
                        ? 'Waiting for Other Person'
                        : 'Confirm Swap Completed',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            if (canRespond) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busyId != null
                          ? null
                          : () => perform(
                                doc.id,
                                () => acceptRequest(
                                  doc.id,
                                  selectedBooks[doc.id],
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busyId != null
                          ? null
                          : () => perform(
                                doc.id,
                                () => rejectRequest(doc.id),
                              ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'pending' ||
                status == 'reschedule_proposed')
              const Text(
                'Waiting for the other person to respond.',
              ),
          ],
        ),
      ),
    );
  }

  Widget requests(String uid, bool incoming) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('requests')
          .where(
            incoming ? 'receiverId' : 'senderId',
            isEqualTo: uid,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: brown),
          );
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          final aMillis = aTime is Timestamp
              ? aTime.millisecondsSinceEpoch
              : 0;

          final bMillis = bTime is Timestamp
              ? bTime.millisecondsSinceEpoch
              : 0;

          return bMillis.compareTo(aMillis);
        });

        if (docs.isEmpty) {
          return Center(
            child: Text(
              incoming
                  ? 'No incoming requests yet'
                  : 'No sent requests yet',
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(14.w),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return requestCard(docs[index], uid);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: bg,
        title: const Text(
          'My Shelf',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Please sign in first'))
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => tab = i);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    tab == i ? brown : peach,
                                foregroundColor:
                                    tab == i ? Colors.white : dark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                              ),
                              child: Text(
                                ['My Books', 'Incoming', 'Sent'][i],
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: tab,
                    children: [
                      myBooks(uid),
                      requests(uid, true),
                      requests(uid, false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
