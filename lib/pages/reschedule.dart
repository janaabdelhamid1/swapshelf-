
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swapshelf_app/pages/location/swap_location.dart';

class ReschedulePage extends StatefulWidget {
  final String requestId;

  const ReschedulePage({
    super.key,
    required this.requestId,
  });

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  static const bg = Color(0xFFFFF8EF);
  static const brown = Color(0xFF713E29);

  final db = FirebaseFirestore.instance;

  DateTime? date;
  TimeOfDay? time;
  String? locationName;
  String? selectedBookId;

  bool initialized = false;
  bool saving = false;

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> chooseDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final current = date != null && !date!.isBefore(today)
        ? date!
        : today;

    final result = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (result != null && mounted) {
      setState(() => date = result);
    }
  }

  Future<void> chooseTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
    );

    if (result != null && mounted) {
      setState(() => time = result);
    }
  }

  Future<void> submitProposal() async {
    if (saving) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null ||
        date == null ||
        time == null ||
        locationName == null) {
      message('Complete all meeting details');
      return;
    }

    final newMeeting = DateTime(
      date!.year,
      date!.month,
      date!.day,
      time!.hour,
      time!.minute,
    );

    if (!newMeeting.isAfter(DateTime.now())) {
      message('Choose a future date and time');
      return;
    }

    setState(() => saving = true);

    try {
      final ref = db.collection('requests').doc(widget.requestId);
      final place = findSwapLocation(locationName!);

      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('Request not found');
        }

        final request = snapshot.data()!;
        final sender = request['senderId'] as String;
        final receiver = request['receiverId'] as String;
        final status = request['status'];

        if (request['waitingForId'] != uid ||
            (status != 'pending' &&
                status != 'reschedule_proposed')) {
          throw Exception('It is not your turn to respond');
        }

        if (uid != sender && uid != receiver) {
          throw Exception('Not authorized');
        }

        final offered = List<String>.from(
          request['offeredBookIds'] ?? [],
        );

        final chosen = uid == receiver
            ? (request['selectedOfferedBookId'] as String? ??
                selectedBookId)
            : request['selectedOfferedBookId'] as String?;

        if (chosen == null || !offered.contains(chosen)) {
          throw Exception('Select a valid offered book');
        }

        final chosenSnapshot = await transaction.get(
          db.collection('books').doc(chosen),
        );

        if (!chosenSnapshot.exists ||
            chosenSnapshot.data()?['ownerId'] != sender) {
          throw Exception('Selected book is unavailable');
        }

        transaction.update(ref, {
          'status': 'reschedule_proposed',
          'selectedOfferedBookId': chosen,
          'proposedMeetingDateTime': Timestamp.fromDate(newMeeting),
          'proposedLocationName': place.name,
          'proposedLocationArea': place.area,
          'proposedLocationMapUrl': place.mapUrl,
          'proposedBy': uid,
          'waitingForId': uid == sender ? receiver : sender,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      message('New proposal sent');
      Navigator.pop(context);
    } catch (e) {
      message('Could not reschedule: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Reschedule Swap'),
        backgroundColor: bg,
        foregroundColor: brown,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.data!.exists || uid == null) {
            return const Center(child: Text('Request not found'));
          }

          final request = snapshot.data!.data()!;

          if (uid != request['senderId'] &&
              uid != request['receiverId']) {
            return const Center(child: Text('Not authorized'));
          }

          final canRespond =
              request['waitingForId'] == uid &&
              (request['status'] == 'pending' ||
                  request['status'] == 'reschedule_proposed');

          if (!initialized) {
            initialized = true;

            final isProposal =
                request['status'] == 'reschedule_proposed';

            final timestamp = isProposal
                ? request['proposedMeetingDateTime']
                : request['meetingDateTime'];

            if (timestamp is Timestamp) {
              final value = timestamp.toDate();
              date = value;
              time = TimeOfDay.fromDateTime(value);
            }

            locationName = isProposal
                ? request['proposedLocationName'] as String?
                : request['locationName'] as String?;

            selectedBookId =
                request['selectedOfferedBookId'] as String?;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggest a new meeting',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: brown,
                  ),
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: canRespond && !saving
                      ? chooseDate
                      : null,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    date == null
                        ? 'Choose Date'
                        : '${date!.day}/${date!.month}/${date!.year}',
                  ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: canRespond && !saving
                      ? chooseTime
                      : null,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    time?.format(context) ?? 'Choose Time',
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'New Meeting Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                ...swapLocations.map((place) {
                  return Card(
                    color: Colors.white,
                    child: RadioListTile<String>(
                      activeColor: brown,
                      title: Text(place.name),
                      subtitle: Text(place.area),
                      value: place.name,
                      groupValue: locationName,
                      onChanged: canRespond && !saving
                          ? (value) {
                              setState(() => locationName = value);
                            }
                          : null,
                    ),
                  );
                }),

                const SizedBox(height: 20),

                if (uid == request['receiverId']) ...[
                  const Text(
                    'Choose a Book From the Offer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  ...List<String>.from(
                    request['offeredBookIds'] ?? [],
                  ).map((id) {
                    return FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      future: db.collection('books').doc(id).get(),
                      builder: (context, bookSnapshot) {
                        if (!bookSnapshot.hasData ||
                            !bookSnapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final book = bookSnapshot.data!.data()!;

                        return Card(
                          child: RadioListTile<String>(
                            activeColor: brown,
                            value: id,
                            groupValue: selectedBookId,
                            title: Text(
                              '${book['bookName'] ?? 'Book'}',
                            ),
                            subtitle: Text(
                              '${book['bookType'] ?? ''}',
                            ),
                            onChanged: canRespond &&
                                    !saving &&
                                    request['selectedOfferedBookId'] == null
                                ? (value) {
                                    setState(() {
                                      selectedBookId = value;
                                    });
                                  }
                                : null,
                          ),
                        );
                      },
                    );
                  }),
                ] else
                  const Text(
                    'The book chosen by the owner will stay selected.',
                  ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: canRespond && !saving
                        ? submitProposal
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      saving
                          ? 'Sending...'
                          : 'Send Reschedule Proposal',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
