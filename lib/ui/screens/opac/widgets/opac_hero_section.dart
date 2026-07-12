import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OpacHeroSection extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onBack;

  const OpacHeroSection({
    super.key,
    required this.searchCtrl,
    required this.isLoading,
    required this.onSearch,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      backgroundColor:
          isDark ? const Color(0xFF0F766E) : const Color(0xFF0D9488),
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
                                controller: searchCtrl,
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
                                onSubmitted: (_) => onSearch(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : onSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    double.infinity,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
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
        padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: onBack,
            tooltip: 'Kembali (Butuh Password)',
          ),
        ),
      ),
    );
  }
}
