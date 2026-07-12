import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../widgets/stat_card.dart';
import 'category_manager_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasShownStartupAlert = false;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
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
              // Notifications
              notificationsAsync.when(
                data: (notif) {
                  if (notif.total > 0 && !_hasShownStartupAlert) {
                    _hasShownStartupAlert = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showNotificationDialog(context, notif);
                    });
                  }
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_active_rounded,
                            color: notif.total > 0 ? AppColors.warning : AppColors.accent,
                          ),
                          onPressed: () {
                            if (notif.total > 0) {
                              _showNotificationDialog(context, notif);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tidak ada notifikasi baru.')),
                              );
                            }
                          },
                          tooltip: 'Notifikasi',
                        ),
                      ),
                      if (notif.total > 0)
                        Positioned(
                          right: 12,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              notif.total.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox(width: 48),
                error: (_, __) => const SizedBox(width: 48),
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

  void _showNotificationDialog(BuildContext context, NotificationsState notif) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text('Notifikasi Penting'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notif.overdueLoans.isNotEmpty) ...[
                  Text(
                    'Peminjaman Terlambat (${notif.overdueLoans.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                  ),
                  const SizedBox(height: 8),
                  ...notif.overdueLoans.take(5).map((l) => Text('- ${l.bookTitle} (oleh ${l.studentName})')),
                  if (notif.overdueLoans.length > 5) const Text('... dan lainnya'),
                  const SizedBox(height: 16),
                ],
                if (notif.pendingReservations.isNotEmpty) ...[
                  Text(
                    'Reservasi Menunggu (${notif.pendingReservations.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.info),
                  ),
                  const SizedBox(height: 8),
                  ...notif.pendingReservations.take(5).map((r) => Text('- ${r.book.title} (oleh ${r.student.name})')),
                  if (notif.pendingReservations.length > 5) const Text('... dan lainnya'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
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
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
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
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
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
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.person_add_outlined,
            label: 'Tambah Santri Baru',
            color: AppColors.success,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(2),
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.assignment_ind_rounded,
            label: 'Presensi / Buku Tamu',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(3),
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.category_rounded,
            label: 'Kelola Kategori Buku',
            color: AppColors.accent,
            isDark: isDark,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const CategoryManagerDialog(),
              );
            },
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Peminjaman Baru',
            color: AppColors.warning,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(4),
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.assignment_return_rounded,
            label: 'Pengembalian Buku',
            color: AppColors.success,
            isDark: isDark,
            onTap: () => ref.read(selectedNavIndexProvider.notifier).select(5),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
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
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_isHovered ? 6 : 0, 0, 0),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isHovered
                      ? widget.color.withOpacity(0.4)
                      : (widget.isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  width: 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(2, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isHovered
                            ? widget.color
                            : (widget.isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _isHovered
                        ? widget.color
                        : (widget.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
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
