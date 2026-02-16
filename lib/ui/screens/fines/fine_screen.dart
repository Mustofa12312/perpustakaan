import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class FineScreen extends ConsumerWidget {
  const FineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c1 = dk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = dk ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final loansAsync = ref.watch(loansWithDetailsProvider(null));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Denda',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daftar denda keterlambatan',
            style: GoogleFonts.inter(fontSize: 14, color: c2),
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
                  final fined = loans
                      .where((l) => l.fineAmount != null && l.fineAmount! > 0)
                      .toList();
                  if (fined.isEmpty)
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
                            'Belum ada denda',
                            style: GoogleFonts.inter(fontSize: 16, color: c2),
                          ),
                        ],
                      ),
                    );
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.builder(
                      itemCount: fined.length,
                      itemBuilder: (ctx, i) {
                        final f = fined[i];
                        final paid = f.isPaid ?? false;
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
                                      (paid
                                              ? AppColors.success
                                              : AppColors.danger)
                                          .withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  paid
                                      ? Icons.check_circle_rounded
                                      : Icons.monetization_on_rounded,
                                  color: paid
                                      ? AppColors.success
                                      : AppColors.danger,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.studentName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c1,
                                      ),
                                    ),
                                    Text(
                                      '${f.bookTitle} • ${f.daysLate} hari terlambat',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: c2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${NumberFormat('#,###').format(f.fineAmount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: paid
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (paid
                                              ? AppColors.success
                                              : AppColors.warning)
                                          .withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  paid ? 'Lunas' : 'Belum Lunas',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: paid
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ),
                              if (!paid) ...[
                                const SizedBox(width: 8),
                                IconButton(
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
                              ],
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
}
