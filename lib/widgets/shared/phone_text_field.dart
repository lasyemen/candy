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
        ],
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال رقم الهاتف';
              }
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
          prefixIcon: Icon(
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
