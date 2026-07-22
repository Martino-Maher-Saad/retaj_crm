import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/profile_model.dart';
import '../../properties/cubit/properties_cubit.dart';
import '../../properties/cubit/properties_state.dart';
import '../../properties/widgets/property_card.dart';
import '../../properties/widgets/list/property_delete_dialog.dart';
import '../../properties/screens/property_details_screen.dart';

class PropertyArchiveView extends StatefulWidget {
  final ProfileModel user;
  final String? filteredEmployeeId;
  const PropertyArchiveView({super.key, required this.user, this.filteredEmployeeId});

  @override
  State<PropertyArchiveView> createState() => _PropertyArchiveViewState();
}

class _PropertyArchiveViewState extends State<PropertyArchiveView> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  void _fetchData({bool isRefresh = false}) {
    context.read<PropertiesCubit>().applyAdvancedFilters(
          role: widget.user.role,
          currentUserId: widget.user.id,
          selectedEmployee: widget.filteredEmployeeId,
          isArchived: true,
        );
  }

  @override
  void didUpdateWidget(covariant PropertyArchiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filteredEmployeeId != oldWidget.filteredEmployeeId) {
      _fetchData(isRefresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.7) {
      context.read<PropertiesCubit>().loadMoreFilteredProperties();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        if (state is PropertiesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PropertiesError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (state is PropertiesSuccess) {
          final properties = state.filteredProperties;

          if (properties.isEmpty) {
            return Center(
              child: Text(
                "الأرشيف فارغ",
                style: TextStyle(fontSize: 18.sp, color: Colors.grey),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Text(
                  "عدد العقارات في الأرشيف: ${properties.length}",
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _fetchData(isRefresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return PropertyCard(
                        key: ValueKey(property.id),
                        property: property,
                        currentUserId: widget.user.id,
                        role: widget.user.role,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailsScreen(
                              property: property,
                              currentUserId: widget.user.id,
                              role: widget.user.role,
                            ),
                          ),
                        ),
                        onRestore: () => context
                            .read<PropertiesCubit>()
                            .archiveProperty(property.id, false),
                        onDelete:
                            (widget.user.role == 'admin' ||
                                widget.user.role == 'manager' ||
                                widget.user.role == 'ceo')
                            ? () => PropertyDeleteDialog.show(
                                context,
                                property,
                                () => context
                                    .read<PropertiesCubit>()
                                    .deleteFullProperty(property.id),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
