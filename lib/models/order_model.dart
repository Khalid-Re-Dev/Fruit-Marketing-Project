// import 'package:food_delivery_app/models/cart_item_model.dart';

import 'cart_item_model.dart';

enum OrderStatus { pending, processing, delivering, delivered, cancelled }

enum PaymentMethod { card, bank, cashOnDelivery }

enum DeliveryMethod { doorDelivery, pickup }

class OrderModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final DeliveryMethod deliveryMethod;
  final String deliveryAddress;
  final String? notes;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.deliveryAddress,
    this.notes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      orderDate:
          DateTime.parse(json['orderDate'] ?? DateTime.now().toIso8601String()),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == json['paymentMethod'],
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      deliveryMethod: DeliveryMethod.values.firstWhere(
        (e) => e.toString() == json['deliveryMethod'],
        orElse: () => DeliveryMethod.doorDelivery,
      ),
      deliveryAddress: json['deliveryAddress'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'status': status.toString(),
      'paymentMethod': paymentMethod.toString(),
      'deliveryMethod': deliveryMethod.toString(),
      'deliveryAddress': deliveryAddress,
      'notes': notes,
    };
  }
}
