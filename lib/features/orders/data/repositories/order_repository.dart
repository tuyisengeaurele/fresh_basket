import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/cart_model.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/user_model.dart';

class OrderRepository {
  Future<String> placeOrder({
    required UserModel customer,
    required CartModel cart,
    required DeliveryAddress address,
    String? scheduledTime,
  }) async {
    final items = cart.items
        .map((i) => OrderItem(
              productId: i.product.id,
              productName: i.product.name,
              productImageUrl: i.product.firstImageUrl,
              sellerId: i.product.sellerId,
              sellerBusinessName: i.product.sellerBusinessName,
              price: i.product.price,
              unit: i.product.unit,
              quantity: i.quantity,
              subtotal: i.subtotal,
            ))
        .toList();

    final sellerIds =
        items.map((i) => i.sellerId).toSet().toList();

    final order = OrderModel(
      id: '',
      customerId: customer.uid,
      customerName: customer.fullName,
      customerPhone: customer.phone ?? '',
      items: items,
      deliveryAddress: address,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      discount: cart.discount,
      total: cart.total,
      promoCode: cart.promoCode,
      timeline: [
        OrderTimeline(
          status: OrderStatus.pending,
          timestamp: DateTime.now(),
          note: 'Order placed by customer',
          actorId: customer.uid,
        ),
      ],
      createdAt: DateTime.now(),
      scheduledTime: scheduledTime,
      sellerIds: sellerIds,
    );

    final doc =
        await FirebaseService.orders.add(order.toMap());

    // Notify customer
    await NotificationService.saveNotification(
      userId: customer.uid,
      title: 'Order Placed!',
      body:
          'Your order ${doc.id.substring(0, 8).toUpperCase()} has been placed.',
      type: NotificationType.orderPlaced,
      data: {'orderId': doc.id},
    );

    // Notify sellers (Firestore + FCM push + email)
    for (final sellerId in sellerIds) {
      await NotificationService.saveNotification(
        userId: sellerId,
        title: 'New Order Received',
        body: 'You have a new order from ${customer.fullName}.',
        type: NotificationType.orderPlaced,
        data: {'orderId': doc.id},
      );
      await NotificationService.sendFcmPush(
        userId: sellerId,
        title: 'New Order Received',
        body: 'You have a new order from ${customer.fullName}.',
        data: {'orderId': doc.id, 'type': 'orderPlaced'},
      );
      // Email to seller
      try {
        final sellerDoc = await FirebaseService.users.doc(sellerId).get();
        final sellerEmail = sellerDoc.data()?['email'] as String?;
        final sellerName = sellerDoc.data()?['fullName'] as String? ?? 'Seller';
        if (sellerEmail != null) {
          await EmailService.sendSellerNewOrder(
            to: sellerEmail,
            sellerName: sellerName,
            customerName: customer.fullName,
            orderId: doc.id,
            total: cart.total,
            itemCount: items.length,
          );
        }
      } catch (e) {
        debugPrint('[Email] Seller new order email failed: $e');
      }
    }

    // FCM push to customer
    await NotificationService.sendFcmPush(
      userId: customer.uid,
      title: 'Order Placed!',
      body: 'Your order ${doc.id.substring(0, 8).toUpperCase()} has been placed successfully.',
      data: {'orderId': doc.id, 'type': 'orderPlaced'},
    );

    // Email confirmation to customer
    try {
      await EmailService.sendOrderConfirmation(
        to: customer.email,
        name: customer.fullName,
        orderId: doc.id,
        total: cart.total,
      );
    } catch (e) {
      debugPrint('[Email] Order confirmation failed: $e');
    }

    await FirebaseService.logAudit(
      action: 'order_placed',
      actorId: customer.uid,
      actorName: customer.fullName,
      targetId: doc.id,
      targetType: 'order',
    );

    return doc.id;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    required String actorId,
    String? note,
    String? cancellationReason,
    String? proofUrl,
  }) async {
    final timeline = OrderTimeline(
      status: newStatus,
      timestamp: DateTime.now(),
      note: note,
      actorId: actorId,
    );

    final updates = <String, dynamic>{
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline': FieldValue.arrayUnion([timeline.toMap()]),
    };

    if (cancellationReason != null) {
      updates['cancellationReason'] = cancellationReason;
    }
    if (proofUrl != null) {
      updates['proofOfDeliveryUrl'] = proofUrl;
    }
    if (newStatus == OrderStatus.delivered) {
      updates['deliveredAt'] = FieldValue.serverTimestamp();
    }

    await FirebaseService.orders.doc(orderId).update(updates);

    // ── Notify all parties ────────────────────────────────────────────────────
    try {
      final orderDoc = await FirebaseService.orders.doc(orderId).get();
      if (!orderDoc.exists) return;
      final data = orderDoc.data()!;

      final customerId = data['customerId'] as String?;
      final sellerIds =
          (data['sellerIds'] as List?)?.cast<String>() ?? <String>[];
      final driverId = data['driverId'] as String?;
      final customerName = data['customerName'] as String? ?? '';

      // Update driver stats when an order is delivered
      if (newStatus == OrderStatus.delivered && driverId != null) {
        final deliveryFee =
            (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
        try {
          await FirebaseService.driverProfiles.doc(driverId).update({
            'totalDeliveries': FieldValue.increment(1),
            'totalEarnings': FieldValue.increment(deliveryFee),
          });
        } catch (e) {
          debugPrint('[OrderRepo] Driver stats update failed: $e');
        }
      }
      final total = (data['total'] as num?)?.toDouble() ?? 0.0;

      // Fetch customer email for email notifications
      String? customerEmail;
      if (customerId != null) {
        try {
          final userDoc = await FirebaseService.users.doc(customerId).get();
          customerEmail = userDoc.data()?['email'] as String?;
        } catch (_) {}
      }

      final customerMsg = _customerStatusMessage(newStatus);
      final notifType = _statusNotifType(newStatus);

      // ── Customer notifications ────────────────────────────────────────────
      if (customerId != null) {
        await NotificationService.saveNotification(
          userId: customerId,
          title: 'Order Update',
          body: customerMsg,
          type: notifType,
          data: {'orderId': orderId},
        );
        await NotificationService.sendFcmPush(
          userId: customerId,
          title: 'Order Update',
          body: customerMsg,
          data: {'orderId': orderId, 'type': notifType.name},
        );

        // Emails for milestone statuses
        if (newStatus == OrderStatus.delivered && customerEmail != null) {
          try {
            await EmailService.sendOrderDelivered(
              to: customerEmail,
              name: customerName,
              orderId: orderId,
              total: total,
            );
          } catch (e) {
            debugPrint('[Email] Delivered email failed: $e');
          }
        }
        if (newStatus == OrderStatus.cancelled && customerEmail != null) {
          try {
            await EmailService.sendOrderCancelled(
              to: customerEmail,
              name: customerName,
              orderId: orderId,
              reason: cancellationReason,
            );
          } catch (e) {
            debugPrint('[Email] Cancelled email failed: $e');
          }
        }
      }

      // ── Seller notifications ──────────────────────────────────────────────
      // Sellers get in-app for all changes; push for delivered & cancelled
      final sellerMsg = _sellerStatusMessage(newStatus);
      final notifySellerByPush = newStatus == OrderStatus.delivered ||
          newStatus == OrderStatus.cancelled ||
          newStatus == OrderStatus.pickedUp;

      for (final sellerId in sellerIds) {
        await NotificationService.saveNotification(
          userId: sellerId,
          title: 'Order Update',
          body: sellerMsg,
          type: notifType,
          data: {'orderId': orderId},
        );
        if (notifySellerByPush) {
          await NotificationService.sendFcmPush(
            userId: sellerId,
            title: 'Order Update',
            body: sellerMsg,
            data: {'orderId': orderId, 'type': notifType.name},
          );
        }
      }

      // ── Driver notifications ──────────────────────────────────────────────
      if (driverId != null) {
        final driverMsg = _driverStatusMessage(newStatus);
        if (driverMsg != null) {
          await NotificationService.saveNotification(
            userId: driverId,
            title: 'Delivery Update',
            body: driverMsg,
            type: notifType,
            data: {'orderId': orderId},
          );
          if (newStatus == OrderStatus.delivered ||
              newStatus == OrderStatus.cancelled) {
            await NotificationService.sendFcmPush(
              userId: driverId,
              title: 'Delivery Update',
              body: driverMsg,
              data: {'orderId': orderId, 'type': notifType.name},
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[OrderRepo] Status notification failed: $e');
    }
  }

  static String _customerStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Your order has been confirmed and is being processed!';
      case OrderStatus.preparing:
        return 'Your order is being prepared by the seller.';
      case OrderStatus.assigned:
        return 'A driver has been assigned to deliver your order.';
      case OrderStatus.pickedUp:
        return 'Your order has been picked up by the driver.';
      case OrderStatus.onTheWay:
        return 'Your order is on the way!';
      case OrderStatus.delivered:
        return 'Your order has been delivered. Enjoy your fresh produce!';
      case OrderStatus.cancelled:
        return 'Your order has been cancelled.';
      default:
        return 'Your order status has been updated.';
    }
  }

  static String _sellerStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Order confirmed — please start preparing it.';
      case OrderStatus.preparing:
        return 'Order is being prepared.';
      case OrderStatus.assigned:
        return 'A driver has been assigned to pick up the order.';
      case OrderStatus.pickedUp:
        return 'Order has been picked up by the driver.';
      case OrderStatus.onTheWay:
        return 'Order is on the way to the customer.';
      case OrderStatus.delivered:
        return 'Order delivered successfully!';
      case OrderStatus.cancelled:
        return 'An order has been cancelled.';
      default:
        return 'Order status updated.';
    }
  }

  static String? _driverStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return 'Delivery confirmed. Great work!';
      case OrderStatus.cancelled:
        return 'The order has been cancelled.';
      default:
        return null; // No driver notification for other statuses
    }
  }

  // Keep legacy name for backward compatibility
  static String _statusMessage(OrderStatus status) =>
      _customerStatusMessage(status);

  static NotificationType _statusNotifType(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return NotificationType.orderConfirmed;
      case OrderStatus.delivered:
        return NotificationType.orderDelivered;
      case OrderStatus.cancelled:
        return NotificationType.orderCancelled;
      case OrderStatus.assigned:
        return NotificationType.driverAssigned;
      default:
        return NotificationType.systemAlert;
    }
  }

  Future<void> assignDriver({
    required String orderId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String customerId,
  }) async {
    // Update the order
    await FirebaseService.orders.doc(orderId).update({
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'status': OrderStatus.assigned.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline': FieldValue.arrayUnion([
        OrderTimeline(
          status: OrderStatus.assigned,
          timestamp: DateTime.now(),
          note: 'Driver assigned',
          actorId: driverId,
        ).toMap(),
      ]),
    });

    // Fetch order for seller IDs + customer email
    List<String> sellerIds = [];
    String? customerEmail;
    String customerName = '';
    try {
      final orderDoc = await FirebaseService.orders.doc(orderId).get();
      if (orderDoc.exists) {
        final d = orderDoc.data()!;
        sellerIds = (d['sellerIds'] as List?)?.cast<String>() ?? [];
        customerName = d['customerName'] as String? ?? '';
      }
      final userDoc = await FirebaseService.users.doc(customerId).get();
      customerEmail = userDoc.data()?['email'] as String?;
    } catch (_) {}

    // ── Customer: push + in-app + email ───────────────────────────────────
    await NotificationService.saveNotification(
      userId: customerId,
      title: 'Driver Assigned',
      body: '$driverName is your delivery driver.',
      type: NotificationType.driverAssigned,
      data: {'orderId': orderId},
    );
    await NotificationService.sendFcmPush(
      userId: customerId,
      title: 'Driver Assigned',
      body: '$driverName is on the way with your order!',
      data: {'orderId': orderId, 'type': 'driverAssigned'},
    );
    if (customerEmail != null) {
      try {
        await EmailService.sendDriverAssignedNotification(
          to: customerEmail,
          customerName: customerName,
          driverName: driverName,
          driverPhone: driverPhone,
          orderId: orderId,
        );
      } catch (e) {
        debugPrint('[Email] Driver assigned email failed: $e');
      }
    }

    // ── Driver: push + in-app ─────────────────────────────────────────────
    await NotificationService.saveNotification(
      userId: driverId,
      title: 'New Delivery Assigned',
      body: 'You have been assigned a new delivery order.',
      type: NotificationType.driverAssigned,
      data: {'orderId': orderId},
    );
    await NotificationService.sendFcmPush(
      userId: driverId,
      title: 'New Delivery',
      body: 'You have been assigned a new delivery. Tap to view details.',
      data: {'orderId': orderId, 'type': 'driverAssigned'},
    );

    // ── Sellers: in-app ───────────────────────────────────────────────────
    for (final sellerId in sellerIds) {
      await NotificationService.saveNotification(
        userId: sellerId,
        title: 'Driver Assigned',
        body: '$driverName has been assigned to deliver this order.',
        type: NotificationType.driverAssigned,
        data: {'orderId': orderId},
      );
    }
  }

  Future<void> updateDriverLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    await FirebaseService.orders.doc(orderId).update({
      'driverLat': lat,
      'driverLng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<OrderModel?> orderStream(String orderId) {
    return FirebaseService.orders.doc(orderId).snapshots().map((d) {
      if (!d.exists) return null;
      try {
        return OrderModel.fromFirestore(d);
      } catch (_) {
        return null;
      }
    });
  }

  Stream<List<OrderModel>> customerOrdersStream(String customerId) {
    return FirebaseService.orders
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => _safeParse(s));
  }

  Stream<List<OrderModel>> sellerOrdersStream(String sellerId) {
    return FirebaseService.orders
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => _safeParse(s));
  }

  Stream<List<OrderModel>> driverOrdersStream(String driverId) {
    return FirebaseService.orders
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => _safeParse(s));
  }

  Stream<List<OrderModel>> allOrdersStream() {
    return FirebaseService.orders
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => _safeParse(s));
  }

  Stream<List<OrderModel>> pendingOrdersForSellerStream(String sellerId) {
    return FirebaseService.orders
        .where('sellerIds', arrayContains: sellerId)
        .where('status', whereIn: [
          OrderStatus.pending.name,
          OrderStatus.confirmed.name,
          OrderStatus.preparing.name,
        ])
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => _safeParse(s));
  }

  /// Parses a query snapshot, silently skipping any document that fails to
  /// deserialise (bad data / schema mismatch) instead of crashing the stream.
  static List<OrderModel> _safeParse(QuerySnapshot<Map<String, dynamic>> snap) {
    final result = <OrderModel>[];
    for (final doc in snap.docs) {
      try {
        result.add(OrderModel.fromFirestore(doc));
      } catch (_) {
        // Skip malformed documents — do not let one bad doc kill the list
      }
    }
    return result;
  }

  Future<List<OrderModel>> getOrdersByDateRange({
    required DateTime from,
    required DateTime to,
    String? sellerId,
  }) async {
    Query<Map<String, dynamic>> query = FirebaseService.orders
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to));

    if (sellerId != null) {
      query = query.where('sellerIds', arrayContains: sellerId);
    }

    final snap = await query.get();
    return snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
  }
}
