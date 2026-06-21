import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import '../../../data/models/lead_model.dart';

class DashboardExportHelper {
  static Future<void> exportToExcel(List<LeadModel> leads) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['العملاء'];
      excel.delete('Sheet1'); // Remove default sheet

      // Header row
      sheet.appendRow([
        TextCellValue('#'),
        TextCellValue('اسم العميل'),
        TextCellValue('أرقام الهاتف'),
        TextCellValue('المسؤول عن العميل'),
        TextCellValue('الحالة الحالية'),
        TextCellValue('نوع الإعلان'),
        TextCellValue('نوع العقار'),
        TextCellValue('المحافظة'),
        TextCellValue('المدينة'),
        TextCellValue('المنصة'),
        TextCellValue('الملاحظات'),
        TextCellValue('سجل تغيير الحالات'),
        TextCellValue('تاريخ الإضافة'),
      ]);

      for (int i = 0; i < leads.length; i++) {
        final l = leads[i];
        final phonesStr = l.phones.map((p) => p.phoneNumber).join('، ');
        final notesStr = l.notes.map((n) => '[${n.userName ?? "موظف"}: ${n.noteText}]').join('\n');
        final logsStr = l.logs
            .where((log) => log.action == 'status_changed')
            .map((log) => '${log.oldStatusName ?? "—"} ➔ ${log.newStatusName ?? "—"} (${DateFormat("yyyy/MM/dd").format(log.createdAt)})')
            .join(' | ');

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(l.clientName),
          TextCellValue(phonesStr),
          TextCellValue(l.assignedToName ?? '—'),
          TextCellValue(l.leadStatus ?? '—'),
          TextCellValue(l.listingType ?? '—'),
          TextCellValue(l.propertyType ?? '—'),
          TextCellValue(l.governorate ?? '—'),
          TextCellValue(l.city ?? '—'),
          TextCellValue(l.platform ?? '—'),
          TextCellValue(notesStr),
          TextCellValue(logsStr),
          TextCellValue(l.createdAt != null ? DateFormat("yyyy/MM/dd HH:mm").format(l.createdAt!) : '—')
        ]);
      }

      final bytes = excel.save();
      if (bytes != null) {
        if (kIsWeb) {
          final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "leads_report_${DateTime.now().millisecondsSinceEpoch}.xlsx")
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/leads_export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(file.path)], text: 'تقرير العملاء Excel');
        }
      }
    } catch (e) {
      debugPrint("Excel Export Error: $e");
    }
  }

  static Future<void> exportToPdf(List<LeadModel> leads) async {
    try {
      if (kIsWeb) {
        // Generate high-fidelity HTML print output which renders Arabic beautifully and natively
        final buf = StringBuffer();
        buf.write('''
          <html>
            <head>
              <meta charset="utf-8">
              <title>تقرير العملاء</title>
              <style>
                body {
                  font-family: 'Cairo', Tahoma, Arial, sans-serif;
                  direction: rtl;
                  padding: 20px;
                  background-color: #fff;
                  color: #333;
                }
                h1 {
                  text-align: center;
                  color: #1E3A8A;
                  margin-bottom: 20px;
                  font-size: 24px;
                }
                table {
                  width: 100%;
                  border-collapse: collapse;
                  margin-top: 10px;
                  font-size: 12px;
                }
                th, td {
                  border: 1px solid #CBD5E1;
                  padding: 8px 10px;
                  text-align: right;
                }
                th {
                  background-color: #F1F5F9;
                  color: #1E3A8A;
                  font-weight: bold;
                }
                tr:nth-child(even) {
                  background-color: #F8FAFC;
                }
                .meta {
                  text-align: left;
                  font-size: 11px;
                  color: #64748B;
                  margin-bottom: 10px;
                }
                @media print {
                  body { padding: 0; }
                  button { display: none; }
                }
              </style>
            </head>
            <body>
              <h1>تقرير تفاصيل العملاء</h1>
              <div class="meta">تاريخ التصدير: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())} | إجمالي العملاء: ${leads.length}</div>
              <table>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>اسم العميل</th>
                    <th>الهاتف</th>
                    <th>المسؤول</th>
                    <th>الحالة</th>
                    <th>نوع الإعلان</th>
                    <th>نوع العقار</th>
                    <th>المدينة</th>
                    <th>الملاحظات</th>
                    <th>سجل انتقالات الحالة</th>
                  </tr>
                </thead>
                <tbody>
        ''');

        for (int i = 0; i < leads.length; i++) {
          final l = leads[i];
          final phonesStr = l.phones.map((p) => p.phoneNumber).join('<br>');
          final notesStr = l.notes.map((n) => '• <b>${n.userName ?? "موظف"}:</b> ${n.noteText}').join('<br>');
          final logsStr = l.logs
              .where((log) => log.action == 'status_changed')
              .map((log) => '${log.oldStatusName ?? "—"} ➔ ${log.newStatusName ?? "—"} (${DateFormat("yyyy/MM/dd").format(log.createdAt)})')
              .join('<br>');

          buf.write('''
            <tr>
              <td>${i + 1}</td>
              <td><b>${l.clientName}</b></td>
              <td style="direction: ltr; text-align: left;">$phonesStr</td>
              <td>${l.assignedToName ?? '—'}</td>
              <td>${l.leadStatus ?? '—'}</td>
              <td>${l.listingType ?? '—'}</td>
              <td>${l.propertyType ?? '—'}</td>
              <td>${l.city ?? '—'}</td>
              <td style="font-size: 10px;">$notesStr</td>
              <td style="font-size: 10px;">$logsStr</td>
            </tr>
          ''');
        }

        buf.write('''
                </tbody>
              </table>
              <script>
                window.onload = function() {
                  window.print();
                }
              </script>
            </body>
          </html>
        ''');

        final blob = html.Blob([buf.toString()], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);
      } else {
        // Fallback for mobile: Excel is cleaner since pdf requires full font assets shaping, 
        // but we share Excel file which is widely compatible
        await exportToExcel(leads);
      }
    } catch (e) {
      debugPrint("PDF Export Error: $e");
    }
  }
}
