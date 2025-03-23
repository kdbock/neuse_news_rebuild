import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // 'article', 'event', 'weather', 'account', 'system'
  final String body;
  final String? title;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime createdAt;
  final bool isRead;
  final String userId;

  AppNotification({
    required this.id,
    required this.type,
    required this.body,
    this.title,
    this.actionLabel,
    this.actionRoute,
    required this.createdAt,
    required this.isRead,
    required this.userId,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: data['type'] ?? 'system',
      body: data['body'] ?? '',
      title: data['title'],
      actionLabel: data['actionLabel'],
      actionRoute: data['actionRoute'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'body': body,
      'title': title,
      'actionLabel': actionLabel,
      'actionRoute': actionRoute,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'userId': userId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? type,
    String? body,
    String? title,
    String? actionLabel,
    String? actionRoute,
    DateTime? createdAt,
    bool? isRead,
    String? userId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      body: body ?? this.body,
      title: title ?? this.title,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
    );
  }
}
