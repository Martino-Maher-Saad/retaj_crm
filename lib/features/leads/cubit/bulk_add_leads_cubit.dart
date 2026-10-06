import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart';
import 'package:archive/archive.dart';
import 'package:universal_html/html.dart' as html;

import 'bulk_add_leads_state.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/services/lead_service.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/utils/csv_parser.dart';
import '../../../core/di/injection_container.dart';

class BulkAddLeadsCubit extends Cubit<BulkAddLeadsState> {
  final LeadService _leadService = sl<LeadService>();
  final StaticDataManager _dataManager = sl<StaticDataManager>();

  String _role = '';
  String _userId = '';

  BulkAddLeadsCubit() : super(BulkAddLeadsInitial()) {
    emit(BulkAddLeadsLoaded(List.generate(30, (_) => _createEmptyRow())));
  }

  void init(String role, String userId) {
    _role = role;
    _userId = userId;
    
    if (_role != 'manager' && _role != 'admin' && _role != 'ceo') {
      if (state is BulkAddLeadsLoaded) {
        final st = state as BulkAddLeadsLoaded;
        final newOrder = List<String>.from(st.columnOrder)..remove('assignedTo');
        final newRows = st.rows.map((r) => r.copyWith(assignedTo: _userId)).toList();
        emit(st.copyWith(columnOrder: newOrder, rows: newRows));
      }
    }
  }

  int _idCounter = 0;
  String _generateId() => 'row_${_idCounter++}';

  EditableLeadRow _createEmptyRow([Map<String, dynamic>? pinned]) {
    return EditableLeadRow(
      id: _generateId(),
      cityId: pinned?['cityId'] as int?,
      propertyTypeId: pinned?['propertyTypeId'] as String?,
      listingTypeId: pinned?['listingTypeId'] as String?,
      platformId: pinned?['platformId'] as String?,
      channelId: pinned?['channelId'] as String?,
      statusId: pinned?['statusId'] as String?,
      assignedTo: (_role != 'manager' && _role != 'admin' && _role != 'ceo' && _role.isNotEmpty) 
          ? _userId 
          : pinned?['assignedTo'] as String?,
    );
  }

  void _emitLoaded(
    List<EditableLeadRow> rows, {
    Map<String, dynamic>? pinned,
    Set<String>? selectedRowIds,
    Map<String, int>? unmappedLocations,
    Map<String, int>? unmappedEmployees,
    Map<String, int>? unmappedPropertyTypes,
    Map<String, int>? unmappedListingTypes,
  }) {
    if (state is BulkAddLeadsLoaded) {
      final st = state as BulkAddLeadsLoaded;
      emit(st.copyWith(
        rows: rows,
        pinnedValues: pinned ?? st.pinnedValues,
        selectedRowIds: selectedRowIds ?? st.selectedRowIds,
        unmappedLocations: unmappedLocations ?? st.unmappedLocations,
        unmappedEmployees: unmappedEmployees ?? st.unmappedEmployees,
        unmappedPropertyTypes: unmappedPropertyTypes ?? st.unmappedPropertyTypes,
        unmappedListingTypes: unmappedListingTypes ?? st.unmappedListingTypes,
      ));
    } else {
      emit(BulkAddLeadsLoaded(
        rows,
        pinnedValues: pinned ?? const {},
        selectedRowIds: selectedRowIds ?? const {},
        unmappedLocations: unmappedLocations ?? const {},
        unmappedEmployees: unmappedEmployees ?? const {},
        unmappedPropertyTypes: unmappedPropertyTypes ?? const {},
        unmappedListingTypes: unmappedListingTypes ?? const {},
      ));
    }
  }

  // --- إدارة تحديد الصفوف والتعديل الجماعي ---

  void toggleSelectRow(String id) {
    if (state is! BulkAddLeadsLoaded) return;
    final st = state as BulkAddLeadsLoaded;
    final currentSelected = Set<String>.from(st.selectedRowIds);
    if (currentSelected.contains(id)) {
      currentSelected.remove(id);
    } else {
      currentSelected.add(id);
    }
    emit(st.copyWith(selectedRowIds: currentSelected));
  }

  void selectAllRows(bool select) {
    if (state is! BulkAddLeadsLoaded) return;
    final st = state as BulkAddLeadsLoaded;
    final newSelected = select ? st.rows.map((r) => r.id).toSet() : <String>{};
    emit(st.copyWith(selectedRowIds: newSelected));
  }

  void clearSelection() {
    if (state is! BulkAddLeadsLoaded) return;
    final st = state as BulkAddLeadsLoaded;
    emit(st.copyWith(selectedRowIds: const {}));
  }

  void deleteSelectedRows() {
    if (state is! BulkAddLeadsLoaded) return;
    final st = state as BulkAddLeadsLoaded;
    if (st.selectedRowIds.isEmpty) return;

    final remaining = st.rows.where((r) => !st.selectedRowIds.contains(r.id)).toList();
    if (remaining.isEmpty) {
      remaining.add(_createEmptyRow(st.pinnedValues));
    }
    _emitLoaded(remaining, selectedRowIds: const {});
  }

  void bulkUpdateSelected({
    int? cityId,
    String? assignedTo,
    String? propertyTypeId,
    String? listingTypeId,
    String? platformId,
    String? statusId,
  }) {
    if (state is! BulkAddLeadsLoaded) return;
    final st = state as BulkAddLeadsLoaded;
    if (st.selectedRowIds.isEmpty) return;

    final updated = st.rows.map((row) {
      if (st.selectedRowIds.contains(row.id)) {
        return row.copyWith(
          cityId: cityId != null ? (cityId == -1 ? null : cityId) : row.cityId,
          assignedTo: assignedTo != null ? (assignedTo.isEmpty ? null : assignedTo) : row.assignedTo,
          propertyTypeId: propertyTypeId != null ? (propertyTypeId.isEmpty ? null : propertyTypeId) : row.propertyTypeId,
          listingTypeId: listingTypeId != null ? (listingTypeId.isEmpty ? null : listingTypeId) : row.listingTypeId,
          platformId: platformId != null ? (platformId.isEmpty ? null : platformId) : row.platformId,
          statusId: statusId != null ? (statusId.isEmpty ? null : statusId) : row.statusId,
        );
      }
      return row;
    }).toList();

    _emitLoaded(updated, selectedRowIds: const {});
  }

