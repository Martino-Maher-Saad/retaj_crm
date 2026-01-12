import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';


class SideBarLogo extends StatelessWidget {
  const SideBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 50),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const Icon(Icons.home_outlined, color: Colors.white, size: 45,),

          const SizedBox(height: 10),

          const Text(
            "RETAJ CRM",
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}