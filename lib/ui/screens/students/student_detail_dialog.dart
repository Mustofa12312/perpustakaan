import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class StudentDetailDialog extends ConsumerStatefulWidget {
  final Student student;
  const StudentDetailDialog({super.key, required this.student});

  @override
  ConsumerState<StudentDetailDialog> createState() =>
      _StudentDetailDialogState();
}

class _StudentDetailDialogState extends ConsumerState<StudentDetailDialog> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLoansAsync = ref.watch(loansWithDetailsProvider(null));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(28),
        child: allLoansAsync.when(
          data: (loans) {
            final myLoans = loans
                .where((l) => l.studentId == widget.student.id)
                .toList();
            final activeLoans = myLoans
                .where((l) => l.loanStatus == 'dipinjam')
                .toList();
            final historyLoans = myLoans
                .where((l) => l.loanStatus != 'dipinjam')
                .toList();

            final totalFines = myLoans
                .where((l) => l.fineAmount != null && l.isPaid == false)
                .fold<int>(0, (sum, l) => sum + (l.fineAmount ?? 0));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: widget.student.gender == 'L'
                          ? AppColors.info.withAlpha(25)
                          : AppColors.accent.withAlpha(25),
                      backgroundImage: widget.student.photo.isNotEmpty
                          ? MemoryImage(base64Decode(widget.student.photo))
                          : null,
                      child: widget.student.photo.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: widget.student.gender == 'L'
                                  ? AppColors.info
                                  : AppColors.accent,
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.student.name,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'NIS: ${widget.student.nis} • Kelas: ${widget.student.classRoom}',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: activeLoans.isEmpty && totalFines == 0
                          ? () => _printClearanceLetter(context)
                          : null, // Disabled if there are active loans or fines
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Bebas Pustaka'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(
                          color: activeLoans.isEmpty && totalFines == 0
                              ? AppColors.success
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _StatCard(
                      title: 'Sedang Dipinjam',
                      value: activeLoans.length.toString(),
                      color: AppColors.info,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      title: 'Tanggungan Denda',
                      value: 'Rp ${NumberFormat('#,###').format(totalFines)}',
                      color: totalFines > 0
                          ? AppColors.danger
                          : AppColors.success,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      title: 'Riwayat Selesai',
                      value: historyLoans.length.toString(),
                      color: AppColors.accent,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Sedang Dipinjam & Tanggungan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: activeLoans.isEmpty && totalFines == 0
                        ? Center(
                            child: Text(
                              'Tidak ada tanggungan, bisa cetak Surat Bebas Pustaka.',
                              style: GoogleFonts.inter(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: myLoans.length,
                            itemBuilder: (ctx, i) {
                              final l = myLoans[i];
                              if (l.loanStatus == 'dikembalikan' &&
                                  (l.fineAmount == null || l.isPaid == true)) {
                                return const SizedBox.shrink(); // Hide completed
                              }
                              return ListTile(
                                leading: Icon(
                                  l.loanStatus == 'dipinjam'
                                      ? Icons.menu_book
                                      : Icons.money_off,
                                  color: l.loanStatus == 'dipinjam'
                                      ? AppColors.info
                                      : AppColors.danger,
                                ),
                                title: Text(
                                  l.bookTitle,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Pinjam: ${DateFormat('dd/MM/yyyy').format(l.loanDate)} - Status: ${l.loanStatus}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                trailing:
                                    l.fineAmount != null && l.isPaid == false
                                    ? Text(
                                        'Denda: Rp ${NumberFormat('#,###').format(l.fineAmount)}',
                                        style: GoogleFonts.inter(
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Future<void> _printClearanceLetter(BuildContext context) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(now);

    final db = ref.read(databaseProvider);
    final sMap = await db.getAllSettings();
    final libraryName = sMap['library_name'] ?? 'Perpustakaan Pondok Pesantren';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      libraryName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 2),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  'SURAT KETERANGAN BEBAS PUSTAKA',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Yang bertanda tangan di bawah ini menerangkan bahwa:'),
              pw.SizedBox(height: 15),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Nama              : ${widget.student.name}'),
                    pw.Text('NIS/NIM         : ${widget.student.nis}'),
                    pw.Text('Kelas/Kamar : ${widget.student.classRoom}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                'Santri tersebut di atas tidak memiliki tanggungan peminjaman buku maupun denda di lingkungan $libraryName.',
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Surat keterangan ini diberikan untuk digunakan sebagaimana mestinya (sebagai syarat kelulusan / pengambilan ijazah).',
              ),
              pw.SizedBox(height: 60),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Dikeluarkan pada: $formattedDate'),
                      pw.Text('Kepala Perpustakaan'),
                      pw.SizedBox(height: 70),
                      pw.Text('( _______________________ )'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 20),
          border: Border.all(color: color.withAlpha(50)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
