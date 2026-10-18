
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwapCompletion {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  static Future<void> confirmSwap(String requestId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please sign in first');
    }

    final requestRef =
        _db.collection('requests').doc(requestId);

    await _db.runTransaction((transaction) async {
      // Read the request first.
      final requestSnapshot =
          await transaction.get(requestRef);

      if (!requestSnapshot.exists) {
        throw Exception('Request not found');
      }

      final request = requestSnapshot.data()!;

      final String senderId = request['senderId'];
      final String receiverId = request['receiverId'];

      final bool isSender = user.uid == senderId;
      final bool isReceiver = user.uid == receiverId;

      if (!isSender && !isReceiver) {
        throw Exception('You are not part of this swap');
      }

      if (request['status'] == 'completed') {
        throw Exception('This swap is already completed');
      }

      if (request['status'] != 'accepted') {
        throw Exception(
          'The request must be accepted before confirmation',
        );
      }

      final String requestedBookId = request['bookId'];

      final String? offeredBookId =
          request['selectedOfferedBookId'] as String?;

      if (offeredBookId == null || offeredBookId.isEmpty) {
        throw Exception('No offered book was selected');
      }

      final requestedBookRef =
          _db.collection('books').doc(requestedBookId);

      final offeredBookRef =
          _db.collection('books').doc(offeredBookId);

      // All reads happen before any write.
      final requestedBookSnapshot =
          await transaction.get(requestedBookRef);

      final offeredBookSnapshot =
          await transaction.get(offeredBookRef);

      if (!requestedBookSnapshot.exists ||
          !offeredBookSnapshot.exists) {
        throw Exception('One of the books is unavailable');
      }

      final requestedBook = requestedBookSnapshot.data()!;
      final offeredBook = offeredBookSnapshot.data()!;

      if (requestedBook['ownerId'] != receiverId ||
          offeredBook['ownerId'] != senderId) {
        throw Exception('Book ownership has changed');
      }

      if (requestedBook['isSwapped'] == true ||
          offeredBook['isSwapped'] == true) {
        throw Exception('One of these books is already swapped');
      }

      bool senderConfirmed =
          request['senderConfirmed'] == true;

      bool receiverConfirmed =
          request['receiverConfirmed'] == true;

      if (isSender) {
        if (senderConfirmed) {
          throw Exception('You already confirmed this swap');
        }

        senderConfirmed = true;
      }

      if (isReceiver) {
        if (receiverConfirmed) {
          throw Exception('You already confirmed this swap');
        }

        receiverConfirmed = true;
      }

      final bool bothConfirmed =
          senderConfirmed && receiverConfirmed;

      // Update the request.
      transaction.update(requestRef, {
        'senderConfirmed': senderConfirmed,
        'receiverConfirmed': receiverConfirmed,
        'status': bothConfirmed ? 'completed' : 'accepted',
        'completedAt': bothConfirmed
            ? FieldValue.serverTimestamp()
            : null,
        'waitingForId': bothConfirmed ? null : (
          senderConfirmed ? receiverId : senderId
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark BOTH books as swapped only after both confirm.
      if (bothConfirmed) {
        transaction.update(requestedBookRef, {
          'isSwapped': true,
          'swappedAt': FieldValue.serverTimestamp(),
          'swapRequestId': requestId,
        });

        transaction.update(offeredBookRef, {
          'isSwapped': true,
          'swappedAt': FieldValue.serverTimestamp(),
          'swapRequestId': requestId,
        });
      }
    });
  }
}
