import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/data/repositories/property_repository.dart';
import 'package:retaj_crm/data/services/property_service.dart';
import 'package:retaj_crm/features/properties/screens/property_details_screen.dart';
import 'package:retaj_crm/features/properties/screens/property_form_screen.dart';
import '../../../data/models/property_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/property_card.dart';

class PropertiesListScreen extends StatelessWidget {
  final String userId;
  final String role;

  const PropertiesListScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertiesCubit(PropertiesRepository(PropertiesService()))
        ..fetchProperties(
          userId: userId,
          role: role,
        ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: const Text(
                "Properties Inventory",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocBuilder<PropertiesCubit, PropertiesState>(
                    builder: (context, state) {
                      if (state is PropertiesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is PropertiesError) {
                        return Center(child: Text(state.message));
                      } else if (state is PropertiesSuccess) {
                        final list = state.properties;
                        if (list.isEmpty) {
                          return const Center(child: Text("لا توجد عقارات مطابقة للبحث"));
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: list.length,
                                itemBuilder: (context, index) => PropertyCard(
                                  property: list[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PropertyDetailsScreen(property: list[index]),
                                      ),
                                    );
                                  },
                                  onEdit: () async {
                                    // حفظ الـ Cubit قبل الانتقال
                                    final cubit = context.read<PropertiesCubit>();
                                    // انتظار العقار المعدل عند العودة
                                    final updatedProperty = await Navigator.push<PropertyModel>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider.value(
                                          value: cubit,
                                          child: PropertyFormScreen(
                                            property: list[index],
                                            userId: userId,
                                          ),
                                        ),
                                      ),
                                    );
                                    // إذا عاد ببيانات، حدث العنصر في القائمة فوراً
                                    if (updatedProperty != null) {
                                      cubit.addPropertyToList(updatedProperty);
                                    }
                                  },
                                  onDelete: () => _showDeleteDialog(context, list[index].id ?? ''),
                                ),
                              ),
                            ),
                            _buildPaginationBar(context, state.currentPage, state.hasMore, state.isPaginationLoading),
                          ],
                        );
                      }
                      return const Center(child: Text("ابدأ بالبحث عن العقارات"));
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final cubit = context.read<PropertiesCubit>();
                // انتظار العقار الجديد عند العودة
                final newProperty = await Navigator.push<PropertyModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: cubit,
                      child: PropertyFormScreen(userId: userId),
                    ),
                  ),
                );
                // إذا تمت الإضافة، أضفه للقائمة في الذاكرة
                if (newProperty != null) {
                  cubit.addPropertyToList(newProperty);
                }
              },
              label: const Text("Add New Property"),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF2563EB),
            ),
          );
        },
      ),
    );
  }

  // --- الميثودز المساعدة بقيت كما هي لضمان التصميم ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterButton(Icons.filter_list, "Filters"),
        ],
      ),
    );
  }

  Widget _buildFilterButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPaginationBar(BuildContext context, int currentPage, bool hasMore, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Page ${currentPage + 1}", style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              TextButton(
                onPressed: currentPage > 0 ? () => context.read<PropertiesCubit>().changePage(currentPage - 1, userId, role) : null,
                child: const Text("Prev"),
              ),
              TextButton(
                onPressed: hasMore ? () => context.read<PropertiesCubit>().changePage(currentPage + 1, userId, role) : null,
                child: const Text("Next"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text("Delete Property"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dContext), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.read<PropertiesCubit>().deleteProperty(id);
              Navigator.pop(dContext);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}