import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/core/constants/app_colors.dart';
import 'package:retaj_crm/core/constants/app_text_styles.dart';
import 'package:retaj_crm/data/repositories/property_repository.dart';
import 'package:retaj_crm/data/services/property_service.dart';
import 'package:retaj_crm/features/properties/screens/property_details_screen.dart';
import 'package:retaj_crm/features/properties/screens/property_form_screen.dart';
import 'package:shimmer/shimmer.dart'; // تأكد من إضافة حزمة shimmer في pubspec.yaml
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_search_bar.dart';
import '../../../data/models/property_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/build_pagination_bar.dart';
import '../widgets/property_card.dart';

class PropertiesListScreen extends StatefulWidget {
  final String userId;
  final String role;

  const PropertiesListScreen({super.key, required this.userId, required this.role});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> with AutomaticKeepAliveClientMixin {
  late PropertiesCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // إنشاء الكيوبت مرة واحدة فقط عند تشغيل الشاشة لأول مرة
    _cubit = PropertiesCubit(PropertiesRepository(PropertiesService()))
      ..fetchPage(userId: widget.userId, role: widget.role, page: 0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<PropertiesCubit, PropertiesState>(
        listener: (context, state) {
          if (state is PropertiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          bool isFirstPage = (state is PropertiesSuccess && state.currentPage == 0);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text(
                "Properties Inventory",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              surfaceTintColor: Colors.white,
              shadowColor: Colors.black87,
            ),
            body: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: CustomSearchBar(),
                ),
                Expanded(
                  child: _buildBody(state),
                ),
                if (state is PropertiesSuccess && state.totalCount > AppConstants.pageSize)
                  BuildPaginationBar(
                    state: state,
                    cubit: _cubit,
                    userId: widget.userId,
                    role: widget.role,
                  ),
              ],
            ),
            floatingActionButton: isFirstPage
                ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _openForm(context: context, cubit: _cubit),
              label: Text("Add New Property", style: AppTextStyles.white16Bold.copyWith(fontSize: 14)),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              backgroundColor: AppColors.primaryBlue,
            )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBody(PropertiesState state) {
    if (state is PropertiesLoading) {
      return _buildShimmerList();
    } else if (state is PropertiesSuccess) {
      return _buildList(state, _cubit);
    } else if (state is PropertiesError) {
      return Center(
        child: Text(
          "Something went wrong\n${state.message}",
          textAlign: TextAlign.center,
          style: AppTextStyles.blue20Medium,
        ),
      );
    }
    return Center(child: Text("No properties found", style: AppTextStyles.blue20Medium));
  }

  Widget _buildList(PropertiesSuccess state, PropertiesCubit cubit) {
    final properties = state.currentProperties; // استخدام الـ Getter الجديد

    if (properties.isEmpty && state.currentPage > 0) {
      cubit.fetchPage(
        page: state.currentPage - 1,
        userId: widget.userId,
        role: widget.role,
      );
      return const Center(child: CircularProgressIndicator());
    }

    if (properties.isEmpty) return const Center(child: Text("No Properties Found"));

    return ListView.builder(
      // PageStorageKey يضمن بقاء الـ Scroll في مكانه عند التنقل بين الصفحات
      key: PageStorageKey('properties_page_${state.currentPage}'),
      padding: const EdgeInsets.all(10),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          key: ValueKey(property.id),
          property: property,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)),
          ),
          onEdit: () => _openForm(context: context, cubit: cubit, property: property),
          onDelete: () => cubit.deleteProperty(property.id!),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: 5, // عدد العناصر الوهمية أثناء التحميل
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm({required BuildContext context, required PropertiesCubit cubit, PropertyModel? property}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PropertyFormScreen(property: property, userId: widget.userId),
        ),
      ),
    );
  }
}