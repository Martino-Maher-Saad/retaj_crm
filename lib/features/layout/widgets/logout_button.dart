import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/cubit/auth_cubit.dart';


class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: IconButton(
        icon: const Icon(Icons.logout_rounded, color: AppColors.primaryRed, size: 28),
        onPressed: () => context.read<AuthCubit>().logout(),
      ),
    );
  }
}
