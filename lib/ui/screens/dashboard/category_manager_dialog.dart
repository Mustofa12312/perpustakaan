import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class CategoryManagerDialog extends ConsumerStatefulWidget {
  const CategoryManagerDialog({super.key});

  @override
  ConsumerState<CategoryManagerDialog> createState() =>
      _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends ConsumerState<CategoryManagerDialog> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addCategory(List<String> currentCategories) async {
    final val = _addController.text.trim();
    if (val.isEmpty) return;
    if (currentCategories.any((e) => e.toLowerCase() == val.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kategori "$val" sudah ada'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final newCats = List<String>.from(currentCategories)..add(val);
    newCats.sort();

    final db = ref.read(databaseProvider);
    await db.setSetting('book_categories', jsonEncode(newCats));
    ref.invalidate(categoriesProvider);
    _addController.clear();
  }

  Future<void> _deleteCategory(
    List<String> currentCategories,
    String cat,
  ) async {
    final db = ref.read(databaseProvider);
    final isUsed = await db.isCategoryUsed(cat);

    if (isUsed) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Gagal Menghapus'),
            content: Text(
              'Kategori "$cat" masih digunakan oleh buku. Ubah kategori buku tersebut terlebih dahulu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus kategori "$cat"?'),
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
      final newCats = currentCategories.where((e) => e != cat).toList();
      final db = ref.read(databaseProvider);
      await db.setSetting('book_categories', jsonEncode(newCats));
      ref.invalidate(categoriesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kelola Kategori',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            categoriesAsync.when(
              data: (categories) => Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addController,
                            decoration: const InputDecoration(
                              hintText: 'Tambah kategori baru...',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addCategory(categories),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _addCategory(categories),
                          child: const Text('Tambah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: ListView.separated(
                          itemCount: categories.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                color: AppColors.danger,
                                onPressed: () =>
                                    _deleteCategory(categories, cat),
                                tooltip: 'Hapus kategori',
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  Expanded(child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ),
    );
  }
}
