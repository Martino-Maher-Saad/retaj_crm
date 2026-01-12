import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/layout_cubit.dart';
import '../cubit/layout_state.dart';


class TopHeader extends StatelessWidget {

  final ProfileModel user;

  TopHeader({super.key, required this.user});

  final List<String> titles = [
    "Dashboard",
    "Properties",
    "Leads",
    "Designs",
    "Accounts",
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<LayoutCubit, LayoutState>(
          builder: (context, state) {
            String title = "Dashboard";
            if (state is LayoutNavigationChanged) title = titles[state.selectedIndex];
            return Expanded(
              child: Container(
                height: 80,
                color: Colors.white,
                padding: EdgeInsets.only(left: 20, top: 20),
                child: Text(
                  title,
                  style: AppTextStyles.blue32Bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
