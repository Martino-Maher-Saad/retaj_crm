/*
import 'package:flutter/material.dart';
import 'package:retaj_crm/core/constants/app_constants.dart';
import 'package:retaj_crm/features/properties/widgets/pagination_arrow_button.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';


class BuildPaginationBar extends StatelessWidget {
  final PropertiesSuccess state;
  final PropertiesCubit cubit;
  final String userId;
  final String role;

  const BuildPaginationBar({super.key, required this.state, required this.cubit, required this.userId, required this.role});

  @override
  Widget build(BuildContext context) {
    final int totalPages = (state.totalCount / AppConstants.pageSize).ceil();
    final int currentPage = state.currentPage;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          PaginationArrowButton(
            icon: Icons.arrow_back_ios_new,
            isEnabled: currentPage > 0,
            onTap: () {
              cubit.fetchPage(
                userId: userId,
                role: role,
                page: currentPage - 1,
                city: state.city,
                type: state.type,
              );
            },
          ),

          const SizedBox(width: 16),

          Text(
            "Page ${currentPage + 1} of $totalPages",
            style: AppTextStyles.blue16Bold,
          ),

          const SizedBox(width: 16),

          PaginationArrowButton(
            icon: Icons.arrow_forward_ios,
            isEnabled: currentPage < totalPages - 1,
            onTap: () {
              cubit.fetchPage(
                userId: userId,
                role: role,
                page: currentPage + 1,
                city: state.city,
                type: state.type,
              );
            },
          ),
        ],
      ),
    );
  }
}
*/
