import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/app_database.dart';

class PdfReportService {
  final AppDatabase db;

  PdfReportService(this.db);

  Future<String> _getLibraryName() async {
    final setting = await (db.select(
      db.settings,
    )..where((s) => s.key.equals('library_name'))).getSingleOrNull();
    return setting?.value ?? 'Perpustakaan Pondok Pesantren';
  }

  /// Generate Book Report
  Future<Uint8List> generateBookReport(List<Book> books) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(now);
    final libraryName = await _getLibraryName();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(context, libraryName, 'Laporan Data Buku'),
        footer: (context) => _buildFooter(context, formattedDate),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Kode',
              'Judul',
              'Penulis',
              'Kategori',
              'Qty',
              'Rak',
            ],
            data: List.generate(books.length, (index) {
              final book = books[index];
              return [
                (index + 1).toString(),
                book.code,
                book.title,
                book.author,
                book.category,
                book.totalQty.toString(),
                book.shelfLocation,
              ];
            }),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {0: pw.Alignment.center, 5: pw.Alignment.center},
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Student Report
  Future<Uint8List> generateStudentReport(List<Student> students) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(now);
    final libraryName = await _getLibraryName();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(context, libraryName, 'Laporan Data Santri'),
        footer: (context) => _buildFooter(context, formattedDate),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['No', 'NIS', 'Nama', 'Kelas', 'L/P', 'Status'],
            data: List.generate(students.length, (index) {
              final s = students[index];
              return [
                (index + 1).toString(),
                s.nis,
                s.name,
                s.classRoom,
                s.gender,
                s.status,
              ];
            }),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Loan Report
  Future<Uint8List> generateLoanReport(
    List<Loan> loans,
    List<Student> students,
    List<Book> books,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(now);
    final libraryName = await _getLibraryName();

    // Map IDs to Objects for faster lookup
    final studentMap = {for (var s in students) s.id: s};
    final bookMap = {for (var b in books) b.id: b};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape for more columns
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(context, libraryName, 'Laporan Peminjaman'),
        footer: (context) => _buildFooter(context, formattedDate),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Nama Santri',
              'Judul Buku',
              'Tgl Pinjam',
              'Tenggat',
              'Kembali',
              'Status',
            ],
            data: List.generate(loans.length, (index) {
              final loan = loans[index];
              final s = studentMap[loan.studentId];
              final b = bookMap[loan.bookId];

              final borrowDate = DateFormat('dd/MM/yy').format(loan.loanDate);
              final dueDate = DateFormat('dd/MM/yy').format(loan.dueDate);
              final returnDate = loan.returnDate != null
                  ? DateFormat('dd/MM/yy').format(loan.returnDate!)
                  : '-';

              return [
                (index + 1).toString(),
                s?.name ?? 'Unknown',
                b?.title ?? 'Unknown',
                borrowDate,
                dueDate,
                returnDate,
                loan.status,
              ];
            }),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.orange900,
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.Context context, String appName, String title) {
    return pw.Column(
      children: [
        pw.Text(
          appName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Laporan Perpustakaan',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.Divider(thickness: 1, indent: 2, endIndent: 2), // Double line effect
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context, String date) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak pada: $date',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }
}
