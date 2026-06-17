# Retaj CRM - Full Project Documentation

## Directory Structure

`	ext
- core/
- data/
- features/
  - constants/
  - di/
  - error/
  - theme/
  - utils/
  - widgets/
  - models/
  - repositories/
  - services/
  - admin_users/
  - archive/
  - auth/
  - dashboard/
  - designs/
  - duplicates/
  - layout/
  - leads/
  - profile/
  - properties/
  - tasks/
    - cubit/
    - screens/
    - screens/
    - cubit/
    - screens/
    - widgets/
    - cubit/
    - screens/
    - widgets/
    - cubit/
    - screens/
    - widgets/
    - screens/
    - cubit/
    - screens/
    - widgets/
    - cubit/
    - screens/
    - widgets/
      - details/
      - form_sections/
      - list/
    - cubit/
    - screens/
    - cubit/
    - screens/
    - widgets/
      - details/
      - form_sections/
      - list/
    - cubit/
    - screens/
    - widgets/
``n
## Files & Classes Detailed Map

### File: $relativePath

`dart
class MyApp
class RootAuthWrapper
  - Method: main
``n
### File: $relativePath

`dart
class AppColors
``n
### File: $relativePath

`dart
class AppConstants
``n
### File: $relativePath

`dart
class AppStrings
``n
### File: $relativePath

`dart
class AppTextStyles
``n
### File: $relativePath

`dart
  - Method: init
``n
### File: $relativePath

`dart
class AppException
class NetworkException
class ServerException
class AuthCustomException
``n
### File: $relativePath

`dart
class AppTheme
``n
### File: $relativePath

`dart
class LeadSyncNotifier
  - Method: notifyUpdated
  - Method: notifyDeleted
``n
### File: $relativePath

`dart
class NumberFormatter
  - Method: formatEditUpdate
  - Method: toCurrency
``n
### File: $relativePath

`dart
class PropertyCacheManager
``n
### File: $relativePath

`dart
class PropertySyncNotifier
  - Method: notifyUpdated
  - Method: notifyDeleted
``n
### File: $relativePath

`dart
class ResponsiveDebouncerWrapper
State: _ResponsiveDebouncerWrapperState
  - Method: _handleConstraints
  - Method: _onResize
  - Method: LayoutBuilder
``n
### File: $relativePath

`dart
class RoleHelper
``n
### File: $relativePath

`dart
class StaticDataManager
class StaticDataManagerImpl
  - Method: _loadData
  - Method: getActiveGovernorates
  - Method: getActiveCitiesByGovId
  - Method: getActiveOptions
``n
### File: $relativePath

`dart
class StaticDataManager
class StaticDataManagerImpl
  - Method: _loadData
  - Method: getActiveGovernorates
  - Method: getActiveCitiesByGovId
  - Method: getActiveOptions
``n
### File: $relativePath

`dart
class WhatsappShareHelper
``n
### File: $relativePath

`dart
class CustomButton
class _CustomButtonState
State: _CustomButtonState
``n
### File: $relativePath

`dart
class CustomSearchBar
``n
### File: $relativePath

`dart
class FormToggleTile
``n
### File: $relativePath

`dart
class RetajPageHeader
``n
### File: $relativePath

`dart
class RetajTextArea
class _RetajTextAreaState
class RetajNumberStepper
class _RetajNumberStepperState
class RetajCopyableDisplay
class RetajFieldRow
class RetajSectionCard
class RetajTextField
class _RetajTextFieldState
class RetajDropdown
class _RetajDropdownState
class RetajDatePicker
State: _RetajTextAreaState
State: _RetajNumberStepperState
State: _RetajTextFieldState
  - Method: _detect
  - Method: _step
  - Method: _detectDirection
  - Method: _copy
  - Method: _spaced
  - Method: _onFocusChange
  - Method: _detectDirection
``n
### File: $relativePath

`dart
class PlatformStat
class StatusStat
class PerformancePoint
class EmployeeStat
class GovernorateStat
class AvgTimeStat
class PeriodComparison
class RecentLead
class EmployeeDashboardModel
class ManagerDashboardModel
``n
### File: $relativePath

