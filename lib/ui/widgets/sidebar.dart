import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final settings = ref.watch(settingsProvider).value ?? {};
    final libName = settings['library_name'] ?? 'Perpustakaan Pondok Pesantren';
    final nameParts = libName.toString().split(' ');
    final firstName = nameParts.first;
    final secondName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_library_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (secondName.isNotEmpty)
                        Text(
                          secondName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _NavSection(label: 'MENU UTAMA', isDark: isDark),
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(0),
                ),
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Data Buku',
                  index: 1,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(1),
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Data Santri',
                  index: 2,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(2),
                ),
                _NavItem(
                  icon: Icons.assignment_ind_rounded,
                  label: 'Presensi / Tamu',
                  index: 3,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(3),
                ),
                const SizedBox(height: 8),
                _NavSection(label: 'TRANSAKSI', isDark: isDark),
                _NavItem(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Peminjaman',
                  index: 4,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(4),
                ),
                _NavItem(
                  icon: Icons.assignment_return_rounded,
                  label: 'Pengembalian',
                  index: 5,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(5),
                ),
                _NavItem(
                  icon: Icons.monetization_on_rounded,
                  label: 'Denda',
                  index: 6,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(6),
                ),
                const SizedBox(height: 8),
                _NavSection(label: 'LAINNYA', isDark: isDark),
                _NavItem(
                  icon: Icons.assessment_rounded,
                  label: 'Laporan',
                  index: 7,
                  selectedIndex: selectedIndex,
                  onTap: () =>
                      ref.read(selectedNavIndexProvider.notifier).select(7),
                ),
                if (authState.currentUser?.role == 'admin')
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Pengaturan',
                    index: 8,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedNavIndexProvider.notifier).select(8),
                  ),
              ],
            ),
          ),

          // User info & logout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withAlpha(30),
                  child: Text(
                    (authState.currentUser?.fullName ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.currentUser?.fullName ?? 'User',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authState.currentUser?.role.toUpperCase() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  tooltip: 'Keluar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String label;
  final bool isDark;

  const _NavSection({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? AppColors.primary.withAlpha(20)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
