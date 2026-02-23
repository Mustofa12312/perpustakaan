import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';
import '../../widgets/csv_import_dialog.dart';

class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booksAsync = ref.watch(
      booksFilterProvider((query: _searchQuery, category: _selectedCategory)),
    );

    final baseCats = ref.watch(categoriesProvider).value ?? [];
    final _categories = ['Semua', ...baseCats];
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }

    return Padding(
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
                      'Data Buku',
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
                      'Kelola koleksi buku perpustakaan',
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
              OutlinedButton.icon(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  final imported = await showDialog<bool>(
                    context: context,
                    builder: (_) => CsvImportDialog(
                      importType: ImportType.books,
                      database: db,
                    ),
                  );
                  if (imported == true) {
                    ref.invalidate(booksProvider);
                  }
                },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Import CSV'),
              ),
              const SizedBox(width: 10),
              // Delete all button
              if (ref.watch(authProvider).currentUser?.role == 'admin')
                OutlinedButton.icon(
                  onPressed: () => _deleteAllBooks(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('Hapus Semua'),
                ),
              if (ref.watch(authProvider).currentUser?.role == 'admin')
                const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showBookForm(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Tambah Buku'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and filter
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari judul, pengarang, atau kode buku...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value ?? 'Semua'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: booksAsync.when(
                data: (books) {
                  final filtered = books;

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 64,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada data buku',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Klik "Tambah Buku" untuk menambahkan',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final book = filtered[index];
                        return _BookListItem(
                          book: book,
                          isDark: isDark,
                          onEdit: () => _showBookForm(context, book: book),
                          onDelete: () => _deleteBook(book),
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

  void _showBookForm(BuildContext context, {Book? book}) {
    showDialog(
      context: context,
      builder: (context) => _BookFormDialog(book: book),
    );
  }

  Future<void> _deleteBook(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Yakin ingin menghapus "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(databaseProvider).deleteBook(book.id);
      ref.invalidate(booksProvider);
      ref.invalidate(dashboardStatsProvider);
    }
  }

  Future<void> _deleteAllBooks(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus SEMUA Buku?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tindakan ini tidak dapat dibatalkan! Semua data buku akan hilang permanen.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YA, HAPUS SEMUA'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(databaseProvider).deleteAllBooks();
      ref.invalidate(booksProvider);
      ref.invalidate(dashboardStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua data buku berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

class _BookListItem extends StatelessWidget {
  final Book book;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookListItem({
    required this.book,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withAlpha(100)
                : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Book code badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                book.code.length > 4 ? book.code.substring(0, 4) : book.code,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title & author
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
                  book.author,
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
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              book.category,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Availability
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  '${book.availableQty}/${book.totalQty}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: book.availableQty > 0
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
                Text(
                  'Tersedia',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.info,
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.danger,
            onPressed: onDelete,
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }
}

class _BookFormDialog extends ConsumerStatefulWidget {
  final Book? book;

  const _BookFormDialog({this.book});

  @override
  ConsumerState<_BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<_BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeC;
  late final TextEditingController _titleC;
  late final TextEditingController _authorC;
  late final TextEditingController _publisherC;
  late final TextEditingController _yearC;
  late final TextEditingController _qtyC;
  late final TextEditingController _shelfC;
  String _category = 'Umum';

  @override
  void initState() {
    super.initState();
    _codeC = TextEditingController(text: widget.book?.code ?? '');
    _titleC = TextEditingController(text: widget.book?.title ?? '');
    _authorC = TextEditingController(text: widget.book?.author ?? '');
    _publisherC = TextEditingController(text: widget.book?.publisher ?? '');
    _yearC = TextEditingController(text: widget.book?.year.toString() ?? '');
    _qtyC = TextEditingController(
      text: widget.book?.totalQty.toString() ?? '1',
    );
    _shelfC = TextEditingController(text: widget.book?.shelfLocation ?? '');
    _category = widget.book?.category ?? 'Umum';
  }

  @override
  void dispose() {
    _codeC.dispose();
    _titleC.dispose();
    _authorC.dispose();
    _publisherC.dispose();
    _yearC.dispose();
    _qtyC.dispose();
    _shelfC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _categories = List<String>.from(
      ref.watch(categoriesProvider).value ?? [],
    );

    if (_categories.isNotEmpty && !_categories.contains(_category)) {
      _categories.add(_category);
    }

    return Dialog(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Buku' : 'Tambah Buku Baru',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        'Kode Buku *',
                        _codeC,
                        'Contoh: FQ001',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          labelStyle: GoogleFonts.inter(fontSize: 13),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _category = v ?? 'Umum'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Judul Buku *', _titleC, 'Masukkan judul buku'),
                const SizedBox(height: 16),
                _buildField('Pengarang *', _authorC, 'Masukkan nama pengarang'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        'Penerbit',
                        _publisherC,
                        'Nama penerbit',
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: _buildField(
                        'Tahun',
                        _yearC,
                        '2024',
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: _buildField('Jumlah', _qtyC, '1', isNumber: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        'Lokasi Rak',
                        _shelfC,
                        'Contoh: Rak A-3',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Buku'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13),
        hintText: hint,
      ),
      validator: label.contains('*')
          ? (v) => v?.isEmpty == true ? 'Wajib diisi' : null
          : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final qty = int.tryParse(_qtyC.text) ?? 1;

    if (widget.book != null) {
      final diff = qty - widget.book!.totalQty;
      final newAvailable = widget.book!.availableQty + diff;

      if (newAvailable < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Total buku tidak boleh lebih kecil dari buku yang sedang dipinjam.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final updated = widget.book!.copyWith(
        code: _codeC.text.trim(),
        title: _titleC.text.trim(),
        author: _authorC.text.trim(),
        publisher: _publisherC.text.trim(),
        year: int.tryParse(_yearC.text) ?? 0,
        category: _category,
        totalQty: qty,
        availableQty: newAvailable,
        shelfLocation: _shelfC.text.trim(),
      );
      await db.updateBook(updated);
    } else {
      await db.insertBook(
        BooksCompanion.insert(
          code: _codeC.text.trim(),
          title: _titleC.text.trim(),
          author: _authorC.text.trim(),
          publisher: drift.Value(_publisherC.text.trim()),
          year: drift.Value(int.tryParse(_yearC.text) ?? 0),
          category: drift.Value(_category),
          totalQty: drift.Value(qty),
          availableQty: drift.Value(qty),
          shelfLocation: drift.Value(_shelfC.text.trim()),
        ),
      );
    }

    ref.invalidate(booksProvider);
    ref.invalidate(dashboardStatsProvider);
    if (mounted) Navigator.pop(context);
  }
}