`dart
class DesignImageModel
``n
### File: $relativePath

`dart
class DesignModel
``n
### File: $relativePath

`dart
class DropdownOptionModel
``n
### File: $relativePath

`dart
class LeadPhoneModel
class LeadNoteModel
class LeadModel
  - Method: copyWith
``n
### File: $relativePath

`dart
class Governorate
class City
``n
### File: $relativePath

`dart
class ProfileModel
  - Method: copyWith
``n
### File: $relativePath

`dart
class PropertyFilterModel
``n
### File: $relativePath

`dart
class PropertyImageModel
  - Method: copyWith
``n
### File: $relativePath

`dart
class PropertyPlatformEntry
class PropertyModel
  - Method: copyWith
``n
### File: $relativePath

`dart
class PropertyShareModel
``n
### File: $relativePath

`dart
class ListingType
class PropertyType
``n
### File: $relativePath

`dart
class AuthRepository
  - Method: login
  - Method: signOut
``n
### File: $relativePath

`dart
class DashboardRepository
``n
### File: $relativePath

`dart
class DesignRepository
  - Method: getDesigns
  - Method: createFullDesign
  - Method: deleteFullDesign
  - Method: updateFullDesign
  - Method: searchDesignsSemantic
``n
### File: $relativePath

`dart
class DropdownRepository
``n
### File: $relativePath

`dart
class LeadRepository
  - Method: getAllLeads
  - Method: getLeadsCount
  - Method: addNewLead
  - Method: updateLeadData
  - Method: updateLeadStatus
  - Method: updateLeadStatusAndEmployee
  - Method: togglePin
  - Method: archiveLead
  - Method: addNote
  - Method: deleteLeadById
  - Method: searchLeadsWithAi
  - Method: searchLeads
  - Method: checkDuplicateLeadPhones
  - Method: getAllEmployees
  - Method: _handlePostgrestError
``n
### File: $relativePath

`dart
class PropertyRepository
  - Method: createFullProperty
  - Method: getMyProperties
  - Method: fetchTaskProperties
  - Method: filterProperties
  - Method: searchProperties
  - Method: checkDuplicatePropertyPhone
  - Method: deleteFullProperty
  - Method: updateFullProperty
  - Method: updateProperty
  - Method: sharePropertyInternal
  - Method: fetchReceivedShares
  - Method: fetchSentShares
  - Method: deleteShare
  - Method: searchWithAi
  - Method: togglePin
  - Method: archiveProperty
  - Method: publishPropertyPlatforms
  - Method: insertPropertyPlatforms
  - Method: resetPlatformsPublished
  - Method: getPropertyById
``n
### File: $relativePath

`dart
class AdminUserService
  - Method: getAllUsers
  - Method: createUser
  - Method: updateUserAdmin
  - Method: deleteUser
``n
### File: $relativePath

`dart
class AiService
  - Method: generateEmbedding
``n
### File: $relativePath

`dart
class SupabaseAuthService
class AuthService
  - Method: login
  - Method: logout
  - Method: changePassword
  - Method: adminCreateUser
  - Method: adminUpdateEmail
  - Method: adminUpdatePassword
  - Method: signIn
``n
### File: $relativePath

`dart
class DashboardService
  - Method: getEmployeeDashboard
  - Method: getManagerDashboard
``n
### File: $relativePath

`dart
class DesignService
  - Method: getDesignsCount
``n
### File: $relativePath

