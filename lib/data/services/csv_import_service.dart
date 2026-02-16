import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class CsvImportResult {
  final int inserted;
  final int skipped;
  final List<String> errors;

  CsvImportResult({
    required this.inserted,
    required this.skipped,
    required this.errors,
  });
}

class CsvImportService {
  final AppDatabase db;

  CsvImportService(this.db);

  /// Parse CSV file and return rows as list of maps
  Future<List<Map<String, String>>> parseFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(content);

    if (rows.isEmpty) return [];

    // First row is headers
    final headers = rows.first
        .map((h) => h.toString().trim().toLowerCase())
        .toList();
    final dataRows = rows.skip(1).toList();

    return dataRows.map((row) {
      final map = <String, String>{};
      for (var i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i].toString().trim();
      }
      return map;
    }).toList();
  }

  /// Validate book CSV headers
  List<String> validateBookHeaders(List<Map<String, String>> rows) {
    if (rows.isEmpty) return ['File CSV kosong'];
    final headers = rows.first.keys.toSet();
    final required = {'code', 'title', 'author'};
    final missing = required.difference(headers);
    if (missing.isNotEmpty) {
      return ['Kolom wajib tidak ditemukan: ${missing.join(', ')}'];
    }
    return [];
  }

  /// Validate student CSV headers
  List<String> validateStudentHeaders(List<Map<String, String>> rows) {
    if (rows.isEmpty) return ['File CSV kosong'];
    final headers = rows.first.keys.toSet();
    final required = {'nis', 'name'};
    final missing = required.difference(headers);
    if (missing.isNotEmpty) {
      return ['Kolom wajib tidak ditemukan: ${missing.join(', ')}'];
    }
    return [];
  }

  /// Import books from parsed CSV data
  Future<CsvImportResult> importBooks(List<Map<String, String>> rows) async {
    int inserted = 0;
    int skipped = 0;
    final errors = <String>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowNum = i + 2; // +2 for header row + 0-index

      final code = row['code'] ?? '';
      final title = row['title'] ?? '';
      final author = row['author'] ?? '';

      if (code.isEmpty || title.isEmpty || author.isEmpty) {
        errors.add('Baris $rowNum: code, title, atau author kosong');
        skipped++;
        continue;
      }

      // Check duplicate
      final existing = await db.getBookByCode(code);
      if (existing != null) {
        skipped++;
        continue;
      }

      final qty = int.tryParse(row['qty'] ?? '1') ?? 1;

      try {
        await db.insertBook(
          BooksCompanion.insert(
            code: code,
            title: title,
            author: author,
            publisher: Value(row['publisher'] ?? ''),
            year: Value(int.tryParse(row['year'] ?? '0') ?? 0),
            category: Value(row['category'] ?? 'Umum'),
            totalQty: Value(qty),
            availableQty: Value(qty),
            shelfLocation: Value(row['shelf_location'] ?? ''),
          ),
        );
        inserted++;
      } catch (e) {
        errors.add('Baris $rowNum: ${e.toString().split('\n').first}');
        skipped++;
      }
    }

    return CsvImportResult(
      inserted: inserted,
      skipped: skipped,
      errors: errors,
    );
  }

  /// Import students from parsed CSV data
  Future<CsvImportResult> importStudents(List<Map<String, String>> rows) async {
    int inserted = 0;
    int skipped = 0;
    final errors = <String>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowNum = i + 2;

      final nis = row['nis'] ?? '';
      final name = row['name'] ?? '';

      if (nis.isEmpty || name.isEmpty) {
        errors.add('Baris $rowNum: nis atau name kosong');
        skipped++;
        continue;
      }

      // Check duplicate
      final existing = await (db.select(
        db.students,
      )..where((s) => s.nis.equals(nis))).getSingleOrNull();
      if (existing != null) {
        skipped++;
        continue;
      }

      final gender = (row['gender'] ?? 'L').toUpperCase();

      try {
        await db.insertStudent(
          StudentsCompanion.insert(
            nis: nis,
            name: name,
            classRoom: Value(row['class'] ?? ''),
            gender: Value(gender == 'P' ? 'P' : 'L'),
            status: Value(row['status'] ?? 'aktif'),
          ),
        );
        inserted++;
      } catch (e) {
        errors.add('Baris $rowNum: ${e.toString().split('\n').first}');
        skipped++;
      }
    }

    return CsvImportResult(
      inserted: inserted,
      skipped: skipped,
      errors: errors,
    );
  }
}
