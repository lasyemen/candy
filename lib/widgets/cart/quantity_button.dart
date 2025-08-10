import 'package:flutter/material.dart';

import '../../core/constants/design_system.dart';

class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const QuantityButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: DesignSystem.getBrandGradient('primary'),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.primary.withOpacity(0.28),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}


