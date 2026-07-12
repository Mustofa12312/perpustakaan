import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import 'widgets/opac_hero_section.dart';
import 'widgets/opac_book_list.dart';
import 'widgets/opac_empty_state.dart';

class OpacScreen extends ConsumerStatefulWidget {
  const OpacScreen({super.key});

  @override
  ConsumerState<OpacScreen> createState() => _OpacScreenState();
}

class _OpacScreenState extends ConsumerState<OpacScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Book> _results = [];
  bool _hasSearched = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final db = ref.read(databaseProvider);
    final res = await db.searchBooks(q);

    setState(() {
      _results = res;
      _isLoading = false;
      _hasSearched = true;
    });
  }

  Future<void> _promptExitOpac() async {
    final pwdCtrl = TextEditingController();
    bool isError = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> checkPwd() async {
              final db = ref.read(databaseProvider);
              final users = await db.getAllUsers();
              bool isValid = false;
              for (final u in users) {
                if (u.role == 'admin' || u.role == 'Admin') {
                  final auth = await db.authenticateUser(
                    u.username,
                    pwdCtrl.text,
                  );
                  if (auth != null) {
                    isValid = true;
                    break;
                  }
                }
              }

              if (isValid) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) Navigator.pop(context);
              } else {
                setState(() => isError = true);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Kunci Pengunjung (OPAC)'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan password petugas/admin untuk keluar dari pencarian OPAC.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pwdCtrl,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      errorText: isError
                          ? 'Password salah atau tidak valid'
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.key_rounded),
                    ),
                    onSubmitted: (_) => checkPwd(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    pwdCtrl.clear();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: checkPwd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Buka Kunci'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _promptExitOpac();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: CustomScrollView(
          slivers: [
            OpacHeroSection(
              searchCtrl: _searchCtrl,
              isLoading: _isLoading,
              onSearch: _doSearch,
              onBack: _promptExitOpac,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(32.0),
              sliver: _hasSearched && _results.isNotEmpty
                  ? OpacBookList(results: _results)
                  : OpacEmptyState(
                      hasSearched: _hasSearched,
                      isDark: isDark,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