`dart
class LookupOptionModel
class DropdownService
  - Method: _fetchFromTable
  - Method: fetchAllForAdmin
  - Method: addOption
  - Method: updateOption
  - Method: deactivateOption
  - Method: activateOption
``n
### File: $relativePath

`dart
class LeadService
  - Method: fetchAllLeads
  - Method: getLeadsCount
  - Method: addLead
  - Method: updateLead
  - Method: updateLeadStatus
  - Method: updateLeadStatusAndEmployee
  - Method: togglePin
  - Method: archiveLead
  - Method: addNote
  - Method: getLeadById
  - Method: deleteLead
  - Method: searchLeadsByAi
  - Method: searchLeads
  - Method: checkDuplicateLeadPhones
  - Method: fetchAllEmployees
``n
### File: $relativePath

`dart
class ProfileService
  - Method: updateProfile
  - Method: uploadProfileImageBytes
``n
### File: $relativePath

`dart
class PropertyService
  - Method: sharePropertyInternal
  - Method: deleteShare
  - Method: getMyCount
  - Method: getFilterCount
  - Method: insertPlatforms
  - Method: publishPlatforms
  - Method: resetPlatformsPublished
  - Method: deletePlatforms
  - Method: archiveProperty
``n
### File: $relativePath

`dart
class StorageService
  - Method: uploadImage
  - Method: deleteFolder
  - Method: deleteFile
``n
### File: $relativePath

`dart
class AdminUsersCubit
Cubit: AdminUsersCubit
  - Method: emit
  - Method: fetchAllUsers
  - Method: createNewUser
  - Method: updateUserAdmin
  - Method: deleteUser
``n
### File: $relativePath

`dart
class AdminUsersState
class AdminUsersInitial
class AdminUsersLoading
class AdminUsersLoaded
class AdminUsersError
class AdminActionSuccess
State: AdminUsersState
``n
### File: $relativePath

`dart
class AdminUsersScreen
class _AdminUsersScreenState
class _AddUserForm
class _AddUserFormState
class _EditUserDialog
class _EditUserDialogState
class _DeleteUserConfirmationDialog
class _DeleteUserConfirmationDialogState
State: _AdminUsersScreenState
State: _AddUserFormState
State: _EditUserDialogState
State: _DeleteUserConfirmationDialogState
  - Method: _showAddUserBottomSheet
  - Method: _showEditUserDialog
  - Method: ElevatedButton
  - Method: ElevatedButton
  - Method: ElevatedButton
``n
### File: $relativePath

`dart
class DropdownManagementScreen
class _CategoryConfig
class _DropdownManagementScreenState
State: _DropdownManagementScreenState
  - Method: _parseBool
  - Method: _loadAll
  - Method: _reloadCurrent
  - Method: _addItem
  - Method: _edit
  - Method: _toggle
  - Method: _buildSidebar
  - Method: _buildContent
  - Method: _buildStandardView
  - Method: _buildLocationsView
  - Method: _buildAddField
  - Method: _buildLocationAddField
  - Method: _typeChip
  - Method: _govCard
  - Method: _itemTile
  - Method: _actions
  - Method: _emptyState
``n
### File: $relativePath

`dart
class ArchiveScreen
class _ArchiveScreenState
State: _ArchiveScreenState
``n
### File: $relativePath

`dart
class LeadArchiveView
class _LeadArchiveViewState
class _ArchiveTabList
State: _LeadArchiveViewState
State: _ArchiveTabListState
  - Method: _fetchData
  - Method: didUpdateWidget
  - Method: LeadCard
``n
### File: $relativePath

`dart
class PropertyArchiveView
class _PropertyArchiveViewState
State: _PropertyArchiveViewState
  - Method: _fetchData
  - Method: didUpdateWidget
  - Method: _onScroll
``n
### File: $relativePath

`dart
class AuthCubit
Cubit: AuthCubit
  - Method: login
  - Method: checkAuthStatus
  - Method: logout
``n
### File: $relativePath

`dart
class AuthInitial
class AuthLoading
class AuthSuccess
class AuthFailure
class AuthLoggedOut
``n
### File: $relativePath

`dart
class AccountsManagementScreen
``n
### File: $relativePath

`dart
class LoginWebScreen
  - Method: Builder
  - Method: CustomButton
``n
### File: $relativePath

