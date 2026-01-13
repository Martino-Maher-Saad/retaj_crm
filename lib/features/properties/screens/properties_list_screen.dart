import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/core/constants/app_colors.dart';
import 'package:retaj_crm/core/constants/app_text_styles.dart';
import 'package:retaj_crm/data/repositories/property_repository.dart';
import 'package:retaj_crm/data/services/property_service.dart';
import 'package:retaj_crm/features/properties/screens/property_details_screen.dart';
import 'package:retaj_crm/features/properties/screens/property_form_screen.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider(
      create: (context) => PropertiesCubit(PropertiesRepository(PropertiesService()),)..fetchPage(userId: widget.userId, role: widget.role, page: 0),

      child: BlocConsumer<PropertiesCubit, PropertiesState>(
        listener: (context, state) {
          if (state is PropertiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },


        builder: (context, state) {
          final propertiesCubit = context.read<PropertiesCubit>();

          bool isFirstPage = (state is PropertiesSuccess && state.currentPage == 0);

          return Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.white,

                appBar: AppBar(
                  title: const Text(
                    "Properties Inventory",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 10,
                  surfaceTintColor: Colors.white,
                  shadowColor: Colors.black87,
                ),

                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: const CustomSearchBar(),
                    ),

                    Expanded(
                      child: (state is PropertiesSuccess) ? _buildList(state, propertiesCubit)
                          : (state is PropertiesError) ? Center(child: Text("There is Something went wrong /nThe Error is ${state.message}",style: AppTextStyles.blue20Medium,))
                          : Center(child: Text("There is no properties", style: AppTextStyles.blue20Medium,)),
                    ),

                    if (state is PropertiesSuccess && state.totalCount > AppConstants.pageSize) BuildPaginationBar(state: state, cubit: propertiesCubit, userId: widget.userId, role: widget.role),
                  ],
                ),

                floatingActionButton: isFirstPage ?
                FloatingActionButton.extended(
                  onPressed: () => _openForm(context: context, cubit: propertiesCubit),
                  label: Text("Add New Property", style: AppTextStyles.white16Bold.copyWith(fontSize: 14),),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20,),
                  backgroundColor: AppColors.primaryBlue,
                ) : null,
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildList(PropertiesSuccess state, PropertiesCubit cubit) {
    if (state.properties.isEmpty) return const Center(child: Text("No Properties Found"));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: state.properties.length,
      itemBuilder: (context, index) {
        final property = state.properties[index];
        return PropertyCard(
          key: ValueKey(property.id),
          property: property,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property))
          ),
          onEdit: () => _openForm(context: context, cubit: cubit, property: property),
          onDelete: () => cubit.deleteProperty(property.id!),
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