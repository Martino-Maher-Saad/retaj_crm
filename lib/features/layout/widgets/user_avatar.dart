import 'package:flutter/material.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class UserAvatar extends StatelessWidget {

  final ProfileModel user;
  const UserAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryBlue,

            child: Text(
              user.firstName?[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
              ),
            ),
          ),

          SizedBox(width: 8,),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "${user.firstName} ${user.lastName ?? ''}",
                style: AppTextStyles.blue20Medium.copyWith(color: AppColors.white),
              ),

              Container(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),

                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(
                  user.role ?? '',
                  style: AppTextStyles.blue18Medium.copyWith(color: AppColors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
