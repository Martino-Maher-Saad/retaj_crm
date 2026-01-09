import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/layout_cubit.dart';
import '../cubit/layout_state.dart';


class TopHeader extends StatelessWidget {
  final ProfileModel user;
  const TopHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          BlocBuilder<LayoutCubit, LayoutState>(
            builder: (context, state) {
              String title = "Dashboard";
              if (state is LayoutNavigationChanged) title = state.pageTitle;
              return Text(title, style: AppTextStyles.blue20Medium);
            },
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${user.firstName} ${user.lastName ?? ''}", style: AppTextStyles.blue18Medium),
              Text(user.role?.toUpperCase() ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(backgroundColor: AppColors.primaryBlue, child: Text(user.firstName?[0] ?? 'U', style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
