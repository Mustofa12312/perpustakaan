import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  List<ReservationWithDetails> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final res = await db.getActiveReservations();
    setState(() {
      _reservations = res;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(Reservation res, String newStatus) async {
    final db = ref.read(databaseProvider);
    await db.updateReservation(res.copyWith(status: newStatus));
    _loadReservations();
  }

  Future<void> _deleteReservation(Reservation res) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Reservasi'),
        content: const Text('Yakin ingin menghapus reservasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.deleteReservation(res.id);
      _loadReservations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = ref.watch(authProvider).currentUser?.role == 'admin';

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Reservasi',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola antrean reservasi buku yang sedang kosong',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reservations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_border_rounded,
                                size: 64,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada reservasi aktif',
                                style: GoogleFonts.inter(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _reservations.length,
                          itemBuilder: (ctx, i) {
                            final item = _reservations[i];
                            final r = item.reservation;
                            final b = item.book;
                            final s = item.student;
                            
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.info,
                                child: Icon(Icons.bookmark, color: Colors.white),
                              ),
                              title: Text('${b.title} - ${b.code}'),
                              subtitle: Text('Pemesan: ${s.name} (${s.nis})\nTanggal: ${r.reservationDate.toLocal().toString().split('.')[0]}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (b.availableQty > 0)
                                    ElevatedButton(
                                      onPressed: () => _updateStatus(r, 'selesai'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                      child: const Text('Buku Tersedia'),
                                    ),
                                  const SizedBox(width: 8),
                                  if (isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.danger),
                                      onPressed: () => _deleteReservation(r),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