`dart
class DashboardCubit
Cubit: DashboardCubit
  - Method: emit
  - Method: loadEmployeeDashboard
  - Method: changeEmployeePeriod
  - Method: loadManagerDashboard
  - Method: changeManagerPeriod
  - Method: viewEmployee
  - Method: backToCompanyView
``n
### File: $relativePath

`dart
class DashboardState
class DashboardInitial
class DashboardLoading
class EmployeeDashboardLoaded
class ManagerDashboardLoaded
class DashboardError
State: DashboardState
``n
### File: $relativePath

`dart
class DashboardScreen
class _DashboardScreenState
class DashboardTimeFilter
class DashboardStatCard
class DashboardSection
class DashboardErrorWidget
State: _DashboardScreenState
``n
### File: $relativePath

`dart
class EmployeeDashboardView
  - Method: _buildScaffold
  - Method: _buildSection
  - Method: _buildStaleAlert
  - Method: _buildLineChart
  - Method: _legend
  - Method: _buildFunnel
  - Method: Column
  - Method: _buildPlatforms
  - Method: Column
  - Method: _buildAvgTime
  - Method: Column
``n
### File: $relativePath

`dart
class ManagerDashboardView
  - Method: Scaffold
  - Method: _buildContent
  - Method: _buildCompanyView
  - Method: _buildSection
  - Method: _buildLineChart
  - Method: _buildFunnel
  - Method: Column
  - Method: _buildPlatformROI
  - Method: _buildAvgTime
  - Method: Column
  - Method: _buildLeaderboard
``n
### File: $relativePath

`dart
class DesignsCubit
Cubit: DesignsCubit
  - Method: emit
  - Method: fetchDesigns
  - Method: searchDesigns
  - Method: addDesign
  - Method: removeDesign
  - Method: updateDesign
``n
### File: $relativePath

`dart
class DesignsState
class DesignsInitial
class DesignsLoading
class DesignsLoaded
class DesignsError
class DesignsSearching
class DesignsSearchLoaded
State: DesignsState
  - Method: copyWith
``n
### File: $relativePath

`dart
class AddDesignScreen
class _AddDesignScreenState
State: _AddDesignScreenState
  - Method: _pickImages
  - Method: _submit
  - Method: _buildDropdown
``n
### File: $relativePath

`dart
class DesignsListScreen
State: _DesignsListScreenState
  - Method: _onScroll
  - Method: _onSearch
  - Method: _openAddScreen
  - Method: RefreshIndicator
  - Method: _showDeleteConfirm
``n
### File: $relativePath

`dart
class DesignDetailsScreen
``n
### File: $relativePath

`dart
class EditDesignScreen
class _EditDesignScreenState
State: _EditDesignScreenState
  - Method: _pickImages
  - Method: _submit
  - Method: _buildDropdown
``n
### File: $relativePath

`dart
class DesignCard
class _DesignCardState
State: _DesignCardState
  - Method: _actionButton
  - Method: _buildBadge
``n
### File: $relativePath

`dart
class DesignCard
class _DesignCardState
State: _DesignCardState
  - Method: _actionButton
  - Method: _buildBadge
``n
### File: $relativePath

`dart
class DesignCard
class _DesignCardState
State: _DesignCardState
  - Method: _actionButton
  - Method: _buildBadge
``n
### File: $relativePath

`dart
class DuplicatesScreen
``n
### File: $relativePath

`dart
class PropertyDuplicatesView
class _PropertyDuplicatesViewState
class LeadDuplicatesView
class _LeadDuplicatesViewState
State: _PropertyDuplicatesViewState
State: _LeadDuplicatesViewState
  - Method: _fetchDuplicates
  - Method: _fetchDuplicates
``n
### File: $relativePath

`dart
class LayoutCubit
Cubit: LayoutCubit
  - Method: changeNavigation
``n
### File: $relativePath

`dart
class LayoutState
class LayoutNavigationChanged
State: LayoutState
``n
### File: $relativePath

