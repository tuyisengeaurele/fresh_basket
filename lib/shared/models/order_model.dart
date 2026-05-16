import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Safe helpers — accept Timestamp, ISO-8601 String, or null.
DateTime _parseTs(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

DateTime? _parseTsNullable(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  assigned,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
  failed,
}

enum PaymentMethod { cashOnDelivery, mobileMoney }

enum PaymentStatus { pending, paid, refunded, failed }

class OrderItem {
  final String productId;
  final String productName;
  final String productImageUrl;
  final String sellerId;
  final String sellerBusinessName;
  final double price;
  final String unit;
  final int quantity;
  final double subtotal;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.sellerId,
    required this.sellerBusinessName,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        productImageUrl: map['productImageUrl'] ?? '',
        sellerId: map['sellerId'] ?? '',
        sellerBusinessName: map['sellerBusinessName'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] ?? 'kg',
        quantity: map['quantity'] ?? 1,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'productImageUrl': productImageUrl,
        'sellerId': sellerId,
        'sellerBusinessName': sellerBusinessName,
        'price': price,
        'unit': unit,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}

class OrderTimeline {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;
  final String? actorId;

  const OrderTimeline({
    required this.status,
    required this.timestamp,
    this.note,
    this.actorId,
  });

  factory OrderTimeline.fromMap(Map<String, dynamic> map) => OrderTimeline(
        status: OrderStatus.values.firstWhere(
          (s) => s.name == (map['status'] ?? 'pending'),
          orElse: () => OrderStatus.pending,
        ),
        timestamp: _parseTs(map['timestamp']),
        note: map['note'],
        actorId: map['actorId'],
      );

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'note': note,
        'actorId': actorId,
      };
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final DeliveryAddress deliveryAddress;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? promoCode;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? driverLat;
  final double? driverLng;
  final String? estimatedDeliveryTime;
  final String? cancellationReason;
  final String? proofOfDeliveryUrl;
  final List<OrderTimeline> timeline;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? scheduledTime;
  final List<String> sellerIds;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.deliveryAddress,
    this.status = OrderStatus.pending,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.paymentStatus = PaymentStatus.pending,
    required this.subtotal,
    this.deliveryFee = 0,
    this.discount = 0,
    required this.total,
    this.promoCode,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverLat,
    this.driverLng,
    this.estimatedDeliveryTime,
    this.cancellationReason,
    this.proofOfDeliveryUrl,
    this.timeline = const [],
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.scheduledTime,
    required this.sellerIds,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      items: (data['items'] as List? ?? [])
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      deliveryAddress: DeliveryAddress.fromMap(
          data['deliveryAddress'] as Map<String, dynamic>? ?? {}),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == (data['paymentMethod'] ?? 'cashOnDelivery'),
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.name == (data['paymentStatus'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      promoCode: data['promoCode'],
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      driverLat: (data['driverLat'] as num?)?.toDouble(),
      driverLng: (data['driverLng'] as num?)?.toDouble(),
      estimatedDeliveryTime: data['estimatedDeliveryTime'],
      cancellationReason: data['cancellationReason'],
      proofOfDeliveryUrl: data['proofOfDeliveryUrl'],
      timeline: (data['timeline'] as List? ?? [])
          .map((t) => OrderTimeline.fromMap(t as Map<String, dynamic>))
          .toList(),
      createdAt: _parseTs(data['createdAt']),
      updatedAt: _parseTsNullable(data['updatedAt']),
      deliveredAt: _parseTsNullable(data['deliveredAt']),
      scheduledTime: data['scheduledTime'],
      sellerIds: List<String>.from(data['sellerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items.map((i) => i.toMap()).toList(),
        'deliveryAddress': deliveryAddress.toMap(),
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'promoCode': promoCode,
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'driverLat': driverLat,
        'driverLng': driverLng,
        'estimatedDeliveryTime': estimatedDeliveryTime,
        'cancellationReason': cancellationReason,
        'proofOfDeliveryUrl': proofOfDeliveryUrl,
        'timeline': timeline.map((t) => t.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'deliveredAt':
            deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
        'scheduledTime': scheduledTime,
        'sellerIds': sellerIds,
      };

  bool get isActive =>
      status != OrderStatus.delivered &&
      status != OrderStatus.cancelled &&
      status != OrderStatus.failed;

  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  String get orderNumber =>
      '#${id.substring(0, 8).toUpperCase()}';

  OrderModel copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? driverId,
    String? driverName,
    String? driverPhone,
    double? driverLat,
    double? driverLng,
    String? estimatedDeliveryTime,
    String? cancellationReason,
    String? proofOfDeliveryUrl,
    List<OrderTimeline>? timeline,
    DateTime? updatedAt,
    DateTime? deliveredAt,
  }) =>
      OrderModel(
        id: id,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        deliveryAddress: deliveryAddress,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        total: total,
        promoCode: promoCode,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        driverPhone: driverPhone ?? this.driverPhone,
        driverLat: driverLat ?? this.driverLat,
        driverLng: driverLng ?? this.driverLng,
        estimatedDeliveryTime:
            estimatedDeliveryTime ?? this.estimatedDeliveryTime,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        proofOfDeliveryUrl: proofOfDeliveryUrl ?? this.proofOfDeliveryUrl,
        timeline: timeline ?? this.timeline,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        scheduledTime: scheduledTime,
        sellerIds: sellerIds,
      );
}
