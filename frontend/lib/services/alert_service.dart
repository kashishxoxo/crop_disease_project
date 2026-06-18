import 'package:cloud_firestore/cloud_firestore.dart';

class AlertService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addUserAlert({
    required String uid,
    required String level,
    required String title,
    required String detail,
  }) async {
    await _firestore.collection('users').doc(uid).collection('alerts').add({
      'level': level,
      'title': title,
      'detail': detail,
      'createdAt': Timestamp.now(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> alertStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
