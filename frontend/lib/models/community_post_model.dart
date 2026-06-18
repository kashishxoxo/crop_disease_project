import 'package:cloud_firestore/cloud_firestore.dart';

enum CommunityPostType { question, tip, alert }

class CommunityPostModel {
  const CommunityPostModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorCropType,
    required this.authorLocation,
    required this.title,
    required this.body,
    required this.topic,
    required this.postType,
    required this.createdAt,
    required this.updatedAt,
    required this.likedBy,
    required this.likesCount,
    required this.commentsCount,
    required this.isResolved,
  });

  static const List<String> topics = [
    'All',
    'Disease',
    'Prevention',
    'Pests',
    'Soil',
    'Irrigation',
    'Nutrition',
    'Harvest',
  ];

  static const List<String> typeFilters = [
    'All',
    'Questions',
    'Tips',
    'Alerts',
  ];

  final String id;
  final String authorUid;
  final String authorName;
  final String authorCropType;
  final String authorLocation;
  final String title;
  final String body;
  final String topic;
  final CommunityPostType postType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likedBy;
  final int likesCount;
  final int commentsCount;
  final bool isResolved;

  String get typeLabel {
    switch (postType) {
      case CommunityPostType.question:
        return 'Question';
      case CommunityPostType.tip:
        return 'Tip';
      case CommunityPostType.alert:
        return 'Alert';
    }
  }

  bool isLikedBy(String uid) => likedBy.contains(uid);

  bool matchesTypeFilter(String filter) {
    if (filter == 'All') return true;
    if (filter == 'Questions') return postType == CommunityPostType.question;
    if (filter == 'Tips') return postType == CommunityPostType.tip;
    if (filter == 'Alerts') return postType == CommunityPostType.alert;
    return true;
  }

  bool matchesTopicFilter(String filter) {
    if (filter == 'All') return true;
    return topic.toLowerCase() == filter.toLowerCase();
  }

  factory CommunityPostModel.fromMap(String id, Map<String, dynamic> map) {
    final likedBy = List<String>.from(
      (map['likedBy'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString()),
    );
    final likesCount = (map['likesCount'] as num?)?.toInt() ?? likedBy.length;

    return CommunityPostModel(
      id: id,
      authorUid: map['authorUid']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'Farmer',
      authorCropType: map['authorCropType']?.toString() ?? '',
      authorLocation: map['authorLocation']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      topic: map['topic']?.toString() ?? 'Disease',
      postType: _parseType(map['postType']?.toString()),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      likedBy: likedBy,
      likesCount: likesCount,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      isResolved: map['isResolved'] == true,
    );
  }

  static CommunityPostType _parseType(String? value) {
    switch (value) {
      case 'tip':
        return CommunityPostType.tip;
      case 'alert':
        return CommunityPostType.alert;
      case 'question':
      default:
        return CommunityPostType.question;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
