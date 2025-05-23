// Stripe integration service
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  // Call Firebase Function to create PaymentIntent and return clientSecret
  static Future<String> createPaymentIntent(int amountInCents) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'createPaymentIntent',
    );
    final resp = await callable.call({'amount': amountInCents});
    return resp.data['clientSecret'];
  }

  // Confirm payment using CardField data
  static Future<void> confirmStripePayment({
    required String clientSecret,
    required String name,
    required String email,
  }) async {
    final paymentMethodParams = PaymentMethodParams.card(
      paymentMethodData: PaymentMethodData(
        billingDetails: BillingDetails(name: name, email: email),
      ),
    );
    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: paymentMethodParams,
    );
  }
}
