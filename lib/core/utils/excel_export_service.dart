import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class ExcelExportService {
  /// يُظهر مربع حوار للمستخدم لاختيار الأعمدة (غير محددة افتراضياً) 
  /// ويقوم بتصدير البيانات المختارة إلى ملف إكسيل
  static Future<void> showExportDialog({
    required BuildContext context,
    required String title,
    required List<String> allColumns,
    required List<List<dynamic>> dataRows, // كل صف عبارة عن قائمة تتوافق ترتيبها مع allColumns
  }) async {
    final selectedColumns = <int>{}; // نخزن индекات الأعمدة المختارة

    final bool? shouldExport = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('تصدير $title إلى إكسيل'),
              content: SizedBox(
                width: 400.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('يرجى تحديد الأعمدة التي تريد استخراجها (غير مفعلة افتراضياً):',
                        style: TextStyle(fontSize: 14.sp)),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              if (selectedColumns.length == allColumns.length) {
                                selectedColumns.clear();
                              } else {
                                selectedColumns.addAll(List.generate(allColumns.length, (i) => i));
                              }
                            });
                          },
                          child: Text(selectedColumns.length == allColumns.length ? 'إلغاء تحديد الكل' : 'تحديد الكل'),
                        ),
                      ],
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allColumns.length,
                        itemBuilder: (context, index) {
                          return CheckboxListTile(
                            title: Text(allColumns[index]),
                            value: selectedColumns.contains(index),
                            activeColor: AppColors.brandPrimary,
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  selectedColumns.add(index);
                                } else {
                                  selectedColumns.remove(index);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: selectedColumns.isEmpty ? null : () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                  child: const Text('تصدير', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldExport == true && selectedColumns.isNotEmpty) {
      _exportToExcel(
        title: title,
        allColumns: allColumns,
        selectedIndices: selectedColumns.toList()..sort(),
        dataRows: dataRows,
        context: context,
      );
    }
  }

  static Future<void> _exportToExcel({
    required String title,
    required List<String> allColumns,
    required List<int> selectedIndices,
    required List<List<dynamic>> dataRows,
    required BuildContext context,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final excel = Excel.createExcel();
      final sheet = excel[title];
      excel.delete('Sheet1'); // إزالة الورقة الافتراضية

      // كتابة العناوين
      final headerRow = selectedIndices.map((i) => TextCellValue(allColumns[i])).toList();
      sheet.appendRow(headerRow);

      // كتابة البيانات
      for (final row in dataRows) {
        final rowData = selectedIndices.map((i) {
          final val = row.length > i ? row[i] : '';
          return TextCellValue(val?.toString() ?? '');
        }).toList();
        sheet.appendRow(rowData);
      }

      final bytes = excel.encode();
      Navigator.pop(context); // إغلاق نافذة التحميل

      if (bytes != null) {
        final fileName = '${title}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        if (kIsWeb) {
          final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(file.path)], text: 'تقرير $title');
        }
      }
    } catch (e) {
      Navigator.pop(context); // إغلاق نافذة التحميل
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء التصدير: $e')));
    }
  }
}
