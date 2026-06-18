import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addReminder({
    required String uid,
    required String title,
    required String disease,
    required String note,
    required DateTime scheduledFor,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('treatment_reminders')
        .add({
      'title': title,
      'disease': disease,
      'note': note,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> reminderStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('treatment_reminders')
        .orderBy('scheduledFor')
        .snapshots();
  }

  static Future<void> updateReminderStatus({
    required String uid,
    required String reminderId,
    required String status,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('treatment_reminders')
        .doc(reminderId)
        .set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteReminder({
    required String uid,
    required String reminderId,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('treatment_reminders')
        .doc(reminderId)
        .delete();
  }
}