  // --- ترتيب الأعمدة والتثبيت ---

  void reorderColumns(int oldIndex, int newIndex) {
    if (state is BulkAddLeadsLoaded) {
      final currentState = state as BulkAddLeadsLoaded;
      final newOrder = List<String>.from(currentState.columnOrder);
      if (oldIndex < newIndex) newIndex -= 1;
      final item = newOrder.removeAt(oldIndex);
      newOrder.insert(newIndex, item);
      emit(currentState.copyWith(columnOrder: newOrder));
    }
  }

  void addEmptyRows() {
    if (state is BulkAddLeadsLoaded) {
      final currentState = state as BulkAddLeadsLoaded;
      final newRows = List.generate(20, (_) => _createEmptyRow(currentState.pinnedValues));
      _emitLoaded([...currentState.rows, ...newRows], pinned: currentState.pinnedValues);
    }
  }

  void pinColumnValue(String columnKey, dynamic value) {
    if (state is BulkAddLeadsLoaded) {
      final currentState = state as BulkAddLeadsLoaded;
      final newPinned = Map<String, dynamic>.from(currentState.pinnedValues);
      
      if (value == null || (value is String && value.isEmpty)) {
        newPinned.remove(columnKey);
      } else {
        newPinned[columnKey] = value;
      }

      final updatedRows = currentState.rows.map((row) {
        switch (columnKey) {
          case 'cityId': return row.copyWith(cityId: value as int?);
          case 'propertyTypeId': return row.copyWith(propertyTypeId: value as String?);
          case 'listingTypeId': return row.copyWith(listingTypeId: value as String?);
          case 'platformId': return row.copyWith(platformId: value as String?);
          case 'channelId': return row.copyWith(channelId: value as String?);
          case 'statusId': return row.copyWith(statusId: value as String?);
          case 'assignedTo': return row.copyWith(assignedTo: value as String?);
        }
        return row;
      }).toList();

      emit(currentState.copyWith(rows: updatedRows, pinnedValues: newPinned));
    }
  }

  void removeRow(String id) {
    if (state is BulkAddLeadsLoaded) {
      final currentRows = (state as BulkAddLeadsLoaded).rows;
      if (currentRows.length > 1) {
        _emitLoaded(currentRows.where((r) => r.id != id).toList());
      }
    }
  }

  void updateRow(EditableLeadRow newRow) {
    if (state is BulkAddLeadsLoaded) {
      final currentRows = (state as BulkAddLeadsLoaded).rows;
      final index = currentRows.indexWhere((r) => r.id == newRow.id);
      if (index != -1) {
        final updatedRows = List<EditableLeadRow>.from(currentRows);
        updatedRows[index] = newRow;
        _emitLoaded(updatedRows);
      }
    }
  }

  // --- شاشة المطابقة للقيم الفريدة (Distinct Values Mapping) ---

  void applyDistinctMapping(Map<String, int> mapping) {
    if (state is! BulkAddLeadsLoaded) return;
    final currentState = state as BulkAddLeadsLoaded;

    final updatedRows = currentState.rows.map((row) {
      if (row.cityId == null) {
        final rawLocation = row.areaName ?? row.unmappedCity;
        if (rawLocation != null && mapping.containsKey(rawLocation)) {
          return row.copyWith(
            cityId: mapping[rawLocation],
            unmappedCity: null,
          );
        }
      }
      return row;
    }).toList();

    final remainingUnmapped = _collectUnmappedLocations(updatedRows);
    _emitLoaded(updatedRows, unmappedLocations: remainingUnmapped);
  }

  void applyDistinctEmployeeMapping(Map<String, String> mapping) {
    if (state is! BulkAddLeadsLoaded) return;
    final currentState = state as BulkAddLeadsLoaded;

    final updatedRows = currentState.rows.map((row) {
      if (row.assignedTo == null) {
        final rawKey = row.unmappedAssignedTo;
        if (rawKey != null && mapping.containsKey(rawKey)) {
          return row.copyWith(
            assignedTo: mapping[rawKey],
            unmappedAssignedTo: null,
          );
        }
      }
      return row;
    }).toList();

    final remainingEmployees = _collectUnmappedEmployees(updatedRows);
    _emitLoaded(updatedRows, unmappedEmployees: remainingEmployees);
  }

  void applyDistinctPropertyTypeMapping(Map<String, String> mapping) {
    if (state is! BulkAddLeadsLoaded) return;
    final currentState = state as BulkAddLeadsLoaded;

    final updatedRows = currentState.rows.map((row) {
      if (row.propertyTypeId == null) {
        final rawKey = row.unmappedPropertyType;
        if (rawKey != null && mapping.containsKey(rawKey)) {
          return row.copyWith(
            propertyTypeId: mapping[rawKey],
            unmappedPropertyType: null,
          );
        }
      }
      return row;
    }).toList();

    final remaining = _collectUnmappedPropertyTypes(updatedRows);
    _emitLoaded(updatedRows, unmappedPropertyTypes: remaining);
  }

