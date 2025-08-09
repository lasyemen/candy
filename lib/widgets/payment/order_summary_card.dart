import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OrderSummaryCard extends StatelessWidget {
  final String deliveryLocationText;
  final String? notes;
  final String totalText;

  const OrderSummaryCard({
    super.key,
    required this.deliveryLocationText,
    required this.totalText,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الطلب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rubik',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow('مكان التوصيل:', deliveryLocationText),
          if (notes != null) _buildRow('ملاحظات:', notes!),
          const Divider(color: AppColors.surface, height: 24),
          _buildRow('المبلغ الإجمالي:', totalText, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
              fontFamily: 'Rubik',
            ),
          ),
        ],
      ),
    );
  }
}


