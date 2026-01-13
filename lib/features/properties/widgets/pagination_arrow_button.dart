import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';


class PaginationArrowButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const PaginationArrowButton({super.key, required this.icon, required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),

      child: Container(
        padding: const EdgeInsets.all(8),

        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primaryBlue : AppColors.greyLight,
          borderRadius: BorderRadius.circular(8),
        ),

        child: Icon(
          icon,
          size: 18,
          weight: 2,
          color: isEnabled ? AppColors.greyLight : AppColors.primaryBlue,
        ),
      ),
    );
  }
}
