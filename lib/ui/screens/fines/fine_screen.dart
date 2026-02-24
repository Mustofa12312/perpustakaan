import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class FineScreen extends ConsumerStatefulWidget {
  const FineScreen({super.key});

  @override
  ConsumerState<FineScreen> createState() => _FineScreenState();
}

class _FineScreenState extends ConsumerState<FineScreen> {
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
    final loansAsync = ref.watch(loansWithDetailsProvider(null));

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
                    'Data Denda',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: c1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola daftar denda keterlambatan dan status pembayaran',
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
                      ref.invalidate(loansWithDetailsProvider(null)),
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
              hintText: 'Cari Santri (Nama/NIS)...',
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
              decoration: BoxDecoration(color: Colors.transparent),
              child: loansAsync.when(
                data: (loans) {
                  final fined = loans.where((l) {
                    final hasFine = l.fineAmount != null && l.fineAmount! > 0;
                    if (!hasFine) return false;

                    if (_query.isEmpty) return true;
                    return l.studentName.toLowerCase().contains(_query) ||
                        l.nis.toLowerCase().contains(_query);
                  }).toList();

                  if (fined.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_satisfied_rounded,
                            size: 64,
                            color: c2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _query.isEmpty
                                ? 'Belum ada denda'
                                : 'Tidak ditemukan denda untuk "$_query"',
                            style: GoogleFonts.inter(fontSize: 16, color: c2),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: fined.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final f = fined[i];
                      final paid = f.isPaid ?? false;
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
                                    radius: 20,
                                    backgroundColor:
                                        (paid
                                                ? AppColors.success
                                                : AppColors.danger)
                                            .withAlpha(dk ? 40 : 25),
                                    child: Text(
                                      f.studentName.isNotEmpty
                                          ? f.studentName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : '?',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: paid
                                            ? AppColors.success
                                            : AppColors.danger,
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
                                          f.studentName,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: c1,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'NIS: ${f.nis}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
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
                              height: 40,
                              color: dk ? Colors.white12 : Colors.black12,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            // Detail Info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.bookTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Denda Keterlambatan: ${f.daysLate} hari',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: c2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tenggat: ${DateFormat('dd MMM yyyy, HH:mm').format(f.dueDate)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Nominal & Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp ${NumberFormat('#,###').format(f.fineAmount)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: paid
                                        ? AppColors.success
                                        : AppColors.danger,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (paid
                                                ? AppColors.success
                                                : AppColors.warning)
                                            .withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    paid ? 'LUNAS' : 'BELUM LUNAS',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: paid
                                          ? AppColors.success
                                          : AppColors.warning,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!paid) ...[
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                  ),
                                  color: AppColors.success,
                                  tooltip: 'Tandai Lunas',
                                  onPressed: () async {
                                    final db = ref.read(databaseProvider);
                                    if (f.fineId != null) {
                                      final fine = await db.getFineByLoanId(
                                        f.loanId,
                                      );
                                      if (fine != null) {
                                        await db.updateFine(
                                          fine.copyWith(isPaid: true),
                                        );
                                        ref.invalidate(
                                          loansWithDetailsProvider(null),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
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
}
