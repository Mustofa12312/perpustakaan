import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c1 = dk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = dk ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = dk ? AppColors.darkSurface : AppColors.lightSurface;
    final bd = dk ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate dan cetak laporan perpustakaan',
            style: GoogleFonts.inter(fontSize: 14, color: c2),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _ReportCard(
                  icon: Icons.list_alt_rounded,
                  title: 'Daftar Buku',
                  desc: 'Semua koleksi buku',
                  color: AppColors.info,
                  bg: bg,
                  bd: bd,
                  dk: dk,
                  onTap: () => _showComingSoon(context),
                ),
                _ReportCard(
                  icon: Icons.people_rounded,
                  title: 'Daftar Santri',
                  desc: 'Semua data santri aktif',
                  color: AppColors.success,
                  bg: bg,
                  bd: bd,
                  dk: dk,
                  onTap: () => _showComingSoon(context),
                ),
                _ReportCard(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Peminjaman',
                  desc: 'Laporan peminjaman buku',
                  color: AppColors.accent,
                  bg: bg,
                  bd: bd,
                  dk: dk,
                  onTap: () => _showComingSoon(context),
                ),
                _ReportCard(
                  icon: Icons.warning_rounded,
                  title: 'Keterlambatan',
                  desc: 'Buku yang terlambat dikembalikan',
                  color: AppColors.danger,
                  bg: bg,
                  bd: bd,
                  dk: dk,
                  onTap: () => _showComingSoon(context),
                ),
                _ReportCard(
                  icon: Icons.monetization_on_rounded,
                  title: 'Denda',
                  desc: 'Rekap denda santri',
                  color: AppColors.warning,
                  bg: bg,
                  bd: bd,
                  dk: dk,
                  onTap: () => _showComingSoon(context),
                ),
                _ReportCard(
                  icon: Icons.analytics_rounded,
                  title: 'Statistik',
                  desc: 'Statistik peminjaman bulanan',
                  color: AppColors.primary,
                  bg: bg,
                  bd: bd,
                  dk: dk,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Fitur cetak PDF akan tersedia di Phase 2'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color color, bg, bd;
  final bool dk;
  final VoidCallback onTap;
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.bg,
    required this.bd,
    required this.dk,
    required this.onTap,
  });
  @override
  Widget build(BuildContext ctx) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: dk
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: dk
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
