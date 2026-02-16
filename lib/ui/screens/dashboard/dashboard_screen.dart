import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(now),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Theme toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: AppColors.accent,
                  ),
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                  tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Stats cards
          stats.when(
            data: (data) => GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                StatCard(
                  title: 'Total Buku',
                  value: _formatNumber(data.totalBooks),
                  icon: Icons.menu_book_rounded,
                  color: AppColors.info,
                  subtitle: 'Koleksi',
                ),
                StatCard(
                  title: 'Total Santri',
                  value: _formatNumber(data.totalStudents),
                  icon: Icons.people_rounded,
                  color: AppColors.success,
                  subtitle: 'Aktif',
                ),
                StatCard(
                  title: 'Sedang Dipinjam',
                  value: _formatNumber(data.activeLoans),
                  icon: Icons.swap_horiz_rounded,
                  color: AppColors.accent,
                  subtitle: 'Buku',
                ),
                StatCard(
                  title: 'Terlambat',
                  value: _formatNumber(data.overdueLoans),
                  icon: Icons.warning_rounded,
                  color: AppColors.danger,
                  subtitle: data.overdueLoans > 0 ? '⚠ Perlu Tindakan' : 'Aman',
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const SizedBox(height: 28),

          // Recent activity and overdue books section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent loans
              Expanded(flex: 3, child: _RecentLoansCard(isDark: isDark)),
              const SizedBox(width: 16),
              // Quick actions
              Expanded(
                flex: 2,
                child: _QuickActionsCard(isDark: isDark, ref: ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }
}

class _RecentLoansCard extends ConsumerWidget {
  final bool isDark;

  const _RecentLoansCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansWithDetailsProvider(null));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aktivitas Terbaru',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          loansAsync.when(
            data: (loans) {
              if (loans.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada transaksi',
                          style: GoogleFonts.inter(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: loans.take(5).map((loan) {
                  final isOverdue =
                      loan.loanStatus == 'dipinjam' &&
                      loan.dueDate.isBefore(DateTime.now());
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              loan.loanStatus,
                              isOverdue,
                            ).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(loan.loanStatus),
                            color: _getStatusColor(loan.loanStatus, isOverdue),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.bookTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${loan.studentName} • ${loan.nis}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              loan.loanStatus,
                              isOverdue,
                            ).withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOverdue
                                ? 'Terlambat'
                                : _getStatusLabel(loan.loanStatus),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(
                                loan.loanStatus,
                                isOverdue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, bool isOverdue) {
    if (isOverdue) return AppColors.danger;
    switch (status) {
      case 'dipinjam':
        return AppColors.accent;
      case 'dikembalikan':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'dipinjam':
        return Icons.arrow_forward_rounded;
      case 'dikembalikan':
        return Icons.check_circle_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'dipinjam':
        return 'Dipinjam';
      case 'dikembalikan':
        return 'Dikembalikan';
      default:
        return status;
    }
  }
}

class _QuickActionsCard extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;

  const _QuickActionsCard({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aksi Cepat',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _QuickActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Tambah Buku Baru',
            color: AppColors.info,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(1),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.person_add_outlined,
            label: 'Tambah Santri Baru',
            color: AppColors.success,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(2),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Peminjaman Baru',
            color: AppColors.accent,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(3),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.assignment_return_rounded,
            label: 'Pengembalian Buku',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(4),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
