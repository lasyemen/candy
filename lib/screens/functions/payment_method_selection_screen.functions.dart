part of '../payment_method_selection_screen.dart';

class PaymentMethodItem {
  final String id;
  final String name;
  final String? subtitle;
  final IconData icon;
  const PaymentMethodItem(this.id, this.name, this.icon, {this.subtitle});
}

mixin PaymentMethodSelectionScreenFunctions
    on State<PaymentMethodSelectionScreen> {
  // Common KSA methods
  final List<PaymentMethodItem> methods = const [
    PaymentMethodItem(
      'mada',
      'Mada',
      Icons.payment,
      subtitle: 'Saudi debit network',
    ),
    PaymentMethodItem(
      'visa',
      'Visa',
      Icons.credit_card,
      subtitle: 'Credit/Debit card',
    ),
    PaymentMethodItem('mastercard', 'Mastercard', Icons.credit_card),
    PaymentMethodItem('apple_pay', 'Apple Pay', Icons.phone_iphone),
    PaymentMethodItem('cod', 'Cash on Delivery', Icons.money),
  ];
}

