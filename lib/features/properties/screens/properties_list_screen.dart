import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/data/repositories/property_repository.dart';
import 'package:retaj_crm/data/services/property_service.dart';
import 'package:retaj_crm/features/properties/screens/property_details_screen.dart';
import 'package:retaj_crm/features/properties/screens/property_form_screen.dart';
import '../../../core/widgets/custom_search_bar.dart';
import '../../../data/models/property_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
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
      create: (context) => PropertiesCubit(
        PropertiesRepository(PropertiesService()),
      )..fetchPage(userId: widget.userId, role: widget.role, page: 0),
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
                backgroundColor: const Color(0xFFF8F9FA),
                appBar: AppBar(
                  title: const Text("Properties Inventory",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  elevation: 0,
                ),
                body: Column(
                  children: [
                    const CustomSearchBar(),
                    Expanded(
                      child: (state is PropertiesSuccess)
                          ? _buildList(state, propertiesCubit) // تمرير الـ state كاملة
                          : const SizedBox(),
                    ),
                    if (state is PropertiesSuccess && state.totalCount > 15)
                      _buildPaginationBar(context, state, propertiesCubit),
                  ],
                ),
                floatingActionButton: isFirstPage
                    ? FloatingActionButton.extended(
                  onPressed: () => _openForm(context, propertiesCubit),
                  label: const Text("Add New Property"),
                  icon: const Icon(Icons.add),
                  backgroundColor: const Color(0xFF2563EB),
                )
                    : null,
              ),
              if (state is PropertiesLoading && state is! PropertiesSuccess)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(PropertiesSuccess state, PropertiesCubit cubit) {
    if (state.properties.isEmpty) return const Center(child: Text("No Properties Found"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.properties.length,
      itemBuilder: (context, index) {
        final property = state.properties[index];
        return PropertyCard(
          key: ValueKey(property.id), // مهم جداً للـ Local Update
          property: property,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property))
          ),
          onEdit: () => _openForm(context, cubit, property: property),
          onDelete: () => cubit.deleteProperty(property.id!),
        );
      },
    );
  }

  Widget _buildPaginationBar(BuildContext context, PropertiesSuccess state, PropertiesCubit cubit) {
    final int totalPages = (state.totalCount / 15).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (index) {
            final bool isSelected = state.currentPage == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text("${index + 1}"),
                selected: isSelected,
                selectedColor: const Color(0xFF2563EB),
                onSelected: (selected) {
                  if (selected && !isSelected) {
                    cubit.fetchPage(userId: widget.userId, role: widget.role, page: index, city: state.city, type: state.type);
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  void _openForm(BuildContext context, PropertiesCubit cubit, {PropertyModel? property}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyFormScreen(property: property, userId: widget.userId),
      ),
    );

    if (result != null) {
      final model = result['model'] as PropertyModel;
      final images = result['images'] as List<Uint8List>;

      if (property == null) {
        await cubit.addProperty(model, images);
      } else {
        await cubit.updateProperty(model, images);
      }
    }
  }

}