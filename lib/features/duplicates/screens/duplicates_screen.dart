import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../properties/cubit/properties_cubit.dart';
import '../../leads/cubit/leads_cubit.dart';
import 'duplicates_views.dart';

class DuplicatesScreen extends StatelessWidget {
  final ProfileModel user;
  const DuplicatesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'سجل التكرارات',
            style: TextStyle(
              color: const Color(0xFF1A1A2E),
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.brandPrimary,
            labelColor: AppColors.brandPrimary,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: 'تكرار العقارات', icon: Icon(Icons.home_work_outlined)),
              Tab(text: 'تكرار العملاء', icon: Icon(Icons.people_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (_) => di.sl<PropertiesCubit>(),
              child: PropertyDuplicatesView(user: user),
            ),
            BlocProvider(
              create: (_) => di.sl<LeadCubit>(),
              child: LeadDuplicatesView(user: user),
            ),
          ],
        ),
      ),
    );
  }
}
