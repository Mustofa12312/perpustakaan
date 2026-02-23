import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../opac_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Username dan password harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        setState(() => _error = 'Username atau password salah');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Left - Branding panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B), // Slate 800
                    Color(0xFF0F172A), // Slate 900
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle Watermark
                  Positioned(
                    right: -80,
                    bottom: -80,
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 400,
                      color: Colors.white.withAlpha(10), // Extremely subtle
                    ),
                  ),
                  // Diagonal decorative lines top left
                  Positioned(
                    top: 60,
                    left: 60,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 2,
                          color: Colors.white.withAlpha(40),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 2,
                          color: Colors.white.withAlpha(40),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 2,
                          color: Colors.white.withAlpha(40),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 100),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withAlpha(30),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Consumer(
                              builder: (context, ref, child) {
                                final settings =
                                    ref.watch(settingsProvider).value ?? {};
                                final libName =
                                    settings['library_name'] ??
                                    'Perpustakaan Pondok Pesantren';
                                final nameParts = libName.toString().split(' ');
                                final firstName = nameParts.first;
                                final secondName = nameParts.length > 1
                                    ? nameParts.skip(1).join(' ')
                                    : '';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      firstName.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -2.0,
                                        height: 1.1,
                                      ),
                                    ),
                                    if (secondName.isNotEmpty)
                                      Text(
                                        secondName.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withAlpha(200),
                                          letterSpacing: -2.0,
                                          height: 1.1,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            Container(
                              width: 64,
                              height: 3,
                              color: Colors.white.withAlpha(80),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Sistem Informasi Manajemen\nPerpustakaan Digital Terintegrasi',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white.withAlpha(160),
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 48),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withAlpha(40),
                                  ),
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withAlpha(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => const OpacScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  'Pencarian Cepat (OPAC)',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right - Login form
          Expanded(
            flex: 4,
            child: Container(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 380),
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Selamat Datang! 👋',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan masuk untuk mengakses sistem perpustakaan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Error message
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.danger.withAlpha(50),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.danger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: GoogleFonts.inter(
                                        color: AppColors.danger,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Username
                          Text(
                            'Username',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan username',
                              hintStyle: GoogleFonts.inter(
                                color: isDark
                                    ? AppColors.darkTextSecondary.withAlpha(150)
                                    : AppColors.lightTextSecondary.withAlpha(
                                        150,
                                      ),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B) // Slate 800
                                  : const Color(0xFFF1F5F9), // Slate 100
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 20),

                          // Password
                          Text(
                            'Password',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan password',
                              hintStyle: GoogleFonts.inter(
                                color: isDark
                                    ? AppColors.darkTextSecondary.withAlpha(150)
                                    : AppColors.lightTextSecondary.withAlpha(
                                        150,
                                      ),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 32),

                          // Login button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF0F766E,
                                ), // Teal 700 / Premium Primary
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Masuk ke Sistem',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Default credentials hint
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(isDark ? 30 : 15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.info.withAlpha(
                                  isDark ? 80 : 40,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.info,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Default: admin / admin123',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF60A5FA)
                                          : AppColors.info,
                                      fontWeight: FontWeight.w500,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
