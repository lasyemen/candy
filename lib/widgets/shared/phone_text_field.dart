import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  const PhoneTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        textAlign: TextAlign.left,
        enableSuggestions: false,
        autocorrect: false,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          LengthLimitingTextInputFormatter(14),
        ],
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال رقم الهاتف';
              }
              final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
              // Accept formats: 5XXXXXXXX, 05XXXXXXXXX, 9665XXXXXXXXX, +9665XXXXXXXXX
              final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
              bool valid = false;
              if (cleaned.length == 9 && cleaned.startsWith('5')) valid = true;
              if (cleaned.length == 10 && cleaned.startsWith('05'))
                valid = true;
              if (cleaned.length == 12 && cleaned.startsWith('9665'))
                valid = true;
              if (digits.startsWith('+9665') && cleaned.length == 12)
                valid = true;
              if (!valid) return 'أدخل رقم سعودي صحيح';
              return null;
            },
        style: const TextStyle(fontFamily: 'Rubik', fontSize: 12),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.grey[500],
          ),
          prefixText: '+966 ',
          prefixStyle: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : Colors.grey[600],
          ),
          suffixIcon: Icon(
            Icons.phone_outlined,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
