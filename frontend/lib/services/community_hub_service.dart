import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_comment_model.dart';
import '../models/community_post_model.dart';
import '../models/user_profile_model.dart';

class CommunityHubService {
  static final CollectionReference<Map<String, dynamic>> _posts =
      FirebaseFirestore.instance.collection('community_posts');

  static Stream<List<CommunityPostModel>> postsStream() {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityPostModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  static Stream<List<CommunityCommentModel>> commentsStream(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CommunityCommentModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  static Future<void> createPost({
    required String uid,
    required UserProfileModel? profile,
    required String title,
    required String body,
    required String topic,
    required CommunityPostType postType,
  }) async {
    await _posts.add({
      'authorUid': uid,
      'authorName': _authorName(profile),
      'authorCropType': profile?.cropType.trim() ?? '',
      'authorLocation': profile?.location.trim() ?? '',
      'title': title.trim(),
      'body': body.trim(),
      'topic': topic,
      'postType': postType.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likedBy': <String>[],
      'likesCount': 0,
      'commentsCount': 0,
      'isResolved': false,
    });
  }

  static Future<void> toggleLike({
    required String postId,
    required String uid,
  }) async {
    final ref = _posts.doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final likedBy = List<String>.from(
        (data['likedBy'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString()),
      );

      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }

      transaction.update(ref, {
        'likedBy': likedBy,
        'likesCount': likedBy.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> addComment({
    required String postId,
    required String uid,
    required UserProfileModel? profile,
    required String body,
  }) async {
    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc();
    final comment = CommunityCommentModel(
      id: commentRef.id,
      authorUid: uid,
      authorName: _authorName(profile),
      authorCropType: profile?.cropType.trim() ?? '',
      authorLocation: profile?.location.trim() ?? '',
      body: body.trim(),
      createdAt: DateTime.now(),
    );

    final batch = FirebaseFirestore.instance.batch();
    batch.set(commentRef, comment.toMap());
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<void> setResolved({
    required String postId,
    required bool resolved,
  }) async {
    await _posts.doc(postId).set({
      'isResolved': resolved,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _authorName(UserProfileModel? profile) {
    final name = profile?.name.trim() ?? '';
    return name.isEmpty ? 'Farmer' : name;
  }
}
