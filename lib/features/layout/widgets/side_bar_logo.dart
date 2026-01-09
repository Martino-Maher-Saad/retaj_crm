import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';


class SideBarLogo extends StatelessWidget {
  const SideBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        width: 200,
        height: 70,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // حواف دائرية بسيطة
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,

          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 80,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 10),

            const Text(
              "CRM",
              style: TextStyle(
                color: AppColors.primaryBlueDark,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}