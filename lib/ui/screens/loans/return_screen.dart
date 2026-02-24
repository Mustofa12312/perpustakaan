import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class ReturnScreen extends ConsumerStatefulWidget {
  const ReturnScreen({super.key});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c1 = dk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = dk ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final loansAsync = ref.watch(loansWithDetailsProvider('dipinjam'));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengembalian Buku',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: c1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola pengembalian aset dan denda keterlambatan dengan mudah',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: c2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: dk ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dk ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: IconButton(
                  onPressed: () =>
                      ref.invalidate(loansWithDetailsProvider('dipinjam')),
                  icon: Icon(Icons.refresh_rounded, color: c1),
                  tooltip: 'Muat Ulang',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            autofocus: true,
            controller: _searchController,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: dk
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Cari Santri (Nama/NIS) atau Judul/Kode Buku...',
              hintStyle: GoogleFonts.inter(
                color: c2.withAlpha(150),
                fontSize: 15,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: c2),
              filled: true,
              fillColor: dk
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9), // Slate 800 or Slate 100
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors
                    .transparent, // Background transparent inside expanded, handled by items
              ),
              child: loansAsync.when(
                data: (loans) {
                  final filtered = loans.where((l) {
                    if (_query.isEmpty) return true;
                    return l.studentName.toLowerCase().contains(_query) ||
                        l.bookTitle.toLowerCase().contains(_query) ||
                        l.nis.toLowerCase().contains(_query) ||
                        l.bookCode.toLowerCase().contains(_query);
                  }).toList();

                  if (filtered.isEmpty) {
                    if (loans.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 64,
                              color: c2,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada buku yang sedang dipinjam',
                              style: GoogleFonts.inter(fontSize: 16, color: c2),
                            ),
                          ],
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        'Tidak ditemukan data untuk "$_query"',
                        style: GoogleFonts.inter(fontSize: 14, color: c2),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final l = filtered[i];
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final due = DateTime(
                        l.dueDate.year,
                        l.dueDate.month,
                        l.dueDate.day,
                      );
                      final daysLate = today.difference(due).inDays;
                      final late = daysLate > 0;
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: dk ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dk
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(dk ? 20 : 5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Peminjam Info
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary
                                        .withAlpha(dk ? 40 : 25),
                                    child: Text(
                                      l.studentName.isNotEmpty
                                          ? l.studentName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : '?',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PEMINJAM:',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: c2,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l.studentName,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: c1,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'NIS: ${l.nis}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: c2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Divider
                            Container(
                              width: 1,
                              height: 50,
                              color: dk ? Colors.white12 : Colors.black12,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            // Book Info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        late
                                            ? Icons.warning_rounded
                                            : Icons.menu_book_rounded,
                                        color: late
                                            ? AppColors.danger
                                            : AppColors.accent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l.bookTitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: c1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _Tag(
                                        'Pinjam: ${DateFormat('dd MMM yyyy, HH:mm').format(l.loanDate.toLocal())}',
                                        AppColors.info,
                                        dk,
                                      ),
                                      _Tag(
                                        'Tenggat: ${DateFormat('dd MMM yyyy, HH:mm').format(l.dueDate.toLocal())}',
                                        late
                                            ? AppColors.danger
                                            : AppColors.success,
                                        dk,
                                      ),
                                      if (late)
                                        _Tag(
                                          'Terlambat $daysLate Hari',
                                          AppColors.danger,
                                          dk,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.danger.withAlpha(
                                      20,
                                    ),
                                    foregroundColor: AppColors.danger,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Hilang',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () => _confirmLost(ctx, ref, l),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.assignment_return_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Kembalikan',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _confirmReturn(ctx, ref, l, daysLate),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReturn(
    BuildContext ctx,
    WidgetRef ref,
    LoanWithDetails loan,
    int daysLate,
  ) async {
    final db = ref.read(databaseProvider);
    final sMap = await db.getAllSettings();
    final finePerDay = int.tryParse(sMap['fine_per_day'] ?? '500') ?? 500;
    final totalFine = daysLate * finePerDay;

    if (!ctx.mounted) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Konfirmasi Pengembalian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buku: ${loan.bookTitle}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            Text('Santri: ${loan.studentName}'),
            if (daysLate > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠ Terlambat $daysLate hari',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    Text(
                      'Denda: Rp ${NumberFormat('#,###').format(totalFine)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await db.returnBook(loan.loanId, finePerDay);
      ref.invalidate(loansWithDetailsProvider('dipinjam'));
      ref.invalidate(loansWithDetailsProvider(null));
      ref.invalidate(booksProvider);
      ref.invalidate(activeLoansProvider);
      ref.invalidate(dashboardStatsProvider);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              daysLate > 0
                  ? 'Dikembalikan. Denda: Rp ${NumberFormat('#,###').format(totalFine)}'
                  : 'Buku berhasil dikembalikan!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmLost(
    BuildContext ctx,
    WidgetRef ref,
    LoanWithDetails loan,
  ) async {
    final db = ref.read(databaseProvider);
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: '0');

    if (!ctx.mounted) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Buku Hilang / Rusak'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buku: ${loan.bookTitle}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              Text('Santri: ${loan.studentName}'),
              const SizedBox(height: 12),
              Text(
                'Masukan denda penggantian buku (Rp):',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(value) == null) return 'Harus angka';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(c, true);
              }
            },
            child: const Text('Proses Hilang'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final lostFine = int.parse(amountController.text);
      await db.returnBook(loan.loanId, 0, isLost: true, lostFine: lostFine);
      ref.invalidate(loansWithDetailsProvider('dipinjam'));
      ref.invalidate(loansWithDetailsProvider(null));
      ref.invalidate(booksProvider);
      ref.invalidate(activeLoansProvider);
      ref.invalidate(dashboardStatsProvider);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              'Buku ditandai hilang. Denda penggantian: Rp ${NumberFormat('#,###').format(lostFine)}',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _Tag extends StatelessWidget {
  final String t;
  final Color c;
  final bool dk;
  const _Tag(this.t, this.c, this.dk);
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withAlpha(20),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      t,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: c,
      ),
    ),
  );
}
