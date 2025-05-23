import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderService {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create a new order
  Future<OrderModel?> createOrder({
    required String userId,
    required List<CartItem> items,
    required double totalAmount,
    required PaymentMethod paymentMethod,
    required DeliveryMethod deliveryMethod,
    required String deliveryAddress,
    String? notes,
  }) async {
    try {
      final orderId = _uuid.v4();
      final now = DateTime.now();

      final order = OrderModel(
        id: orderId,
        userId: userId,
        items: items,
        totalAmount: totalAmount,
        orderDate: now,
        status: OrderStatus.pending,
        paymentMethod: paymentMethod,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );

      await _firestore.collection('orders').doc(orderId).set(order.toJson());

      return order;
    } catch (e) {
      _logger.e('Error creating order: $e');
      return null;
    }
  }

  // Get user orders
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('orderDate', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching user orders: $e');
      return [];
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        return OrderModel.fromJson(doc.data()!);
      }

      return null;
    } catch (e) {
      _logger.e('Error fetching order: $e');
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'OrderStatus.cancelled',
      });

      return true;
    } catch (e) {
      _logger.e('Error cancelling order: $e');
      return false;
    }
  }
}