`dart
class LayoutScreen
class _NavItemData
class _LayoutScreenState
class _CustomNavItem
class _CustomNavItemState
State: _LayoutScreenState
State: _CustomNavItemState
  - Method: _getNavItems
  - Method: _resolveSidebarRole
  - Method: _getInitials
  - Method: _buildCustomSidebar
  - Method: _initialsWidget
``n
### File: $relativePath

`dart
class LogoutButton
``n
### File: $relativePath

`dart
class SideBarLogo
``n
### File: $relativePath

`dart
class TopHeader
  - Method: _resolveRoleLabel
``n
### File: $relativePath

`dart
class UserAvatar
``n
### File: $relativePath

`dart
class LeadCubit
Cubit: LeadCubit
  - Method: emit
  - Method: getAllLeads
  - Method: loadSingleLeadAndEmployees
  - Method: search
  - Method: clearSearch
  - Method: smartSearch
  - Method: checkDuplicates
  - Method: loadMoreLeads
  - Method: addLead
  - Method: updateLeadStatus
  - Method: updateLeadStatusAndEmployee
  - Method: restoreLeadFromArchive
  - Method: toggleLeadPin
  - Method: updateFullLead
  - Method: addNote
  - Method: deleteLead
  - Method: archiveLead
  - Method: _hasLeadDataChanged
  - Method: _havePhonesChanged
``n
### File: $relativePath

`dart
class LeadState
class LeadInitial
class LeadLoading
class LeadLoaded
class LeadError
class LeadActionSuccess
State: LeadState
  - Method: copyWith
``n
### File: $relativePath

`dart
class LeadsManagementScreen
State: _LeadsManagementScreenState
  - Method: _onScroll
  - Method: _openFilterDialog
  - Method: _openForm
  - Method: _openDetails
``n
### File: $relativePath

`dart
class LeadDetailsScreen
class _LeadDetailsScreenState
State: _LeadDetailsScreenState
  - Method: _submitNote
  - Method: _buildStatusCard
  - Method: _buildNotesSection
``n
### File: $relativePath

`dart
class LeadFormScreen
class _LeadFormScreenState
State: _LeadFormScreenState
  - Method: _initializeFields
  - Method: _buildSectionCard
  - Method: _buildDropdown
  - Method: _buildSubmitButton
  - Method: _submitForm
``n
### File: $relativePath

`dart
class SmartMatchScreen
class _SmartMatchScreenState
State: _SmartMatchScreenState
  - Method: _triggerSearch
  - Method: Column
  - Method: _buildSkeleton
``n
### File: $relativePath

`dart
class LeadCard
class _LeadCardState
State: _LeadCardState
  - Method: _checkDuplicates
  - Method: _showDuplicatesModal
  - Method: _copyPhone
  - Method: _statusColor
  - Method: _buildAvatar
  - Method: _buildBadge
  - Method: _buildActions
  - Method: _actionBtn
``n
### File: $relativePath

`dart
class LeadCopyableField
``n
### File: $relativePath

`dart
class LeadHeaderCard
  - Method: _resolveStatusColor
``n
### File: $relativePath

`dart
class LeadPipelineIndicator
class _PipelineStep
  - Method: _buildExcludedState
``n
### File: $relativePath

`dart
class ClientAdminSection
``n
### File: $relativePath

`dart
class ClientBasicSection
  - Method: _buildPhoneFields
  - Method: _circularAction
``n
### File: $relativePath

`dart
class ClientRequirementsSection
``n
### File: $relativePath

`dart
class LeadsStatusFilterBar
  - Method: SizedBox
``n
### File: $relativePath

`dart
class LeadArchiveDialog
``n
### File: $relativePath

`dart
class LeadDeleteDialog
``n
### File: $relativePath

`dart
class LeadEmptyState
State: LeadEmptyState
``n
### File: $relativePath

