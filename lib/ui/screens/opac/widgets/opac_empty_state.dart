import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class OpacEmptyState extends StatelessWidget {
  final bool hasSearched;
  final bool isDark;

  const OpacEmptyState({
    super.key,
    required this.hasSearched,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasSearched) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 80,
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(20),
              ),
              const SizedBox(height: 24),
              Text(
                'Mulai Eksplorasi',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ketik kata kunci di atas untuk mencari buku di OPAC.',
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

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(20),
            ),
            const SizedBox(height: 24),
            Text(
              'Buku Tidak Ditemukan',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba gunakan kata kunci lain atau periksa ejaan Anda.',
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
}
