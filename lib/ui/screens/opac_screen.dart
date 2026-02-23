import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';

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
            Future<void> _checkPwd() async {
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
                Navigator.pop(ctx);
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
                    onSubmitted: (_) => _checkPwd(),
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
                  onPressed: _checkPwd,
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
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _promptExitOpac();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: CustomScrollView(
          slivers: [
            // Custom App Bar / Hero Section
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: isDark
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF0D9488),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D9488),
                        Color(0xFF0F766E),
                        Color(0xFF134E4A),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative elements
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -80,
                        left: -50,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(15),
                          ),
                        ),
                      ),
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eksplorasi Katalog Buku',
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Temukan inspirasi dan pengetahuan dari ribuan koleksi kami.',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white.withAlpha(220),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Search Bar
                              Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 20),
                                    Icon(
                                      Icons.search_rounded,
                                      color: Colors.grey[400],
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchCtrl,
                                        autofocus: true,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Ketik judul, pengarang, atau kode buku...',
                                          hintStyle: GoogleFonts.inter(
                                            color: Colors.grey[400],
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onSubmitted: (_) => _doSearch(),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _doSearch,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0F766E,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          minimumSize: const Size(
                                            100,
                                            double.infinity,
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                'Cari',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 8.0,
                  bottom: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _promptExitOpac,
                    tooltip: 'Kembali (Butuh Password)',
                  ),
                ),
              ),
            ),

            // Results Section
            SliverPadding(
              padding: const EdgeInsets.all(32.0),
              sliver: _buildBodyContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(bool isDark) {
    if (!_hasSearched) {
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

    if (_results.isEmpty) {
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

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final b = _results[index];
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
                              color:
                                  (isAvailable
                                          ? AppColors.success
                                          : AppColors.danger)
                                      .withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    (isAvailable
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
      }, childCount: _results.length),
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
