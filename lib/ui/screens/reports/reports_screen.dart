import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/pdf_report_service.dart';
import '../../../providers/providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _generateReport(
    BuildContext context,
    WidgetRef ref,
    String title,
    Future<Uint8List> Function(PdfReportService) generator,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = ref.read(databaseProvider);
      final service = PdfReportService(db);
      final pdfBytes = await generator(service);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: title,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat laporan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c1 = dk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = dk ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pusat Laporan',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola, analisa, dan cetak laporan perpustakaan Anda dengan format yang rapi.',
            style: GoogleFonts.inter(fontSize: 14, color: c2, height: 1.5),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Data Master & Analitik', dk),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.3,
                    children: [
                      _ReportCard(
                        icon: Icons.list_alt_rounded,
                        title: 'Daftar Buku',
                        desc: 'Semua koleksi perpustakaan',
                        color: AppColors.info,
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Laporan Data Buku',
                          (s) async {
                            final books = await s.db.getAllBooks();
                            return s.generateBookReport(books);
                          },
                        ),
                      ),
                      _ReportCard(
                        icon: Icons.people_rounded,
                        title: 'Daftar Santri',
                        desc: 'Semua data anggota aktif',
                        color: AppColors.success,
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Laporan Data Santri',
                          (s) async {
                            final students = await s.db.getAllStudents();
                            return s.generateStudentReport(students);
                          },
                        ),
                      ),
                      _ReportCard(
                        icon: Icons.analytics_rounded,
                        title: 'Statistik',
                        desc: 'Perkembangan & ringkasan',
                        color: AppColors.primary,
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Laporan Statistik',
                          (s) async {
                            final totalBooks = await s.db.getTotalBooks();
                            final totalStudents = await s.db.getTotalStudents();
                            final activeLoans = await s.db
                                .getActiveLoansCount();
                            final overdueLoans = await s.db
                                .getOverdueLoansCount();
                            final topVisitors = await s.db.getTopVisitors();
                            return s.generateStatsReport(
                              totalBooks,
                              totalStudents,
                              activeLoans,
                              overdueLoans,
                              topVisitors,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Sirkulasi & Keuangan', dk),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.3,
                    children: [
                      _ReportCard(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Peminjaman',
                        desc: 'Riwayat sirkulasi buku',
                        color: AppColors.accent,
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Laporan Peminjaman',
                          (s) async {
                            final loans = await s.db.getAllLoans();
                            final students = await s.db.getAllStudents();
                            final books = await s.db.getAllBooks();
                            return s.generateLoanReport(loans, students, books);
                          },
                        ),
                      ),
                      _ReportCard(
                        icon: Icons.warning_rounded,
                        title: 'Keterlambatan',
                        desc: 'Pelanggaran batas waktu',
                        color: AppColors.danger,
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Laporan Keterlambatan',
                          (s) async {
                            final loans = await s.db.getAllLoans();
                            final students = await s.db.getAllStudents();
                            final books = await s.db.getAllBooks();
                            return s.generateOverdueReport(
                              loans,
                              students,
                              books,
                            );
                          },
                        ),
                      ),
                      _ReportCard(
                        icon: Icons.monetization_on_rounded,
                        title: 'Denda',
                        desc: 'Rekapitulasi denda santri',
                        color: AppColors.warning,
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Laporan Denda',
                          (s) async {
                            final fines = await s.db.getAllFines();
                            final loans = await s.db.getAllLoans();
                            final students = await s.db.getAllStudents();
                            return s.generateFinesReport(
                              fines,
                              loans,
                              students,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Cetak Fisik & Perlengkapan', dk),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.3,
                    children: [
                      _ReportCard(
                        icon: Icons.qr_code_2_rounded,
                        title: 'Label Barcode',
                        desc: 'Stiker scan barcode buku',
                        color: const Color(0xFF6366F1), // Indigo
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Label Barcode Buku',
                          (s) async {
                            final books = await s.db.getAllBooks();
                            return s.generateBookBarcodes(books);
                          },
                        ),
                      ),
                      _ReportCard(
                        icon: Icons.badge_rounded,
                        title: 'Kartu Anggota',
                        desc: 'Kartu id fisik santri',
                        color: const Color(0xFF14B8A6), // Teal
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Kartu Anggota Santri',
                          (s) async {
                            final students = await s.db.getAllStudents();
                            return s.generateStudentCards(students);
                          },
                        ),
                      ),
                      _ReportCard(
                        icon: Icons.bookmark_added_rounded,
                        title: 'Label Punggung',
                        desc: 'Penempatan letak di rak',
                        color: const Color(0xFF8B5CF6), // Violet
                        dk: dk,
                        onTap: () => _generateReport(
                          context,
                          ref,
                          'Label Punggung Buku',
                          (s) async {
                            final books = await s.db.getAllBooks();
                            return s.generateSpineLabels(books);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  final bool dk;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.dk,
    required this.onTap,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.dk ? AppColors.darkCard : AppColors.lightCard;
    final bd = widget.dk ? AppColors.darkBorder : AppColors.lightBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? widget.color.withOpacity(0.5) : bd,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.dk
                        ? Colors.black.withOpacity(0.1)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            hoverColor: widget.color.withOpacity(0.03),
            splashColor: widget.color.withOpacity(0.1),
            highlightColor: widget.color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: widget.dk
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.desc,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: widget.dk
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: widget.color,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
