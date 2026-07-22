import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;

import 'bulk_add_leads_state.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/services/lead_service.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart';

class BulkAddLeadsCubit extends Cubit<BulkAddLeadsState> {
  final LeadService _leadService = sl<LeadService>();
  final StaticDataManager _dataManager = sl<StaticDataManager>();

  BulkAddLeadsCubit() : super(BulkAddLeadsInitial()) {
    emit(BulkAddLeadsLoaded(List.generate(30, (_) => _createEmptyRow())));
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  EditableLeadRow _createEmptyRow() {
    return EditableLeadRow(id: _generateId());
  }

  void _emitLoaded(List<EditableLeadRow> rows) {
    if (state is BulkAddLeadsLoaded) {
      emit(BulkAddLeadsLoaded(rows, columnOrder: (state as BulkAddLeadsLoaded).columnOrder));
    } else {
      emit(BulkAddLeadsLoaded(rows));
    }
  }

  void reorderColumns(int oldIndex, int newIndex) {
    if (state is BulkAddLeadsLoaded) {
      final currentState = state as BulkAddLeadsLoaded;
      final newOrder = List<String>.from(currentState.columnOrder);
      if (oldIndex < newIndex) newIndex -= 1;
      final item = newOrder.removeAt(oldIndex);
      newOrder.insert(newIndex, item);
      emit(BulkAddLeadsLoaded(currentState.rows, columnOrder: newOrder));
    }
  }

  void addEmptyRows() {
    if (state is BulkAddLeadsLoaded) {
      final currentRows = (state as BulkAddLeadsLoaded).rows;
      final newRows = List.generate(30, (_) => _createEmptyRow());
      _emitLoaded([...currentRows, ...newRows]);
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

  Future<void> saveAll(String creatorId) async {
    if (state is! BulkAddLeadsLoaded) return;
    
    // Filter out completely empty rows
    final allRows = (state as BulkAddLeadsLoaded).rows;
    final rows = allRows.where((r) => !r.isEmpty).toList();

    if (rows.isEmpty) {
      emit(BulkAddLeadsError('جميع الصفوف فارغة، لا يوجد شيء للحفظ'));
      _emitLoaded(allRows); 
      return;
    }

    if (rows.any((r) => !r.isValid)) {
      emit(BulkAddLeadsError('يرجى تصحيح الأخطاء في الصفوف قبل الحفظ'));
      _emitLoaded(allRows); 
      return;
    }

    List<LeadModel> leadsToInsert = [];
    for (var row in rows) {
      String? statusId = row.statusId;
      if (statusId == null) {
        statusId = _dataManager.getIdByName('lead_status', 'جديد') ??
                   _dataManager.getIdByName('lead_status', 'New');
      }

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
      
      await _leadService.bulkInsertLeads(leadsToInsert, (processed, total) {
        emit(BulkAddLeadsProgress(processed, total));
      });

      emit(BulkAddLeadsSuccess());
    } catch (e) {
      emit(BulkAddLeadsError('حدث خطأ أثناء الحفظ: $e'));
      _emitLoaded(allRows);
    }
  }

  void uploadExcelFile() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.xlsx';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) async {
          final bytes = reader.result as Uint8List;
          _parseExcelBytes(bytes);
        });
      }
    });
  }

  void _parseExcelBytes(Uint8List bytes) {
    try {
      emit(BulkAddLeadsLoading('جاري قراءة الملف...'));
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first; 
      final rows = sheet.rows;
      
      if (rows.length < 2) {
        emit(BulkAddLeadsError('الملف فارغ أو لا يحتوي على بيانات صحيحة'));
        _emitLoaded([_createEmptyRow()]);
        return;
      }

      List<EditableLeadRow> newRows = [];
      
      for (int i = 1; i < rows.length; i++) {
        final r = rows[i];
        if (r.isEmpty) continue;
        
        bool allEmpty = r.every((cell) => cell == null || cell.value.toString().trim().isEmpty);
        if (allEmpty) continue;

        final name = _val(r, 0);
        final phone = _val(r, 1);
        final cityName = _val(r, 2);
        final propTypeName = _val(r, 3);
        final listTypeName = _val(r, 4);
        final platformName = _val(r, 5);
        final channelName = _val(r, 6);
        final statusName = _val(r, 7);
        final assignedToName = _val(r, 8);
        final desc = _val(r, 9);
        final bFrom = _val(r, 10);
        final bTo = _val(r, 11);
        final notes = _val(r, 12);
        final pCode = _val(r, 13);
        final dateStr = _val(r, 14);

        final cityId = _findCityId(cityName);
        final propId = _findId('property_type', propTypeName);
        final listId = _findId('listing_type', listTypeName);
        final platId = _findId('platform', platformName);
        final chanId = _findId('communication_channel', channelName);
        final statId = _findId('lead_status', statusName);
        final userId = _findUserId(assignedToName);

        DateTime? parsedDate;
        if (dateStr != null && dateStr.isNotEmpty) {
          parsedDate = DateTime.tryParse(dateStr);
        }

        newRows.add(EditableLeadRow(
          id: _generateId() + i.toString(),
          name: name,
          phone: phone,
          budgetFrom: bFrom,
          budgetTo: bTo,
          notes: notes,
          propertyCode: pCode,
          descLeadNeed: desc,
          createdAt: parsedDate,
          
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

          assignedTo: userId,
          unmappedAssignedTo: userId == null && assignedToName != null ? assignedToName : null,
        ));
      }

      if (newRows.isEmpty) {
        newRows.add(_createEmptyRow());
      }

      _emitLoaded(newRows);

    } catch (e) {
      emit(BulkAddLeadsError('خطأ في قراءة الملف: $e'));
      emit(BulkAddLeadsLoaded([_createEmptyRow()]));
    }
  }

  String? _val(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) return null;
    final v = row[index]!.value.toString().trim();
    return v.isEmpty ? null : v;
  }

  String? _findId(String tableName, String? name) {
    if (name == null || name.isEmpty) return null;
    return _dataManager.getIdByName(tableName, name);
  }

  int? _findCityId(String? name) {
    if (name == null || name.isEmpty) return null;
    for (var c in _dataManager.allCities) {
      if (c.name == name) return c.id;
    }
    return null;
  }

  String? _findUserId(String? name) {
    if (name == null || name.isEmpty) return null;
    for (var u in _dataManager.employees) {
      final fullName = '${u.firstName} ${u.lastName}'.trim();
      if (fullName == name || u.firstName == name) return u.id;
    }
    return null;
  }

  void downloadTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel.tables[excel.getDefaultSheet()]!;
    
    sheet.appendRow([
      TextCellValue('اسم العميل'),
      TextCellValue('رقم الهاتف (إجباري)'),
      TextCellValue('المدينة (إجباري)'),
      TextCellValue('نوع العقار (إجباري)'),
      TextCellValue('نوع الإعلان (إجباري)'),
      TextCellValue('المنصة القادم منها (إجباري)'),
      TextCellValue('طريقة التواصل'),
      TextCellValue('حالة العميل'),
      TextCellValue('الموظف المسند إليه (إجباري)'),
      TextCellValue('وصف / متطلبات العميل'),
      TextCellValue('الميزانية من'),
      TextCellValue('الميزانية إلى'),
      TextCellValue('ملاحظات'),
      TextCellValue('كود العقار'),
      TextCellValue('تاريخ الإضافة (مثال: 2024-01-01)'),
    ]);

    final bytes = excel.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'Leads_Template.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
