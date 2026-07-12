import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';
import 'stock_opname_session_screen.dart';

class StockOpnameScreen extends ConsumerStatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  ConsumerState<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends ConsumerState<StockOpnameScreen> {
  List<StockOpname> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final sessions = await db.getAllStockOpnames();
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _createNewSession() async {
    final titleCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai Stock Opname Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Sesi',
                hintText: 'Contoh: Opname Semester Ganjil 2026',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );

    if (confirm == true && titleCtrl.text.isNotEmpty) {
      final db = ref.read(databaseProvider);
      final id = await db.insertStockOpname(
        StockOpnamesCompanion.insert(
          title: titleCtrl.text,
          status: const drift.Value('berlangsung'),
        ),
      );
      _loadSessions();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockOpnameSessionScreen(opnameId: id),
          ),
        ).then((_) => _loadSessions());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Opname',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Audit dan penyesuaian stok buku perpustakaan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _createNewSession,
                icon: const Icon(Icons.add_task_rounded, size: 20),
                label: const Text('Mulai Sesi Baru'),
              ),
            ],
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
                  : _sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_rounded,
                                size: 64,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada sesi stock opname',
                                style: GoogleFonts.inter(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _sessions.length,
                          itemBuilder: (ctx, i) {
                            final session = _sessions[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: session.status == 'berlangsung'
                                    ? AppColors.warning.withAlpha(50)
                                    : AppColors.success.withAlpha(50),
                                child: Icon(
                                  session.status == 'berlangsung'
                                      ? Icons.sync_rounded
                                      : Icons.check_circle_rounded,
                                  color: session.status == 'berlangsung' ? AppColors.warning : AppColors.success,
                                ),
                              ),
                              title: Text(session.title),
                              subtitle: Text(
                                'Dimulai: ${session.startDate.toLocal().toString().split('.')[0]}\nStatus: ${session.status.toUpperCase()}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StockOpnameSessionScreen(opnameId: session.id),
                                  ),
                                ).then((_) => _loadSessions());
                              },
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
