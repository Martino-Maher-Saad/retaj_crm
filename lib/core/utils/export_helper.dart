import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../../data/models/lead_model.dart';
import '../../data/models/form_field_model.dart';
import 'static_data_manager.dart';
import '../di/injection_container.dart' as di;

class ExportHelper {
  static Future<void> exportLeadsToExcel(List<LeadModel> leads, List<FormFieldModel> selectedColumns) async {
    final excel = Excel.createExcel();
    final sheet = excel['العملاء'];
    excel.setDefaultSheet('العملاء');

    // Headers
    sheet.appendRow(selectedColumns.map((col) => TextCellValue(col.titleAr)).toList());

    final staticManager = di.sl<StaticDataManager>();

    // Data
    for (final lead in leads) {
      final row = <CellValue>[];
      for (final field in selectedColumns) {
        String valueStr = '-';
        if (field.isSystem) {
          switch (field.fieldKey) {
            case 'client_name': valueStr = lead.clientName; break;
            case 'phones': valueStr = lead.phones.map((e) => e.phoneNumber).join(' - '); break;
            case 'property_type_id': valueStr = lead.propertyType ?? '-'; break;
            case 'listing_type_id': valueStr = lead.listingType ?? '-'; break;
            case 'city_id': valueStr = lead.city ?? '-'; break;
            case 'budget_from': valueStr = lead.budgetFrom?.toString() ?? '-'; break;
            case 'budget_to': valueStr = lead.budgetTo?.toString() ?? '-'; break;
            case 'lead_status': valueStr = lead.leadStatus ?? '-'; break;
            case 'created_at': valueStr = lead.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(lead.createdAt!) : '-'; break;
            case 'assigned_to': valueStr = lead.assignedToName ?? '-'; break;
            case 'created_by': valueStr = lead.createdByName ?? '-'; break;
            case 'exclusion_reason_id': valueStr = lead.exclusionReasonName ?? '-'; break;
            case 'channel_id': valueStr = lead.communicationChannel ?? '-'; break;
            case 'platform_id': valueStr = lead.platform ?? '-'; break;
            case 'desc_lead_need': valueStr = lead.descLeadNeed ?? '-'; break;
            case 'property_code': valueStr = lead.propertyCode ?? '-'; break;
            default:
              valueStr = lead.customFields?[field.fieldKey]?.toString() ?? '-';
          }
        } else {
          final customVal = lead.customFields?[field.fieldKey];
          if (customVal != null) {
            if (field.inputType == FormFieldInputType.checkbox) {
              valueStr = (customVal == true || customVal == 'true' || customVal == 1) ? 'نعم' : 'لا';
            } else if (field.inputType == FormFieldInputType.selectStatic) {
              try {
                valueStr = field.options.firstWhere((o) => o.value == customVal.toString()).label;
              } catch (_) { valueStr = customVal.toString(); }
            } else if (field.inputType == FormFieldInputType.selectRef && field.refTable != null) {
              try {
                valueStr = staticManager.getRefTableOptions(field.refTable!).firstWhere((o) => o.id == customVal.toString()).nameAr;
              } catch (_) { valueStr = customVal.toString(); }
            } else if (field.inputType == FormFieldInputType.date) {
               try {
                  valueStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(customVal.toString()));
               } catch (_) { valueStr = customVal.toString(); }
            } else {
              valueStr = customVal.toString();
            }
          }
        }
        row.add(TextCellValue(valueStr.isEmpty ? '-' : valueStr));
      }
      sheet.appendRow(row);
    }

    // Save
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'leads_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
