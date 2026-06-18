import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_disease_detector/models/community_post_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommunityPostModel', () {
    test('parses firestore payload and exposes filters', () {
      final post = CommunityPostModel.fromMap('post-1', {
        'authorUid': 'user-1',
        'authorName': 'Kashish',
        'authorCropType': 'Tomato',
        'authorLocation': 'Lucknow',
        'title': 'Leaf spots increasing after humidity',
        'body': 'Need help identifying whether this is early blight.',
        'topic': 'Disease',
        'postType': 'question',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 6, 8)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 6, 9)),
        'likedBy': ['user-2'],
        'likesCount': 1,
        'commentsCount': 3,
        'isResolved': true,
      });

      expect(post.id, 'post-1');
      expect(post.typeLabel, 'Question');
      expect(post.matchesTypeFilter('Questions'), isTrue);
      expect(post.matchesTypeFilter('Tips'), isFalse);
      expect(post.matchesTopicFilter('Disease'), isTrue);
      expect(post.isLikedBy('user-2'), isTrue);
      expect(post.commentsCount, 3);
      expect(post.isResolved, isTrue);
    });

    test('falls back safely for incomplete documents', () {
      final post = CommunityPostModel.fromMap('post-2', {
        'title': 'Quick note',
        'body': 'Observe the lower leaves first.',
      });

      expect(post.authorName, 'Farmer');
      expect(post.typeLabel, 'Question');
      expect(post.matchesTopicFilter('All'), isTrue);
      expect(post.likesCount, 0);
      expect(post.commentsCount, 0);
    });
  });
}