`dart
class LeadFilterDialog
class _LeadFilterDialogState
State: _LeadFilterDialogState
  - Method: _pickDate
  - Method: _sectionLabel
  - Method: _buildDropdown
  - Method: _buildGovDropdown
  - Method: _buildCityDropdown
  - Method: _buildDateButton
``n
### File: $relativePath

`dart
class LeadRestoreDialog
class _LeadRestoreDialogState
State: _LeadRestoreDialogState
``n
### File: $relativePath

`dart
class LeadSearchBar
class _LeadSearchBarState
State: _LeadSearchBarState
  - Method: _buildSearchField
  - Method: TextField
``n
### File: $relativePath

`dart
class LeadTopActionsBar
``n
### File: $relativePath

`dart
class ProfileCubit
Cubit: ProfileCubit
  - Method: emit
  - Method: setProfile
  - Method: updateProfileData
  - Method: updateProfileImageBytes
  - Method: removeProfileImage
``n
### File: $relativePath

`dart
class ProfileState
class ProfileInitial
class ProfileLoading
class ProfileLoaded
class ProfileError
State: ProfileState
``n
### File: $relativePath

`dart
class UserProfileScreen
class _UserProfileScreenState
State: _UserProfileScreenState
  - Method: _pickAndUploadImage
  - Method: _saveProfile
``n
### File: $relativePath

`dart
class PropertiesCubit
Cubit: PropertiesCubit
  - Method: emit
  - Method: fetchMyProperties
  - Method: applyAdvancedFilters
  - Method: checkDuplicates
  - Method: patchProperty
  - Method: removeProperty
  - Method: loadMoreFilteredProperties
  - Method: search
  - Method: smartSearch
  - Method: clearSearch
  - Method: clearFilter
  - Method: addProperty
  - Method: deleteFullProperty
  - Method: togglePropertyPin
  - Method: updateProperty
  - Method: archiveProperty
  - Method: sharePropertyInternal
``n
### File: $relativePath

`dart
class PropertiesInitial
class PropertiesLoading
class PropertiesSuccess
class PropertiesError
State: PropertiesState
  - Method: copyWith
``n
### File: $relativePath

`dart
class PropertySharesState
class PropertySharesInitial
class PropertySharesLoading
class PropertySharesLoaded
class PropertySharesError
class PropertySharesCubit
Cubit: PropertySharesCubit
State: PropertySharesState
  - Method: _initRealtime
  - Method: fetchShares
  - Method: deleteShare
  - Method: close
``n
### File: $relativePath

`dart
class PropertiesListScreen
State: _PropertiesListScreenState
  - Method: _onPropertySync
  - Method: _onScroll
  - Method: _buildBody
  - Method: _openForm
  - Method: _openAdvancedFilter
``n
### File: $relativePath

`dart
class PropertyDetailsScreen
class _StatusPriceCard
class _PlatformChips
``n
### File: $relativePath

`dart
class PropertyFormScreen
class _PropertyFormScreenState
State: _PropertyFormScreenState
  - Method: _initData
  - Method: _buildDropdown
  - Method: _buildSubmitButton
  - Method: _submit
  - Method: _pick
``n
### File: $relativePath

`dart
class PropertyFullScreenImage
``n
### File: $relativePath

`dart
class PropertySharesScreen
class _PropertySharesScreenState
State: _PropertySharesScreenState
  - Method: _buildTabContent
  - Method: PropertyShareCard
``n
### File: $relativePath

`dart
class PropertyCard
class _PropertyCardState
State: _PropertyCardState
  - Method: _actionButton
  - Method: _buildStatusBadge
``n
### File: $relativePath

`dart
class PropertyFormCard
``n
### File: $relativePath

`dart
class PropertyShareCard
class _PropertyShareCardState
State: _PropertyShareCardState
``n
### File: $relativePath

`dart
class PropertyShareSheet
  - Method: _buildShareOption
  - Method: showPropertyShareSheet
``n
### File: $relativePath

`dart
class PropertyCopyableField
``n
### File: $relativePath

