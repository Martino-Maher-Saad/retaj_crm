import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/profile_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../leads/cubit/leads_cubit.dart';
import '../../leads/cubit/leads_state.dart';
import '../../leads/widgets/lead_card.dart';
import '../../leads/widgets/list/lead_delete_dialog.dart';
import '../../leads/widgets/list/lead_restore_dialog.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/static_data_manager.dart';

class LeadArchiveView extends StatefulWidget {
  final ProfileModel user;
  final String? filteredEmployeeId;
  const LeadArchiveView({super.key, required this.user, this.filteredEmployeeId});

  @override
  State<LeadArchiveView> createState() => _LeadArchiveViewState();
}

class _LeadArchiveViewState extends State<LeadArchiveView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: AppColors.brandPrimary,
            labelColor: AppColors.brandPrimary,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'مستبعد'),
              Tab(text: 'تم التعاقد'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BlocProvider(
                  create: (_) => di.sl<LeadCubit>(),
                  child: _ArchiveTabList(user: widget.user, tabIndex: 0, filteredEmployeeId: widget.filteredEmployeeId),
                ),
                BlocProvider(
                  create: (_) => di.sl<LeadCubit>(),
                  child: _ArchiveTabList(user: widget.user, tabIndex: 1, filteredEmployeeId: widget.filteredEmployeeId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveTabList extends StatefulWidget {
  final ProfileModel user;
  final int tabIndex;
  final String? filteredEmployeeId;

  const _ArchiveTabList({
    required this.user,
    required this.tabIndex,
    this.filteredEmployeeId,
  });

  @override
  State<_ArchiveTabList> createState() => _ArchiveTabListState();
}

class _ArchiveTabListState extends State<_ArchiveTabList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  void _fetchData({bool isRefresh = false}) {
    final statusId = widget.tabIndex == 0
        ? '34f6f48c-3179-4b83-b34e-edc3fdc2e3d4' // مستبعد
        : '6d5c7b17-9ef7-48ee-a9f6-0575cc390278'; // تم التعاقد

    context.read<LeadCubit>().getAllLeads(
          role: widget.user.role,
          userId: widget.user.id,
          isRefresh: isRefresh,
          isArchived: true,
          leadStatusId: statusId,
          filterByEmployeeId: widget.filteredEmployeeId,
        );
  }

  @override
  void didUpdateWidget(covariant _ArchiveTabList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filteredEmployeeId != oldWidget.filteredEmployeeId) {
      _fetchData(isRefresh: true);
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        if (state is LeadLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LeadError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (state is LeadLoaded) {
          var leads = state.allLeads;

          if (leads.isEmpty) {
            return Center(
              child: Text(
                "لا توجد عناصر هنا",
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
                  "عدد العملاء في الأرشيف: ${leads.length}",
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _fetchData(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    itemCount: leads.length,
                    itemBuilder: (context, index) {
                      final lead = leads[index];
                      VoidCallback? deleteAction;
                      if (widget.user.role == 'admin') {
                        deleteAction = () => LeadDeleteDialog.show(
                          context,
                          lead,
                          () => context.read<LeadCubit>().deleteLead(
                            lead.id!,
                            widget.user.role,
                          ),
                        );
                      }

                      return LeadCard(
                        lead: lead,
                        role: widget.user.role,
                        onEdit: () {},
                        onTap: () {},
                        onRestore: () {
                          final role = widget.user.role;
                          if (role == 'admin' || role == 'manager' || role == 'ceo') {
                            LeadRestoreDialog.show(context, lead, widget.user);
                          } else {
                            context.read<LeadCubit>().restoreLeadFromArchive(
                              lead.id!,
                              '460be748-7685-49ef-abcf-c4dd49511ab7',
                            );
                          }
                        },
                        onDelete: deleteAction,
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
