import 'package:flutter/material.dart';

import '../../core/constants/design_system.dart';

class LoadingCart extends StatelessWidget {
  const LoadingCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignSystem.surface,
                    DesignSystem.surface.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.primary.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'جاري تحميل السلة...',
              style: DesignSystem.headlineMedium.copyWith(
                color: DesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى الانتظار بينما نقوم بتحميل محتويات سلة التسوق',
              style: DesignSystem.bodyLarge.copyWith(
                color: DesignSystem.textSecondary,
                fontFamily: 'Rubik',
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