`dart
class PropertyImageHeader
``n
### File: $relativePath

`dart
class PropertyMainInfoCard
``n
### File: $relativePath

`dart
class PropertySectionCard
``n
### File: $relativePath

`dart
class PropertySpecItem
``n
### File: $relativePath

`dart
class AdminSection
``n
### File: $relativePath

`dart
class FinancialSection
``n
### File: $relativePath

`dart
class ImageSection
class _DashedBorderPainter
  - Method: _buildUploadArea
  - Method: paint
``n
### File: $relativePath

`dart
class StatusSection
``n
### File: $relativePath

`dart
class TechnicalSection
``n
### File: $relativePath

`dart
class AdvancedFilterDialog
class _AdvancedFilterDialogState
State: _AdvancedFilterDialogState
  - Method: _pickDateTime
  - Method: _buildDropdown
``n
### File: $relativePath

`dart
class InternalShareDialog
class _InternalShareDialogState
State: _InternalShareDialogState
  - Method: _fetchEmployees
  - Method: _submit
``n
### File: $relativePath

`dart
class PropertyArchiveDialog
``n
### File: $relativePath

`dart
class PropertyDeleteDialog
``n
### File: $relativePath

`dart
class PropertyListHeader
``n
### File: $relativePath

`dart
class PropertySearchBar
class _PropertySearchBarState
State: _PropertySearchBarState
  - Method: _buildSearchField
  - Method: TextField
``n
### File: $relativePath

`dart
class PropertyShimmerList
``n
### File: $relativePath

`dart
class LeadTasksCubit
Cubit: LeadTasksCubit
  - Method: emit
  - Method: fetchTasks
  - Method: loadMore
  - Method: removeLead
  - Method: patchLead
``n
### File: $relativePath

`dart
class LeadTasksState
class LeadTasksInitial
class LeadTasksLoading
class LeadTasksLoaded
class LeadTasksError
State: LeadTasksState
  - Method: copyWith
``n
### File: $relativePath

`dart
class PropertyTasksCubit
Cubit: PropertyTasksCubit
  - Method: emit
  - Method: invalidateTasks
  - Method: invalidateApprovals
  - Method: fetchPendingApprovals
  - Method: fetchTaskProperties
  - Method: approveProperty
  - Method: markAsPublished
  - Method: resubmitRejectedProperty
  - Method: deleteFullProperty
  - Method: _updateApprovalStatus
  - Method: _applyPropertyUpdate
``n
### File: $relativePath

`dart
class PropertyTasksInitial
class PropertyTasksLoading
class PropertyTasksSuccess
class PropertyTasksError
State: PropertyTasksState
  - Method: copyWith
``n
### File: $relativePath

`dart
class LeadsTasksView
State: _LeadsTasksViewState
  - Method: _onLeadSync
  - Method: didUpdateWidget
  - Method: _fetchData
  - Method: _onScroll
  - Method: _openDetails
  - Method: _openEdit
  - Method: _buildList
``n
### File: $relativePath

`dart
class ManagerApprovalsScreen
class _ManagerApprovalsScreenState
State: _ManagerApprovalsScreenState
  - Method: _fetchEmployees
  - Method: _fetchData
``n
### File: $relativePath

`dart
class PropertyTasksView
State: _PropertyTasksViewState
  - Method: didUpdateWidget
  - Method: _fetchData
``n
### File: $relativePath

`dart
class TasksScreen
class _TasksScreenState
State: _TasksScreenState
  - Method: _loadEmployees
``n
### File: $relativePath

`dart
class AdminPropertyTaskCard
class _AdminPropertyTaskCardState
State: _AdminPropertyTaskCardState
  - Method: _submitAction
  - Method: _infoCol
``n
### File: $relativePath

`dart
class EmployeePropertyTaskCard
class _EmployeePropertyTaskCardState
State: _EmployeePropertyTaskCardState
  - Method: _submitPublishAction
  - Method: _submitResubmitAction
  - Method: _submitDeleteAction
  - Method: _infoCol
``n
