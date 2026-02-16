import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/csv_import_service.dart';
import '../../data/database/app_database.dart';

enum ImportType { books, students }

class CsvImportDialog extends StatefulWidget {
  final ImportType importType;
  final AppDatabase database;

  const CsvImportDialog({
    super.key,
    required this.importType,
    required this.database,
  });

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  String? _filePath;
  String? _fileName;
  List<Map<String, String>>? _previewData;
  List<String>? _validationErrors;
  CsvImportResult? _result;
  bool _isLoading = false;
  bool _isImporting = false;

  String get _typeLabel =>
      widget.importType == ImportType.books ? 'Buku' : 'Santri';

  String get _templateInfo {
    if (widget.importType == ImportType.books) {
      return 'Kolom wajib: code, title, author\n'
          'Kolom opsional: publisher, year, category, qty, shelf_location';
    } else {
      return 'Kolom wajib: nis, name\n'
          'Kolom opsional: class, gender (L/P), status (aktif/alumni)';
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Pilih File CSV $_typeLabel',
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _validationErrors = null;
    });

    try {
      final path = result.files.single.path!;
      final service = CsvImportService(widget.database);
      final data = await service.parseFile(path);

      // Validate headers
      final errors = widget.importType == ImportType.books
          ? service.validateBookHeaders(data)
          : service.validateStudentHeaders(data);

      setState(() {
        _filePath = path;
        _fileName = result.files.single.name;
        _previewData = data;
        _validationErrors = errors.isEmpty ? null : errors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _validationErrors = ['Gagal membaca file: ${e.toString()}'];
        _isLoading = false;
      });
    }
  }

  Future<void> _doImport() async {
    if (_previewData == null || _filePath == null) return;

    setState(() => _isImporting = true);

    final service = CsvImportService(widget.database);
    final result = widget.importType == ImportType.books
        ? await service.importBooks(_previewData!)
        : await service.importStudents(_previewData!);

    setState(() {
      _result = result;
      _isImporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import $_typeLabel dari CSV',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Upload file CSV untuk menambah data secara massal',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Template info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _templateInfo,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.accent,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // File picker area
            if (_result == null) ...[
              InkWell(
                onTap: _isLoading ? null : _pickFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: isDark
                        ? Colors.white.withAlpha(5)
                        : Colors.black.withAlpha(5),
                  ),
                  child: Column(
                    children: [
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        Icon(
                          _fileName != null
                              ? Icons.description_rounded
                              : Icons.cloud_upload_outlined,
                          size: 36,
                          color: _fileName != null
                              ? AppColors.success
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _fileName ?? 'Klik untuk memilih file CSV',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: _fileName != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _fileName != null
                                ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary)
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                          ),
                        ),
                        if (_previewData != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_previewData!.length} baris data ditemukan',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Validation errors
            if (_validationErrors != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _validationErrors!
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $e',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            // Preview table
            if (_previewData != null &&
                _validationErrors == null &&
                _result == null) ...[
              const SizedBox(height: 14),
              Text(
                'Preview (${_previewData!.length > 5 ? "5 baris pertama" : "${_previewData!.length} baris"}):',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: _buildPreviewTable(isDark),
                  ),
                ),
              ),
            ],

            // Result
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(isDark),
            ],

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_result != null),
                  child: Text(
                    _result != null ? 'Tutup' : 'Batal',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (_previewData != null &&
                    _validationErrors == null &&
                    _result == null) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isImporting ? null : _doImport,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_rounded, size: 18),
                    label: Text(
                      _isImporting
                          ? 'Mengimpor...'
                          : 'Import ${_previewData!.length} $_typeLabel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable(bool isDark) {
    final preview = _previewData!.take(5).toList();
    final headers = preview.first.keys.toList();

    return DataTable(
      headingRowHeight: 36,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 32,
      columnSpacing: 20,
      headingTextStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      dataTextStyle: GoogleFonts.inter(
        fontSize: 11,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
      ),
      columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
      rows: preview
          .map(
            (row) => DataRow(
              cells: headers
                  .map(
                    (h) => DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          row[h] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  Widget _buildResultCard(bool isDark) {
    final result = _result!;
    final hasErrors = result.errors.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasErrors
            ? AppColors.accent.withAlpha(12)
            : AppColors.success.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasErrors
              ? AppColors.accent.withAlpha(40)
              : AppColors.success.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasErrors
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: hasErrors ? AppColors.accent : AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Import Selesai',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _resultBadge(
                '${result.inserted} berhasil',
                AppColors.success,
                isDark,
              ),
              const SizedBox(width: 8),
              if (result.skipped > 0)
                _resultBadge(
                  '${result.skipped} dilewati',
                  AppColors.accent,
                  isDark,
                ),
            ],
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...result.errors
                .take(5)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $e',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
            if (result.errors.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '...dan ${result.errors.length - 5} error lainnya',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _resultBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
