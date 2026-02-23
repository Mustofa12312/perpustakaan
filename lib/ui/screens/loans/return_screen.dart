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
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: c1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proses pengembalian dan hitung denda otomatis',
                    style: GoogleFonts.inter(fontSize: 14, color: c2),
                  ),
                ],
              ),
              IconButton(
                onPressed: () =>
                    ref.invalidate(loansWithDetailsProvider('dipinjam')),
                icon: Icon(Icons.refresh, color: c2),
                tooltip: 'Muat Ulang',
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            autofocus: true,
            controller: _searchController,
            style: GoogleFonts.inter(color: c1),
            decoration: InputDecoration(
              hintText: 'Cari Santri (Nama/NIS) atau Judul Buku...',
              hintStyle: GoogleFonts.inter(color: c2),
              prefixIcon: Icon(Icons.search, color: c2),
              filled: true,
              fillColor: dk ? AppColors.darkSurface : AppColors.lightSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dk ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dk ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: dk ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dk ? AppColors.darkBorder : AppColors.lightBorder,
                ),
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

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.builder(
                      itemCount: filtered.length,
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: dk
                                    ? AppColors.darkBorder.withAlpha(100)
                                    : AppColors.lightBorder,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      (late
                                              ? AppColors.danger
                                              : AppColors.accent)
                                          .withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  late
                                      ? Icons.warning_rounded
                                      : Icons.menu_book_rounded,
                                  color: late
                                      ? AppColors.danger
                                      : AppColors.accent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.bookTitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l.studentName} • ${l.nis}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: c2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _Tag(
                                          'Pinjam: ${DateFormat('dd/MM').format(l.loanDate)}',
                                          AppColors.info,
                                          dk,
                                        ),
                                        const SizedBox(width: 6),
                                        _Tag(
                                          'Batas: ${DateFormat('dd/MM').format(l.dueDate)}',
                                          late
                                              ? AppColors.danger
                                              : AppColors.success,
                                          dk,
                                        ),
                                        if (late) ...[
                                          const SizedBox(width: 6),
                                          _Tag(
                                            'Terlambat $daysLate hari',
                                            AppColors.danger,
                                            dk,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.danger,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.not_interested_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Hilang',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () => _confirmLost(ctx, ref, l),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.assignment_return_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Kembalikan',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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
                    ),
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
