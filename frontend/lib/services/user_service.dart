import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile_model.dart';

class UserService {
  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  static Future<void> createOrUpdateProfile(UserProfileModel profile) async {
    await _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  static Future<UserProfileModel?> getProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserProfileModel.fromMap(snapshot.data()!);
  }

  static Stream<UserProfileModel?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfileModel.fromMap(snapshot.data()!);
    });
  }

  static Future<void> addScanHistory({
    required String uid,
    required String predictedClass,
    required double confidence,
    required DateTime scannedAt,
    String predictionSource = 'cloud',
    String diagnosisStatus = 'accepted',
    bool syncPending = false,
    String? diagnosisNote,
  }) async {
    await _users.doc(uid).collection('scan_history').add({
      'predictedClass': predictedClass,
      'confidence': confidence,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'predictionSource': predictionSource,
      'diagnosisStatus': diagnosisStatus,
      'syncPending': syncPending,
      if (diagnosisNote != null && diagnosisNote.trim().isNotEmpty)
        'diagnosisNote': diagnosisNote.trim(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> scanHistoryStream(
      String uid) {
    return _users
        .doc(uid)
        .collection('scan_history')
        .orderBy('scannedAt', descending: true)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> getRecentScanHistory(
    String uid, {
    int limit = 10,
  }) async {
    final snapshot = await _users
        .doc(uid)
        .collection('scan_history')
        .orderBy('scannedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    await _users.doc(uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> voiceQueryStream(
      String uid) {
    return _users
        .doc(uid)
        .collection('voice_queries')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
  }
}
