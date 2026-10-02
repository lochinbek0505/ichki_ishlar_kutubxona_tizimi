import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

/// Excel hisobotidagi bitta kitob qatori
class ExcelBookRow {
  final int rowNumber; // № пп
  final String title; // Наименование предмета
  final int publishedYear; // Дата выпуск (yili)
  final int copies; // Oy oxiridagi qoldiq soni
  final double sum; // Oy oxiridagi qoldiq summasi

  const ExcelBookRow({
    required this.rowNumber,
    required this.title,
    required this.publishedYear,
    required this.copies,
    required this.sum,
  });
}

class ExcelImportResult {
  final String fileName;
  final List<ExcelBookRow> rows;

  const ExcelImportResult({required this.fileName, required this.rows});

  int get totalCopies => rows.fold(0, (sum, r) => sum + r.copies);
}

/// Kutubxona "Ахборот-ресурс марказидаги китоблар бўйича хисобати" kabi
/// .xlsx fayllarni o'qib, kitoblar ro'yxatiga aylantiradi.
class ExcelImportService {
  static final ExcelImportService instance = ExcelImportService._internal();

  ExcelImportService._internal();

  /// Diskdan .xlsx faylni tanlash va o'qish. Foydalanuvchi bekor qilsa null qaytaradi.
  Future<ExcelImportResult?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      throw const FormatException('Faylni o\'qib bo\'lmadi');
    }

    final rows = await compute(parseXlsx, bytes);
    return ExcelImportResult(fileName: file.name, rows: rows);
  }
}

/// .xlsx baytlarini tahlil qiladi (isolate ichida ishlashi uchun top-level).
List<ExcelBookRow> parseXlsx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('Fayl .xlsx formatida emas');
  }

  String? readEntry(String name) {
    final entry = archive.findFile(name);
    if (entry == null) return null;
    return utf8.decode(entry.content as List<int>, allowMalformed: true);
  }

  final sharedStrings = <String>[];
  final sstXml = readEntry('xl/sharedStrings.xml');
  if (sstXml != null) {
    for (final si in XmlDocument.parse(sstXml).findAllElements('si')) {
      // Rich text (r/t) bo'laklarini birlashtiramiz, fonetik (rPh) qismlarsiz
      final buffer = StringBuffer();
      for (final t in si.findAllElements('t')) {
        if (t.parentElement?.name.local == 'rPh') continue;
        buffer.write(t.innerText);
      }
      sharedStrings.add(buffer.toString());
    }
  }

  final sheetXml = readEntry(_firstSheetPath(readEntry));
  if (sheetXml == null) {
    throw const FormatException('Excel faylda varaq topilmadi');
  }

  // Qatorlarni {ustun indeksi: qiymat} ko'rinishiga keltiramiz
  final grid = <Map<int, String>>[];
  for (final row in XmlDocument.parse(sheetXml).findAllElements('row')) {
    final cells = <int, String>{};
    for (final c in row.findElements('c')) {
      final ref = c.getAttribute('r');
      if (ref == null) continue;
      final value = _cellValue(c, sharedStrings);
      if (value == null || value.trim().isEmpty) continue;
      cells[_columnIndex(ref)] = value.trim();
    }
    grid.add(cells);
  }

  // Sarlavha qatorini topamiz ("Наименование предмета")
  var titleCol = 1, dateCol = 2, countCol = 10, headerRow = -1;
  for (var i = 0; i < grid.length && headerRow < 0; i++) {
    grid[i].forEach((col, text) {
      final lower = text.toLowerCase();
      if (lower.contains('наименование') || lower.contains('nomi') || lower.contains('номи')) {
        titleCol = col;
        headerRow = i;
      }
    });
  }
  if (headerRow >= 0) {
    // "Дата выпуск" — birinchi sana ustuni ("01.08.2026 йил" kabi davr ustunlari emas)
    final dateEntry = grid[headerRow].entries
        .where((e) => e.key != titleCol && RegExp(r'дата|sana|нашр|nashr', caseSensitive: false).hasMatch(e.value))
        .firstOrNull;
    if (dateEntry != null) dateCol = dateEntry.key;
    // Eng oxirgi "Сони" ustuni — oy oxiridagi qoldiq
    var lastCountCol = -1;
    for (var i = headerRow; i < grid.length && i <= headerRow + 3; i++) {
      grid[i].forEach((col, text) {
        final lower = text.toLowerCase();
        if ((lower.contains('сони') || lower.contains('soni')) && col > lastCountCol) lastCountCol = col;
      });
    }
    if (lastCountCol >= 0) countCol = lastCountCol;
  }

  final rows = <ExcelBookRow>[];
  for (var i = headerRow + 1; i < grid.length; i++) {
    final cells = grid[i];
    final number = double.tryParse(cells[0] ?? '');
    final title = cells[titleCol];
    // "Жами" kabi yakuniy qatorlarda № bo'lmaydi
    if (number == null || title == null) continue;

    final copies = (double.tryParse(cells[countCol] ?? '') ?? 0).round();
    if (copies <= 0) continue;

    rows.add(ExcelBookRow(
      rowNumber: number.toInt(),
      title: title.replaceAll(RegExp(r'\s+'), ' '),
      publishedYear: _parseYear(cells[dateCol]),
      copies: copies,
      sum: double.tryParse(cells[countCol + 1] ?? '') ?? 0,
    ));
  }

  if (rows.isEmpty) {
    throw const FormatException('Faylda kitoblar topilmadi. Jadval tuzilishini tekshiring.');
  }
  return rows;
}

String _firstSheetPath(String? Function(String) readEntry) {
  const fallback = 'xl/worksheets/sheet1.xml';
  final workbook = readEntry('xl/workbook.xml');
  final rels = readEntry('xl/_rels/workbook.xml.rels');
  if (workbook == null || rels == null) return fallback;

  final sheet = XmlDocument.parse(workbook).findAllElements('sheet').firstOrNull;
  final relId = sheet?.attributes.where((a) => a.name.local == 'id').firstOrNull?.value;
  if (relId == null) return fallback;

  for (final rel in XmlDocument.parse(rels).findAllElements('Relationship')) {
    if (rel.getAttribute('Id') == relId) {
      final target = rel.getAttribute('Target') ?? '';
      return target.startsWith('/') ? target.substring(1) : 'xl/$target';
    }
  }
  return fallback;
}

String? _cellValue(XmlElement c, List<String> sharedStrings) {
  final type = c.getAttribute('t');
  if (type == 'inlineStr') {
    return c.findAllElements('t').map((t) => t.innerText).join();
  }
  final v = c.getElement('v')?.innerText;
  if (v == null || type == 'e') return null;
  if (type == 's') {
    final idx = int.tryParse(v);
    return (idx != null && idx < sharedStrings.length) ? sharedStrings[idx] : null;
  }
  return v;
}

/// "AB12" -> 27
int _columnIndex(String ref) {
  var index = 0;
  for (final code in ref.codeUnits) {
    if (code < 65 || code > 90) break;
    index = index * 26 + (code - 64);
  }
  return index - 1;
}

/// "01.01.2002", "2023" yoki Excel sana raqami (37257) dan yilni ajratadi
int _parseYear(String? raw) {
  if (raw == null) return 0;
  final match = RegExp(r'(1[89]\d{2}|20\d{2})').allMatches(raw).lastOrNull;
  final numeric = double.tryParse(raw);
  if (numeric != null && numeric > 3000 && numeric < 80000) {
    return DateTime(1899, 12, 30).add(Duration(days: numeric.toInt())).year;
  }
  return match != null ? int.parse(match.group(0)!) : 0;
}
