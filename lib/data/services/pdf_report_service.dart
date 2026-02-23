import 'dart:convert';
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

  /// Generate Overdue Report
  Future<Uint8List> generateOverdueReport(
    List<Loan> loans,
    List<Student> students,
    List<Book> books,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(now);
    final libraryName = await _getLibraryName();

    final studentMap = {for (var s in students) s.id: s};
    final bookMap = {for (var b in books) b.id: b};

    final overdueLoans = loans
        .where(
          (l) => l.status == 'dipinjam' && l.dueDate.isBefore(DateTime.now()),
        )
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          context,
          libraryName,
          'Laporan Keterlambatan Pengembalian',
        ),
        footer: (context) => _buildFooter(context, formattedDate),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Nama Santri',
              'Judul Buku',
              'Tgl Pinjam',
              'Jatuh Tempo',
              'Telat (Hari)',
            ],
            data: List.generate(overdueLoans.length, (index) {
              final loan = overdueLoans[index];
              final s = studentMap[loan.studentId];
              final b = bookMap[loan.bookId];
              final daysLate = DateTime.now().difference(loan.dueDate).inDays;

              return [
                (index + 1).toString(),
                s?.name ?? 'Unknown',
                b?.title ?? 'Unknown',
                DateFormat('dd/MM/yy').format(loan.loanDate),
                DateFormat('dd/MM/yy').format(loan.dueDate),
                daysLate.toString(),
              ];
            }),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
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

  /// Generate Fines Report
  Future<Uint8List> generateFinesReport(
    List<Fine> fines,
    List<Loan> loans,
    List<Student> students,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(now);
    final libraryName = await _getLibraryName();

    final loanMap = {for (var l in loans) l.id: l};
    final studentMap = {for (var s in students) s.id: s};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(context, libraryName, 'Laporan Data Denda'),
        footer: (context) => _buildFooter(context, formattedDate),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Nama Santri',
              'Tgl Denda',
              'Telat (Hari)',
              'Jumlah (Rp)',
              'Status',
            ],
            data: List.generate(fines.length, (index) {
              final fine = fines[index];
              final loan = loanMap[fine.loanId];
              final student = loan != null ? studentMap[loan.studentId] : null;

              return [
                (index + 1).toString(),
                student?.name ?? '-',
                DateFormat('dd/MM/yy').format(fine.createdAt),
                fine.daysLate.toString(),
                NumberFormat('#,###', 'id_ID').format(fine.amount),
                fine.isPaid ? 'Lunas' : 'Belum Lunas',
              ];
            }),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.orange800,
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
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateStatsReport(
    int totalBooks,
    int totalStudents,
    int activeLoans,
    int overdueLoans,
    List<TopVisitor> topVisitors,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(now);
    final libraryName = await _getLibraryName();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(context, libraryName, 'Laporan Statistik Bulanan'),
        footer: (context) => _buildFooter(context, formattedDate),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.grey100,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Buku', totalBooks.toString()),
                _buildStatItem('Total Santri', totalStudents.toString()),
                _buildStatItem('Sedang Dipinjam', activeLoans.toString()),
                _buildStatItem('Terlambat', overdueLoans.toString()),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Santri Paling Rajin (Top 5)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Rank', 'Nama Santri', 'Total Kunjungan'],
            data: List.generate(topVisitors.length, (index) {
              final visitor = topVisitors[index];
              return [
                '#${index + 1}',
                visitor.student.name,
                visitor.visitCount.toString(),
              ];
            }),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {0: pw.Alignment.center, 2: pw.Alignment.center},
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Generate Book Barcode Labels (e.g. 3x7 per page A4)
  Future<Uint8List> generateBookBarcodes(List<Book> books) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(books.length, (index) {
                final book = books[index];
                return pw.Container(
                  width: 170,
                  height: 80,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        book.title.length > 25
                            ? '${book.title.substring(0, 25)}...'
                            : book.title,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 4),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: book.code,
                        width: 140,
                        height: 40,
                        drawText: true,
                        textStyle: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generate Student ID Cards
  Future<Uint8List> generateStudentCards(List<Student> students) async {
    final pdf = pw.Document();
    final libraryName = await _getLibraryName();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Wrap(
              spacing: 15,
              runSpacing: 15,
              children: List.generate(students.length, (index) {
                final s = students[index];
                return pw.Container(
                  width: 240, // ID Card size approx
                  height: 150,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      // Header
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(4),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue800,
                          borderRadius: pw.BorderRadius.vertical(
                            top: pw.Radius.circular(7),
                          ),
                        ),
                        child: pw.Text(
                          libraryName,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            // Photo Area
                            pw.Container(
                              width: 70,
                              margin: const pw.EdgeInsets.all(8),
                              color: PdfColors.grey200,
                              child: s.photo.isNotEmpty
                                  ? pw.Image(
                                      pw.MemoryImage(base64Decode(s.photo)),
                                      fit: pw.BoxFit.cover,
                                    )
                                  : pw.Center(
                                      child: pw.Icon(
                                        const pw.IconData(0xe7fd), // Person
                                        size: 40,
                                        color: PdfColors.grey400,
                                      ),
                                    ),
                            ),
                            // Details
                            pw.Expanded(
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      s.name,
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      'NIS: ${s.nis}',
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                    pw.Text(
                                      s.classRoom,
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.BarcodeWidget(
                                      barcode: pw.Barcode.code128(),
                                      data: s.nis,
                                      height: 30,
                                      width: 100,
                                      drawText: false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Footer
                      pw.Container(
                        width: double.infinity,
                        height: 15,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.orange500,
                          borderRadius: pw.BorderRadius.vertical(
                            bottom: pw.Radius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ];
        },
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
