import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentModel {
  const CommunityCommentModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorCropType,
    required this.authorLocation,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String authorCropType;
  final String authorLocation;
  final String body;
  final DateTime createdAt;

  factory CommunityCommentModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return CommunityCommentModel(
      id: id,
      authorUid: map['authorUid']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'Farmer',
      authorCropType: map['authorCropType']?.toString() ?? '',
      authorLocation: map['authorLocation']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorCropType': authorCropType,
      'authorLocation': authorLocation,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
