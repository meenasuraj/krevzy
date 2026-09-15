import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomRule {
  final String id;
  final String roomId;
  final String title;
  final String description;
  final String createdBy;
  final String status;
  final bool isActive;
  final DateTime? createdAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? updatedAt;

  const ChatRoomRule({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.status,
    required this.isActive,
    this.createdAt,
    this.approvedBy,
    this.approvedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.updatedAt,
  });

  factory ChatRoomRule.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return ChatRoomRule(
      id: document.id,
      roomId: (data['roomId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      isActive: data['isActive'] == true,
      createdAt: _timestamp(data['createdAt']),
      approvedBy: data['approvedBy']?.toString(),
      approvedAt: _timestamp(data['approvedAt']),
      reviewedBy: data['reviewedBy']?.toString(),
      reviewedAt: _timestamp(data['reviewedAt']),
      updatedAt: _timestamp(data['updatedAt']),
    );
  }

  bool get isPending => status == 'pending';

  bool get isRejected => status == 'rejected';

  bool get isInactive => status == 'inactive';

  static DateTime? _timestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
