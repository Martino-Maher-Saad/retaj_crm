import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../data/models/lead_model.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/lead_repository.dart';
import '../../../../data/repositories/property_repository.dart';
import '../../leads/cubit/leads_cubit.dart';
import '../../leads/screens/lead_details_screen.dart';
import '../../leads/widgets/lead_card.dart';
import '../../properties/cubit/properties_cubit.dart';
import '../../properties/screens/property_details_screen.dart';
import '../../properties/widgets/property_card.dart';

class PropertyDuplicatesView extends StatefulWidget {
  final ProfileModel user;
  const PropertyDuplicatesView({super.key, required this.user});

  @override
  State<PropertyDuplicatesView> createState() => _PropertyDuplicatesViewState();
}

class _PropertyDuplicatesViewState extends State<PropertyDuplicatesView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isLoading = true;
  List<List<PropertyModel>> _duplicates = [];

  @override
  void initState() {
    super.initState();
    _fetchDuplicates();
  }

  Future<void> _fetchDuplicates() async {
    try {
      final repo = di.sl<PropertyRepository>();
      // جلب عدد كبير للبحث عن التكرارات
      final allProps = await repo.filterProperties(
        0,
        500,
        assignedTo: widget.user.role == 'sales' ? widget.user.id : null,
      );

      final Map<String, List<PropertyModel>> grouped = {};
      for (var p in allProps) {
        final phone = p.ownerPhone?.trim() ?? '';
        final key = phone.length >= 6
            ? phone.substring(phone.length - 6)
            : phone;
        if (key.isNotEmpty) {
          grouped.putIfAbsent(key, () => []).add(p);
        }
      }

      if (mounted) {
        setState(() {
          _duplicates = grouped.values
              .where((list) => list.length > 1)
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_duplicates.isEmpty) {
      return Center(
        child: Text("لا توجد عقارات مكررة", style: TextStyle(fontSize: 16.sp)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      itemCount: _duplicates.length,
      itemBuilder: (context, i) {
        final dupGroup = _duplicates[i];
        return Card(
          margin: EdgeInsets.all(10.w),
          child: ExpansionTile(
            key: PageStorageKey<String>('prop_dup_$i'),
            title: Text(
              "تكرار برقم المالك: ${dupGroup.first.ownerPhone}",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("العدد: ${dupGroup.length}"),
            children: dupGroup
                .map(
                  (p) => PropertyCard(
                    property: p,
                    currentUserId: widget.user.id,
                    role: widget.user.role,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<PropertiesCubit>(),
                          child: PropertyDetailsScreen(
                            property: p,
                            currentUserId: widget.user.id,
                            role: widget.user.role,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class LeadDuplicatesView extends StatefulWidget {
  final ProfileModel user;
  const LeadDuplicatesView({super.key, required this.user});

  @override
  State<LeadDuplicatesView> createState() => _LeadDuplicatesViewState();
}

class _LeadDuplicatesViewState extends State<LeadDuplicatesView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isLoading = true;
  List<List<LeadModel>> _duplicates = [];

  @override
  void initState() {
    super.initState();
    _fetchDuplicates();
  }

  Future<void> _fetchDuplicates() async {
    try {
      final repo = di.sl<LeadRepository>();
      final allLeads = await repo.getAllLeads(
        from: 0,
        to: 500,
        role: widget.user.role,
        userId: widget.user.id,
      );

      final Map<String, List<LeadModel>> grouped = {};
      for (var l in allLeads) {
        for (var phone in l.phones) {
          final p = phone.phoneNumber.trim();
          final key = p.length >= 6 ? p.substring(p.length - 6) : p;
          if (key.isNotEmpty) {
            grouped.putIfAbsent(key, () => []).add(l);
          }
        }
      }

      if (mounted) {
        setState(() {
          _duplicates = grouped.values
              .where((list) => list.length > 1)
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_duplicates.isEmpty) {
      return Center(
        child: Text("لا يوجد عملاء مكررين", style: TextStyle(fontSize: 16.sp)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      itemCount: _duplicates.length,
      itemBuilder: (context, i) {
        final dupGroup = _duplicates[i];
        return Card(
          margin: EdgeInsets.all(10.w),
          child: ExpansionTile(
            key: PageStorageKey<String>('lead_dup_$i'),
            title: Text(
              "تكرار العميل: ${dupGroup.first.clientName}",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("العدد: ${dupGroup.length}"),
            children: dupGroup
                .map(
                  (l) => LeadCard(
                    lead: l,
                    role: widget.user.role,
                    onEdit: () {},
                    onDelete: () {},
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<LeadCubit>(),
                          child: LeadDetailsScreen(
                            leadId: l.id ?? '',
                            currentUser: widget.user,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