  void applyDistinctListingTypeMapping(Map<String, String> mapping) {
    if (state is! BulkAddLeadsLoaded) return;
    final currentState = state as BulkAddLeadsLoaded;

    final updatedRows = currentState.rows.map((row) {
      if (row.listingTypeId == null) {
        final rawKey = row.unmappedListingType;
        if (rawKey != null && mapping.containsKey(rawKey)) {
          return row.copyWith(
            listingTypeId: mapping[rawKey],
            unmappedListingType: null,
          );
        }
      }
      return row;
    }).toList();

    final remaining = _collectUnmappedListingTypes(updatedRows);
    _emitLoaded(updatedRows, unmappedListingTypes: remaining);
  }

  Map<String, int> _collectUnmappedLocations(List<EditableLeadRow> rows) {
    final Map<String, int> counts = {};
    for (var r in rows) {
      if (r.cityId == null) {
        final key = (r.areaName?.isNotEmpty == true) ? r.areaName! : r.unmappedCity;
        if (key != null && key.trim().isNotEmpty) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  Map<String, int> _collectUnmappedEmployees(List<EditableLeadRow> rows) {
    final Map<String, int> counts = {};
    for (var r in rows) {
      if (r.assignedTo == null) {
        final key = r.unmappedAssignedTo;
        if (key != null && key.trim().isNotEmpty) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  Map<String, int> _collectUnmappedPropertyTypes(List<EditableLeadRow> rows) {
    final Map<String, int> counts = {};
    for (var r in rows) {
      if (r.propertyTypeId == null) {
        final key = r.unmappedPropertyType;
        if (key != null && key.trim().isNotEmpty) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  Map<String, int> _collectUnmappedListingTypes(List<EditableLeadRow> rows) {
    final Map<String, int> counts = {};
    for (var r in rows) {
      if (r.listingTypeId == null) {
        final key = r.unmappedListingType;
        if (key != null && key.trim().isNotEmpty) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  // --- رفع ومعالجة الملفات (Excel & CSV) ---

  void uploadFile() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.xlsx,.csv';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final fileName = file.name.toLowerCase();
        final reader = html.FileReader();

        if (fileName.endsWith('.csv')) {
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) async {
            final bytes = reader.result as Uint8List;
            await _parseCsvBytes(bytes);
          });
        } else {
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) async {
            final bytes = reader.result as Uint8List;
            await _parseExcelBytes(bytes);
          });
        }
      }
    });
  }

  Future<void> _parseCsvBytes(Uint8List bytes) async {
    try {
      emit(BulkAddLeadsLoading('جاري قراءة ومعالجة ملف CSV والبحث في قاعدة البيانات...'));
      // معالجة الـ BOM والترميز العربي
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }

      final parsedGrid = CsvParser.parse(content);
      await processImportedGrid(parsedGrid);
    } catch (e) {
      emit(BulkAddLeadsError('خطأ أثناء قراءة ملف CSV: $e'));
      _emitLoaded([_createEmptyRow()]);
    }
  }

  Uint8List _sanitizeExcelBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      bool modified = false;
      final newArchive = Archive();

      for (final file in archive) {
        if (file.name == 'xl/_rels/workbook.xml.rels') {
          final content = utf8.decode(file.content as List<int>);
          if (content.contains('Target="/xl/') || content.contains("Target='/xl/")) {
            final patched = content.replaceAll('Target="/xl/', 'Target="').replaceAll("Target='/xl/", "Target='");
            final newBytes = utf8.encode(patched);
            newArchive.addFile(ArchiveFile(file.name, newBytes.length, newBytes));
            modified = true;
            continue;
          }
        } else if (file.name.startsWith('xl/worksheets/') && file.name.endsWith('.xml')) {
          final content = utf8.decode(file.content as List<int>);
          if (content.contains('t="inlineStr"') || content.contains("t='inlineStr'")) {
            final patched = content
                .replaceAllMapped(RegExp(r'<c\s+([^>]*?)t="inlineStr"\s*>\s*</c>'), (m) => '<c ${m.group(1)}></c>')
                .replaceAllMapped(RegExp(r'<c\s+([^>]*?)t="inlineStr"\s*/>'), (m) => '<c ${m.group(1)}/>')
                .replaceAllMapped(RegExp(r"<c\s+([^>]*?)t='inlineStr'\s*>\s*</c>"), (m) => '<c ${m.group(1)}></c>')
                .replaceAllMapped(RegExp(r"<c\s+([^>]*?)t='inlineStr'\s*/>"), (m) => '<c ${m.group(1)}/>');
            if (patched != content) {
              final newBytes = utf8.encode(patched);
              newArchive.addFile(ArchiveFile(file.name, newBytes.length, newBytes));
              modified = true;
              continue;
            }
          }
        }
        newArchive.addFile(file);
      }

      if (modified) {
        final encoder = ZipEncoder();
        return Uint8List.fromList(encoder.encode(newArchive)!);
      }
    } catch (_) {}
    return bytes;
  }

  Future<void> _parseExcelBytes(Uint8List bytes) async {
    try {
      emit(BulkAddLeadsLoading('جاري قراءة ومعالجة ملف Excel والبحث في قاعدة البيانات...'));
      final sanitizedBytes = _sanitizeExcelBytes(bytes);
      final excel = Excel.decodeBytes(sanitizedBytes);
      final sheet = excel.tables.values.first;
      final rawRows = sheet.rows;

      if (rawRows.length < 2) {
        emit(BulkAddLeadsError('الملف فارغ أو لا يحتوي على صفوف بيانات'));
        _emitLoaded([_createEmptyRow()]);
        return;
      }

      final List<List<String>> grid = [];
      for (final row in rawRows) {
        grid.add(row.map((cell) => cell?.value?.toString().trim() ?? '').toList());
      }

      await processImportedGrid(grid);
    } catch (e) {
      emit(BulkAddLeadsError('خطأ أثناء قراءة ملف الإكسيل: $e'));
      _emitLoaded([_createEmptyRow()]);
    }
  }

  Future<void> processImportedGrid(List<List<String>> grid) async {
    if (grid.length < 2) {
      emit(BulkAddLeadsError('الملف فارغ أو لا يحتوي على بيانات كافية'));
      _emitLoaded([_createEmptyRow()]);
      return;
    }

    final headerRow = grid[0].map((h) => h.toLowerCase()).toList();
    
    // هل الملف هو الملف الموحد بـ 10 أعمدة الناتج عن سكريبت البايثون؟
    final bool isUnifiedFile = headerRow.any((h) => h.contains('منصة') || h.contains('platform') || h.contains('المنطقة الأصلية') || h.contains('كود العقار')) 
        || (headerRow.length >= 9 && headerRow.length <= 11);

    List<EditableLeadRow> newRows = [];

    for (int i = 1; i < grid.length; i++) {
      final r = grid[i];
      if (r.isEmpty || r.every((c) => c.isEmpty)) continue;

      if (isUnifiedFile) {
        // قراءة الأعمدة إما بناء على مكان الهيدر الفعلي أو الفهارس المعتادة:
        final dateStr = _valByCol(r, headerRow, ['التاريخ', 'تاريخ', 'created_at']) ?? _cell(r, 0);
        final platformName = _valByCol(r, headerRow, ['اسم المنصة', 'منصة', 'platform']) ?? _cell(r, 1);
        final name = _valByCol(r, headerRow, ['اسم العميل', 'العميل', 'sender_name']) ?? _cell(r, 2);
        final rawPhone = _valByCol(r, headerRow, ['رقم العميل', 'الهاتف', 'phone']) ?? _cell(r, 3);
        final assignedToName = _valByCol(r, headerRow, ['اسم الموظف', 'الموظف', 'agent']) ?? _cell(r, 4);
        final prefix = _valByCol(r, headerRow, ['prefix', 'البريفكس', 'كود الموظف']) ?? (headerRow.any((h) => h == 'prefix') ? _cell(r, 5) : null);
        final pCode = (_valByCol(r, headerRow, ['كود العقار', 'كود_العقار', 'property_code', 'reference']) ?? (headerRow.any((h) => h == 'prefix') ? _cell(r, 6) : _cell(r, 5)))?.toUpperCase();
        final propTypeName = _valByCol(r, headerRow, ['نوع العقار', 'نوع_العقار', 'property_type', 'unit_type']) ?? (headerRow.any((h) => h == 'prefix') ? _cell(r, 7) : _cell(r, 6));
        final listTypeName = _valByCol(r, headerRow, ['نوع الاعلان', 'نوع_الاعلان', 'listing_type', 'القسم']) ?? (headerRow.any((h) => h == 'prefix') ? _cell(r, 8) : _cell(r, 7));
        final rawArea = _valByCol(r, headerRow, ['المنطقة الأصلية', 'المنطقة_الأصلية', 'area_name', 'المنطقة']) ?? (headerRow.any((h) => h == 'prefix') ? _cell(r, 9) : _cell(r, 8));
        final cityName = _valByCol(r, headerRow, ['المدينة', 'city']) ?? (headerRow.any((h) => h == 'prefix') ? _cell(r, 10) : _cell(r, 9));

        final phone = _cleanPhoneNumber(rawPhone);
        final parsedDate = _parseDate(dateStr);

        // إسناد الموظف حصراً بالاسم الكامل الثنائي (أول + أخير):
        String? userId;
        if (assignedToName != null && assignedToName.trim().isNotEmpty) {
          userId = _findUserId(assignedToName);
        }

        // مطابقة بقية الحقول (فقط إن كانت تحتوي على نص غير فارغ)
        final platId = _findPlatformId(platformName);
        final propId = (propTypeName != null && propTypeName.trim().isNotEmpty) ? _findPropertyTypeId(propTypeName) : null;
        final listId = (listTypeName != null && listTypeName.trim().isNotEmpty) ? _findListingTypeId(listTypeName) : null;

        // مطابقة المدينة: البحث في اسم المدينة، ثم البحث في اسم المنطقة الأصلية
        int? cityId;
        if (cityName != null && cityName.trim().isNotEmpty) {
          cityId = _findCityId(cityName);
        }
        if (cityId == null && rawArea != null && rawArea.trim().isNotEmpty) {
          cityId = _findCityId(rawArea);
        }

        final assignedTo = (_role != 'manager' && _role != 'admin' && _role != 'ceo' && _role.isNotEmpty)
            ? _userId
            : userId;

        newRows.add(EditableLeadRow(
          id: '${_generateId()}_$i',
          name: name,
          phone: phone,
          createdAt: parsedDate,
          propertyCode: pCode,
          areaName: (rawArea != null && rawArea.trim().isNotEmpty) ? rawArea.trim() : null,
          platformId: platId,
          unmappedPlatform: (platId == null && platformName != null && platformName.trim().isNotEmpty) ? platformName.trim() : null,
          propertyTypeId: propId,
          unmappedPropertyType: (propId == null && propTypeName != null && propTypeName.trim().isNotEmpty) ? propTypeName.trim() : null,
          listingTypeId: listId,
          unmappedListingType: (listId == null && listTypeName != null && listTypeName.trim().isNotEmpty) ? listTypeName.trim() : null,
          cityId: cityId,
          unmappedCity: (cityId == null && ((rawArea != null && rawArea.trim().isNotEmpty) || (cityName != null && cityName.trim().isNotEmpty)))
              ? (cityName?.trim().isNotEmpty == true ? cityName!.trim() : rawArea!.trim())
              : null,
          assignedTo: assignedTo,
          unmappedAssignedTo: assignedTo == null
              ? (assignedToName?.isNotEmpty == true
                  ? assignedToName
                  : (prefix != null && prefix.trim().isNotEmpty ? 'كود: $prefix' : 'بدون موظف (غير محدد)'))
              : null,
          channelId: _findChannelId('مكالمة هاتفية') ?? _findChannelId('واتساب'),
          statusId: _findId('lead_status', 'لم يتم التواصل معه') ??
                    _findId('lead_status', 'لم يتم التواصل') ??
                    _findId('lead_status', 'جديد') ??
                    '460be748-7685-49ef-abcf-c4dd49511ab7',
        ));
      } else {
        // القالب الكلاسيكي بـ 15 عموداً
        final name = _cell(r, 0);
        final phone = _cleanPhoneNumber(_cell(r, 1));
        final cityName = _cell(r, 2);
        final propTypeName = _cell(r, 3);
        final listTypeName = _cell(r, 4);
        final platformName = _cell(r, 5);
        final channelName = _cell(r, 6);
        final statusName = _cell(r, 7);
        final assignedToName = _cell(r, 8);
        final desc = _cell(r, 9);
        final bFrom = _cell(r, 10);
        final bTo = _cell(r, 11);
        final notes = _cell(r, 12);
        final pCode = _cell(r, 13)?.toUpperCase();
        final dateStr = _cell(r, 14);

        final cityId = _findCityId(cityName);
        final propId = _findPropertyTypeId(propTypeName);
        final listId = _findListingTypeId(listTypeName);
        final platId = _findPlatformId(platformName);
        final chanId = _findChannelId(channelName);
        final statId = (statusName != null && statusName.isNotEmpty)
            ? _findId('lead_status', statusName)
            : (_findId('lead_status', 'لم يتم التواصل معه') ??
               _findId('lead_status', 'لم يتم التواصل') ??
               _findId('lead_status', 'جديد') ??
               '460be748-7685-49ef-abcf-c4dd49511ab7');

        String? userId;
        final prefix = _extractPrefix(pCode);
        if (assignedToName != null && assignedToName.trim().isNotEmpty) {
          userId = _findUserId(assignedToName);
        }
        if (userId == null && prefix != null) {
          userId = _findUserIdByPrefix(prefix);
        }

        newRows.add(EditableLeadRow(
          id: '${_generateId()}_$i',
          name: name,
          phone: phone,
          budgetFrom: bFrom,
          budgetTo: bTo,
          notes: notes,
          propertyCode: pCode,
          descLeadNeed: desc,
          createdAt: _parseDate(dateStr),
          cityId: cityId,
          unmappedCity: cityId == null && cityName != null ? cityName : null,
          propertyTypeId: propId,
          unmappedPropertyType: propId == null && propTypeName != null ? propTypeName : null,
          listingTypeId: listId,
          unmappedListingType: listId == null && listTypeName != null ? listTypeName : null,
          platformId: platId,
          unmappedPlatform: platId == null && platformName != null ? platformName : null,
          channelId: chanId,
          unmappedChannel: chanId == null && channelName != null ? channelName : null,
          statusId: statId,
          unmappedStatus: statId == null && statusName != null ? statusName : null,
          assignedTo: (_role != 'manager' && _role != 'admin' && _role != 'ceo' && _role.isNotEmpty) ? _userId : userId,
          unmappedAssignedTo: userId == null
              ? (assignedToName?.isNotEmpty == true
                  ? assignedToName
                  : (prefix != null && prefix.trim().isNotEmpty ? 'كود: $prefix' : 'بدون موظف (غير محدد)'))
              : null,
        ));
      }
    }

    if (newRows.isEmpty) {
      newRows.add(_createEmptyRow());
    }

    // 1. الاستعلام السريع من قاعدة البيانات (Supabase) لإثراء بيانات العقارات بالأكواد
    final codesToLookup = <String>{};
    for (final row in newRows) {
      final code = row.propertyCode?.trim().toUpperCase();
      if (code != null && code.isNotEmpty) {
        if (row.cityId == null || row.propertyTypeId == null || row.listingTypeId == null) {
          codesToLookup.add(code);
        }
      }
    }

    if (codesToLookup.isNotEmpty) {
      final dbCatalog = await _leadService.lookupPropertiesByCodes(codesToLookup.toList());
      if (dbCatalog.isNotEmpty) {
        newRows = newRows.map((row) {
          final code = row.propertyCode?.trim().toUpperCase();
          if (code != null && dbCatalog.containsKey(code)) {
            final info = dbCatalog[code]!;
            final enrichedCityId = row.cityId ?? info['cityId'] as int?;
            final enrichedPropTypeId = row.propertyTypeId ?? info['propertyTypeId'] as String?;
            final enrichedListTypeId = row.listingTypeId ?? info['listingTypeId'] as String?;
            final enrichedAreaName = (row.areaName == null || row.areaName!.isEmpty) ? (info['areaName'] as String?) : row.areaName;

            return row.copyWith(
              cityId: enrichedCityId,
              unmappedCity: enrichedCityId != null ? null : row.unmappedCity,
              propertyTypeId: enrichedPropTypeId,
              unmappedPropertyType: enrichedPropTypeId != null ? null : row.unmappedPropertyType,
              listingTypeId: enrichedListTypeId,
              unmappedListingType: enrichedListTypeId != null ? null : row.unmappedListingType,
              areaName: enrichedAreaName,
            );
          }
          return row;
        }).toList();
      }
    }

    // 2. إزالة التكرار داخل الشيت لنفس اليوم ونفس الموظف حتى لو من منصات مختلفة
    final seenKeys = <String>{};
    final deduplicatedRows = <EditableLeadRow>[];
    for (final row in newRows) {
      final phone = row.phone?.trim();
      if (phone != null && phone.isNotEmpty) {
        final dateKey = row.createdAt != null
            ? '${row.createdAt!.year}-${row.createdAt!.month.toString().padLeft(2, '0')}-${row.createdAt!.day.toString().padLeft(2, '0')}'
            : 'no_date';
        final empKey = row.assignedTo ?? row.unmappedAssignedTo ?? '__unassigned__';
        final key = '$phone|$dateKey|$empKey';
        if (seenKeys.contains(key)) {
          continue; // تخطي المكرر لنفس اليوم ونفس الموظف
        }
        seenKeys.add(key);
      }
      deduplicatedRows.add(row);
    }
    newRows = deduplicatedRows;

    final unmappedLocations = _collectUnmappedLocations(newRows);
    final unmappedEmployees = _collectUnmappedEmployees(newRows);
    final unmappedPropertyTypes = _collectUnmappedPropertyTypes(newRows);
    final unmappedListingTypes = _collectUnmappedListingTypes(newRows);
    _emitLoaded(
      newRows,
      unmappedLocations: unmappedLocations,
      unmappedEmployees: unmappedEmployees,
      unmappedPropertyTypes: unmappedPropertyTypes,
      unmappedListingTypes: unmappedListingTypes,
    );
  }

  // --- محركات المطابقة الذكية واستخراج الـ Prefix ---

  String? _cell(List<String> row, int index) {
    if (index >= row.length) return null;
    final v = row[index].trim();
    return v.isEmpty ? null : v;
  }

  String? _valByCol(List<String> row, List<String> headers, List<String> keywords) {
    // 1. التطابق التام أولاً لمنع التداخل بين الأعمدة المتشابهة (Exact Match)
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].trim().toLowerCase();
      if (keywords.any((kw) => h == kw.trim().toLowerCase())) {
        return _cell(row, i);
      }
    }
    // 2. فحص الاحتواء كبديل فقط في حال عدم وجود تطابق تام (Contains)
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].trim().toLowerCase();
      if (keywords.any((kw) => h.contains(kw.trim().toLowerCase()))) {
        return _cell(row, i);
      }
    }
    return null;
  }

  String? _cleanPhoneNumber(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    return cleaned.isEmpty ? null : cleaned;
  }

  DateTime? _parseDate(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final clean = text.trim();
    final d = DateTime.tryParse(clean);
    if (d != null) return d;
    final parts = clean.split(RegExp(r'[-/ ]'));
    if (parts.length >= 3) {
      int? p1 = int.tryParse(parts[0]);
      int? p2 = int.tryParse(parts[1]);
      int? p3 = int.tryParse(parts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        if (p1 > 1000) return DateTime(p1, p2, p3);
        if (p3 > 1000) return (p2 > 12 && p1 <= 12) ? DateTime(p3, p1, p2) : DateTime(p3, p2, p1);
      }
    }
    return null;
  }

  String? _extractPrefix(String? propertyCode) {
    if (propertyCode == null || propertyCode.trim().isEmpty) return null;
    final code = propertyCode.trim().toUpperCase();
    // يستخرج الحروف الإنجليزية الأولى سواء كان الفاصل شرطة أو نقطة أو مسافة أو بدون فواصل
    final match = RegExp(r'^([A-Z]+)[\s._\-]*\d*').firstMatch(code);
    if (match != null && match.group(1) != null) {
      final prefix = match.group(1)!;
      return prefix.isNotEmpty ? prefix : null;
    }
    return null;
  }

  String? _findUserIdByPrefix(String? prefix) {
    if (prefix == null || prefix.isEmpty) return null;
    final upperPrefix = prefix.toUpperCase().trim();
    for (var u in _dataManager.employees) {
      if (u.propertyPrefix != null && u.propertyPrefix!.toUpperCase().trim() == upperPrefix) {
        return u.id;
      }
    }
    return null;
  }

  String? _findUserId(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    // تنظيف الاسم وإزالة المسافات المتعددة وتحويله بالكامل إلى lowercase
    final cleanName = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    for (var u in _dataManager.employees) {
      final fullName = '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      // مطابقة تامة وصارمة للاسم الكامل (الاسم الأول + الاسم الأخير معاً)
      if (fullName == cleanName) {
        return u.id;
      }
    }
    return null;
  }

  String? _findPlatformId(String? name) {
    if (name == null || name.isEmpty) return null;
    final clean = name.trim().toLowerCase();
    for (var opt in _dataManager.getOptionModels('platform')) {
      final optName = opt.nameAr.trim().toLowerCase();
      if (optName == clean || optName.contains(clean) || clean.contains(optName)) {
        return opt.id;
      }
    }
    if (clean.contains('aqar') || clean.contains('عقار')) {
      return _dataManager.getOptionModels('platform').where((o) => o.nameAr.toLowerCase().contains('aqar') || o.nameAr.contains('عقار')).firstOrNull?.id;
    }
    if (clean.contains('bayut') || clean.contains('بايوت')) {
      return _dataManager.getOptionModels('platform').where((o) => o.nameAr.toLowerCase().contains('bayut') || o.nameAr.contains('بايوت')).firstOrNull?.id;
    }
    if (clean.contains('property') || clean.contains('فايندر')) {
      return _dataManager.getOptionModels('platform').where((o) => o.nameAr.toLowerCase().contains('property') || o.nameAr.contains('فايندر')).firstOrNull?.id;
    }
    if (clean.contains('dubiz') || clean.contains('دوبيزل')) {
      return _dataManager.getOptionModels('platform').where((o) => o.nameAr.toLowerCase().contains('dub') || o.nameAr.contains('دوبيزل')).firstOrNull?.id;
    }
    return _findId('platform', name);
  }

  String? _findPropertyTypeId(String? name) {
    if (name == null || name.isEmpty) return null;
    final clean = name.trim().toLowerCase();
    for (var opt in _dataManager.getOptionModels('property_type')) {
      final oName = opt.nameAr.trim().toLowerCase();
      if (oName == clean || clean.contains(oName) || oName.contains(clean)) {
        return opt.id;
      }
    }
    if (clean.contains('شقة') || clean.contains('apartment')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('شقة')).firstOrNull?.id;
    }
    if (clean.contains('فيلا') || clean.contains('villa')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('فيلا')).firstOrNull?.id;
    }
    if (clean.contains('دوبليكس') || clean.contains('duplex')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('دوبليكس')).firstOrNull?.id;
    }
    if (clean.contains('محل') || clean.contains('commercial') || clean.contains('retail')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('محل')).firstOrNull?.id;
    }
    if (clean.contains('مكتب') || clean.contains('office') || clean.contains('إداري')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('مكتب') || o.nameAr.contains('إداري')).firstOrNull?.id;
    }
    if (clean.contains('مبنى') || clean.contains('building')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('مبنى')).firstOrNull?.id;
    }
    if (clean.contains('استوديو') || clean.contains('studio')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('استوديو')).firstOrNull?.id;
    }
    if (clean.contains('بنتهاوس') || clean.contains('penthouse')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('بنتهاوس')).firstOrNull?.id;
    }
    if (clean.contains('روف') || clean.contains('roof')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('روف')).firstOrNull?.id;
    }
    if (clean.contains('مخزن') || clean.contains('warehouse')) {
      return _dataManager.getOptionModels('property_type').where((o) => o.nameAr.contains('مخزن')).firstOrNull?.id;
    }
    return _findId('property_type', name);
  }

  String? _findListingTypeId(String? name) {
    if (name == null || name.isEmpty) return null;
    final clean = name.trim().toLowerCase();
    if (clean.contains('بيع') || clean.contains('sale')) {
      return _dataManager.getOptionModels('listing_type').where((o) => o.nameAr.contains('بيع')).firstOrNull?.id;
    }
    if (clean.contains('إيجار') || clean.contains('ايجار') || clean.contains('rent')) {
      return _dataManager.getOptionModels('listing_type').where((o) => o.nameAr.contains('إيجار') || o.nameAr.contains('ايجار')).firstOrNull?.id;
    }
    return _findId('listing_type', name);
  }

  int? _findCityId(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final clean = name.trim().toLowerCase();
    for (var c in _dataManager.allCities) {
      final cName = c.name.trim().toLowerCase();
      if (cName == clean || clean.contains(cName) || cName.contains(clean)) {
        return c.id;
      }
    }
    if (clean.contains('تجمع') || clean.contains('settlement') || clean.contains('new cairo') || clean.contains('القاهرة الجديدة')) {
      return _dataManager.allCities.where((c) => c.name.contains('التجمع') || c.name.contains('القاهرة الجديدة')).firstOrNull?.id;
    }
    if (clean.contains('مدينة نصر') || clean.contains('nasr city')) {
      return _dataManager.allCities.where((c) => c.name.contains('مدينة نصر')).firstOrNull?.id;
    }
    if (clean.contains('زايد') || clean.contains('zayed')) {
      return _dataManager.allCities.where((c) => c.name.contains('الشيخ زايد')).firstOrNull?.id;
    }
    if (clean.contains('مصر الجديدة') || clean.contains('heliopolis')) {
      return _dataManager.allCities.where((c) => c.name.contains('مصر الجديدة')).firstOrNull?.id;
    }
    if (clean.contains('شروق') || clean.contains('shorouk')) {
      return _dataManager.allCities.where((c) => c.name.contains('الشروق')).firstOrNull?.id;
    }
    return null;
  }

  String? _findChannelId(String? name) {
    if (name == null || name.isEmpty) return null;
    final clean = name.trim().toLowerCase();
    for (var opt in _dataManager.getOptionModels('communication_channel')) {
      if (opt.nameAr.toLowerCase().contains(clean) || clean.contains(opt.nameAr.toLowerCase())) {
        return opt.id;
      }
    }
    return _findId('communication_channel', name);
  }

  String? _findId(String tableName, String? name) {
    if (name == null || name.isEmpty) return null;
    return _dataManager.getIdByName(tableName, name);
  }

  // --- الحفظ النهائي (Batch Insert) ---

  Future<void> saveAll(String creatorId) async {
    if (state is! BulkAddLeadsLoaded) return;
    
    final allRows = (state as BulkAddLeadsLoaded).rows;
    final nonEmptyRows = allRows.where((r) => !r.isEmpty).toList();

    if (nonEmptyRows.isEmpty) {
      emit(BulkAddLeadsError('جميع الصفوف فارغة، لا يوجد شيء للحفظ'));
      _emitLoaded(allRows); 
      return;
    }

    final validRows = nonEmptyRows.where((r) => r.isValid).toList();
    final invalidRows = nonEmptyRows.where((r) => !r.isValid).toList();

    if (validRows.isEmpty) {
      List<String> errorMessages = [];
      for (var r in invalidRows) {
        int index = allRows.indexOf(r) + 1;
        List<String> missing = [];
        if (r.name == null || r.name!.trim().isEmpty) missing.add('الاسم');
        if (r.phone == null || r.phone!.trim().isEmpty) {
          missing.add('رقم الهاتف');
        } else if (r.phone!.contains(',') || r.phone!.contains(' ')) {
          missing.add('رقم الهاتف (يجب ألا يحتوي على مسافات)');
        }
        final bool pf = r.isPropertyFinder;
        if (!pf && r.cityId == null) missing.add('المدينة');
        if (!pf && r.propertyTypeId == null) missing.add('نوع العقار');
        if (!pf && r.listingTypeId == null) missing.add('نوع الإعلان');
        if (r.platformId == null) missing.add('المنصة');
        if (r.assignedTo == null) missing.add('الموظف المسند إليه');
        
        errorMessages.add('الصف $index: ينقصه (${missing.join('، ')})');
      }
      
      emit(BulkAddLeadsError('يرجى تصحيح الأخطاء التالية قبل الحفظ:\n${errorMessages.take(10).join('\n')}${errorMessages.length > 10 ? '\n...وغيرها' : ''}'));
      _emitLoaded(allRows); 
      return;
    }

    List<LeadModel> leadsToInsert = [];
    for (var row in validRows) {
      String? statusId = row.statusId;
      statusId ??= _findId('lead_status', 'لم يتم التواصل معه') ??
                   _findId('lead_status', 'لم يتم التواصل') ??
                   _findId('lead_status', 'جديد') ??
                   '460be748-7685-49ef-abcf-c4dd49511ab7';

      num? bFrom;
      num? bTo;
      if (row.budgetFrom != null && row.budgetFrom!.isNotEmpty) {
        bFrom = num.tryParse(row.budgetFrom!);
      }
      if (row.budgetTo != null && row.budgetTo!.isNotEmpty) {
        bTo = num.tryParse(row.budgetTo!);
      }

      final lead = LeadModel(
        clientName: row.name ?? 'بدون اسم',
        phones: [LeadPhoneModel(phoneNumber: row.phone!.trim(), isPrimary: true)],
        createdBy: creatorId,
        assignedTo: row.assignedTo!,
        createdAt: row.createdAt ?? DateTime.now().toLocal(),
        cityId: row.cityId,
        propertyTypeId: row.propertyTypeId,
        listingTypeId: row.listingTypeId,
        platformId: row.platformId,
        channelId: row.channelId,
        statusId: statusId,
        propertyCode: row.propertyCode,
        areaName: row.areaName,
        descLeadNeed: row.descLeadNeed,
        budgetFrom: bFrom,
        budgetTo: bTo,
        notes: row.notes != null && row.notes!.isNotEmpty 
            ? [LeadNoteModel(noteText: row.notes!)] 
            : [],
      );
      leadsToInsert.add(lead);
    }

    try {
      emit(BulkAddLeadsProgress(0, leadsToInsert.length));
      
      // استخدام خدمة Batch Insert السريعة
      await _leadService.batchInsertUnifiedLeads(leadsToInsert, (processed, total) {
        emit(BulkAddLeadsProgress(processed, total));
      });

      final remainingRows = allRows.where((r) => !validRows.contains(r)).toList();
      if (remainingRows.isEmpty) {
        remainingRows.add(_createEmptyRow());
      }

      if (invalidRows.isNotEmpty) {
        emit(BulkAddLeadsError('تم حفظ ${validRows.length} عميل بنجاح. يرجى إكمال باقي الصفوف الناقصة.'));
      } else {
        emit(BulkAddLeadsSuccess());
      }
      
      _emitLoaded(remainingRows, selectedRowIds: const {});
    } catch (e) {
      emit(BulkAddLeadsError('حدث خطأ أثناء الحفظ: $e'));
      _emitLoaded(allRows);
    }
  }

  Future<void> saveLeadsList(List<LeadModel> leadsToInsert, [List<EditableLeadRow>? remainingRows]) async {
    if (leadsToInsert.isEmpty) {
      emit(BulkAddLeadsError('لا توجد بيانات صالحة للحفظ'));
      return;
    }

    try {
      emit(BulkAddLeadsProgress(0, leadsToInsert.length));
      
      await _leadService.batchInsertUnifiedLeads(leadsToInsert, (processed, total) {
        emit(BulkAddLeadsProgress(processed, total));
      });

      emit(BulkAddLeadsSuccess());
      final toEmit = (remainingRows != null && remainingRows.isNotEmpty)
          ? remainingRows
          : [_createEmptyRow()];
      final unmappedLocations = _collectUnmappedLocations(toEmit);
      final unmappedEmployees = _collectUnmappedEmployees(toEmit);
      final unmappedPropertyTypes = _collectUnmappedPropertyTypes(toEmit);
      final unmappedListingTypes = _collectUnmappedListingTypes(toEmit);
      _emitLoaded(
        toEmit,
        selectedRowIds: const {},
        unmappedLocations: unmappedLocations,
        unmappedEmployees: unmappedEmployees,
        unmappedPropertyTypes: unmappedPropertyTypes,
        unmappedListingTypes: unmappedListingTypes,
      );
    } catch (e) {
      emit(BulkAddLeadsError('حدث خطأ أثناء الحفظ: $e'));
      if (state is BulkAddLeadsLoaded) {
        _emitLoaded((state as BulkAddLeadsLoaded).rows);
      }
    }
  }

  // --- تحميل القالب الموحد ---

  void downloadTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel.tables[excel.getDefaultSheet()]!;
    
    sheet.appendRow([
      TextCellValue('التاريخ (YYYY-MM-DD HH:MM:SS)'),
      TextCellValue('اسم المنصة (aqar map, bayut, property finder)'),
      TextCellValue('اسم العميل'),
      TextCellValue('رقم العميل (إجباري)'),
      TextCellValue('اسم الموظف (أو يُستخرج آلياً من كود العقار)'),
      TextCellValue('كود العقار (مثال: HG-601)'),
      TextCellValue('نوع العقار (شقة، فيلا، محل...)'),
      TextCellValue('نوع الاعلان (بيع، إيجار)'),
      TextCellValue('المنطقة الأصلية (اسم الكمبوند أو الشارع)'),
      TextCellValue('المدينة (المدينة الرئيسية إن عُرفت)'),
    ]);

    final bytes = excel.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'unified_leads_template.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
