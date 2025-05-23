import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_button.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final DeliveryMethod deliveryMethod;
  final String address;
  final String phoneNumber;

  const PaymentScreen({
    super.key,
    required this.deliveryMethod,
    required this.address,
    required this.phoneNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Logger _logger = Logger();
  PaymentMethod _paymentMethod = PaymentMethod.card;
  bool _isProcessing = false;
  final OrderService _orderService = OrderService();

  Future<void> _placeOrder() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cartService = Provider.of<CartService>(context, listen: false);

      if (authService.userModel == null) {
        throw Exception('User not authenticated');
      }

      final order = await _orderService.createOrder(
        userId: authService.userModel!.id,
        items: cartService.items,
        totalAmount: cartService.totalAmount,
        paymentMethod: _paymentMethod,
        deliveryMethod: widget.deliveryMethod,
        deliveryAddress: widget.address,
      );

      if (!mounted) return;

      if (order != null) {
        // Clear cart after successful order
        cartService.clearCart();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(order: order),
          ),
          (route) => route.isFirst,
        );
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      if (!mounted) return;

      _logger.e('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Payment method
                  const Text(
                    'Payment method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(
                            26,
                          ), // 0.1 opacity = 26/255
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        RadioListTile<PaymentMethod>(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Text('Card'),
                            ],
                          ),
                          value: PaymentMethod.card,
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(),
                        RadioListTile<PaymentMethod>(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.pink,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Text('Bank'),
                            ],
                          ),
                          value: PaymentMethod.bank,
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(),
                        RadioListTile<PaymentMethod>(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.money,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Text('Cash on Delivery'),
                            ],
                          ),
                          value: PaymentMethod.cashOnDelivery,
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total and proceed button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51), // 0.2 opacity = 51/255
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs. ${cartService.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Proceed to payment',
                  isLoading: _isProcessing,
                  onPressed: _placeOrder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
