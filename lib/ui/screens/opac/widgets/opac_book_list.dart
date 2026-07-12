import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';

class OpacBookList extends StatelessWidget {
  final List<Book> results;

  const OpacBookList({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final b = results[index];
        final isAvailable = b.availableQty > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Icon/Cover Placeholder
              Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(5)
                      : Colors.black.withAlpha(5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.book_rounded,
                    size: 48,
                    color: isDark
                        ? Colors.white.withAlpha(50)
                        : Colors.black.withAlpha(50),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b.title,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (isAvailable
                                      ? AppColors.success
                                      : AppColors.danger)
                                  .withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (isAvailable
                                        ? AppColors.success
                                        : AppColors.danger)
                                    .withAlpha(50),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAvailable
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAvailable ? 'Tersedia' : 'Masih Dipinjam',
                                  style: GoogleFonts.inter(
                                    color: isAvailable
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Oleh ${b.author}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.domain_rounded,
                            '${b.publisher} (${b.year})',
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.bookmark_border_rounded,
                            'Kls: ${b.code}',
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.shelves,
                            'Rak: ${b.shelfLocation}',
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Stok Aktual: ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${b.availableQty} dari ${b.totalQty} buku',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }, childCount: results.length),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
