import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderPlaced,
  orderConfirmed,
  driverAssigned,
  driverNearby,
  orderDelivered,
  orderCancelled,
  paymentReceived,
  sellerApproved,
  sellerRejected,
  newProduct,
  promotion,
  systemAlert,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == (d['type'] ?? 'systemAlert'),
        orElse: () => NotificationType.systemAlert,
      ),
      data: d['data'],
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'data': data,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
