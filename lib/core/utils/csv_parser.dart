/// أداة مساعدة لتحليل وتفكيك ملفات CSV القياسية (RFC 4180)
class CsvParser {
  CsvParser._();

  /// تحليل نص CSV إلى قائمة صفوف وخلايا
  static List<List<String>> parse(String input) {
    if (input.isEmpty) return [];

    final List<List<String>> rows = [];
    List<String> currentRow = [];
    final StringBuffer currentCell = StringBuffer();

    bool insideQuotes = false;
    int i = 0;
    final int len = input.length;

    // كشف الفاصل التلقائي (فاصلة أو فاصلة منقوطة أو Tab) من السطر الأول
    final firstLine = input.split(RegExp(r'\r?\n')).firstOrNull ?? '';
    final String delimiter = _detectDelimiter(firstLine);

    while (i < len) {
      final char = input[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < len && input[i + 1] == '"') {
          // علامة تنصيص مزدوجة مكررة "" تعني علامة تنصيص واحدة داخل النص
          currentCell.write('"');
          i += 2;
          continue;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (!insideQuotes && char == delimiter) {
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
      } else if (!insideQuotes && (char == '\r' || char == '\n')) {
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
        
        // التحقق من أن الصف ليس فارغاً تماماً
        if (currentRow.any((c) => c.isNotEmpty)) {
          rows.add(currentRow);
        }
        currentRow = [];

        // تجاوز \r\n ككتلة واحدة
        if (char == '\r' && i + 1 < len && input[i + 1] == '\n') {
          i++;
        }
      } else {
        currentCell.write(char);
      }
      i++;
    }

    // إضافة الخلية الأخيرة والصف الأخير إن وُجدت بيانات متبقية
    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString().trim());
      if (currentRow.any((c) => c.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  static String _detectDelimiter(String line) {
    int commas = 0;
    int semicolons = 0;
    int tabs = 0;
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') inQuotes = !inQuotes;
      if (!inQuotes) {
        if (c == ',') commas++;
        if (c == ';') semicolons++;
        if (c == '\t') tabs++;
      }
    }

    if (semicolons > commas && semicolons > tabs) return ';';
    if (tabs > commas && tabs > semicolons) return '\t';
    return ',';
  }
}
