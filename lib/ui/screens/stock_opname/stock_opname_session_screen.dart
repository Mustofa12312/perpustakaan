import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class StockOpnameSessionScreen extends ConsumerStatefulWidget {
  final int opnameId;
  const StockOpnameSessionScreen({super.key, required this.opnameId});

  @override
  ConsumerState<StockOpnameSessionScreen> createState() => _StockOpnameSessionScreenState();
}

class _StockOpnameSessionScreenState extends ConsumerState<StockOpnameSessionScreen> {
  final _barcodeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  
  StockOpname? _session;
  List<StockOpnameItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    
    // We need getStockOpnameById, but we can just filter getAllStockOpnames for now if not implemented.
    final sessions = await db.getAllStockOpnames();
    try {
      _session = sessions.firstWhere((s) => s.id == widget.opnameId);
    } catch (_) {
      _session = null;
    }

    if (_session != null) {
      _items = await db.getStockOpnameItems(widget.opnameId);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleBarcodeScan(String code) async {
    if (code.isEmpty || _session == null) return;
    
    final db = ref.read(databaseProvider);
    final books = await db.getAllBooks();
    Book? book;
    try {
      book = books.firstWhere((b) => b.code == code || b.title.contains(code));
    } catch (_) {}

    if (book == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buku tidak ditemukan!'), backgroundColor: AppColors.danger),
        );
      }
      _barcodeCtrl.clear();
      _focusNode.requestFocus();
      return;
    }

    // Check if item already exists in this session
    StockOpnameItem? existingItem;
    try {
      existingItem = _items.firstWhere((i) => i.bookId == book!.id);
    } catch (_) {}

    if (existingItem != null) {
      await db.updateStockOpnameItem(
        existingItem.copyWith(actualQty: existingItem.actualQty + 1),
      );
    } else {
      await db.insertStockOpnameItem(
        StockOpnameItemsCompanion.insert(
          opnameId: widget.opnameId,
          bookId: book.id,
          systemQty: book.totalQty,
          actualQty: 1,
        ),
      );
    }

    _barcodeCtrl.clear();
    _focusNode.requestFocus();
    await _loadData();
  }

  Future<void> _completeSession() async {
    if (_session == null) return;
    final db = ref.read(databaseProvider);
    await db.updateStockOpname(_session!.copyWith(
      status: 'selesai',
      endDate: drift.Value(DateTime.now()),
    ));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return const Scaffold(body: Center(child: Text('Sesi tidak ditemukan.')));
    }

    final isCompleted = _session!.status == 'selesai';

    return Scaffold(
      appBar: AppBar(
        title: Text(_session!.title),
        actions: [
          if (!isCompleted)
            ElevatedButton.icon(
              onPressed: _completeSession,
              icon: const Icon(Icons.check_circle),
              label: const Text('Selesaikan Audit'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!isCompleted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 32, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _barcodeCtrl,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Scan Barcode atau masukkan Kode Buku / Judul lalu tekan Enter',
                          border: InputBorder.none,
                        ),
                        onSubmitted: _handleBarcodeScan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: _items.isEmpty
                    ? const Center(child: Text('Belum ada buku yang di-scan.'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final item = _items[i];
                          // In a real app we'd join with the Books table to get the title.
                          // For simplicity, we just show IDs or you can fetch it if needed.
                          // Here, since we have the DB, we can load book info per item.
                          // But to keep it simple, let's just display the difference.
                          final diff = item.actualQty - item.systemQty;
                          final diffColor = diff == 0
                              ? AppColors.success
                              : diff < 0
                                  ? AppColors.danger
                                  : AppColors.warning;

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.book),
                            ),
                            title: Text('Book ID: ${item.bookId}'),
                            subtitle: Text('Sistem: ${item.systemQty} | Aktual: ${item.actualQty}'),
                            trailing: Text(
                              diff == 0 ? 'Sesuai' : (diff > 0 ? '+$diff' : '$diff'),
                              style: TextStyle(
                                color: diffColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
