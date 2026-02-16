import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c1 = dk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = dk ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = dk ? AppColors.darkSurface : AppColors.lightSurface;
    final bd = dk ? AppColors.darkBorder : AppColors.lightBorder;
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Konfigurasi aplikasi perpustakaan',
            style: GoogleFonts.inter(fontSize: 14, color: c2),
          ),
          const SizedBox(height: 28),

          // Theme
          _Section(
            title: 'Tampilan',
            icon: Icons.palette_rounded,
            bg: bg,
            bd: bd,
            dk: dk,
            children: [
              _SettingRow(
                label: 'Mode Gelap',
                dk: dk,
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  activeColor: AppColors.primary,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggleTheme(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Library settings
          settingsAsync.when(
            data: (settings) => Column(
              children: [
                _Section(
                  title: 'Perpustakaan',
                  icon: Icons.local_library_rounded,
                  bg: bg,
                  bd: bd,
                  dk: dk,
                  children: [
                    _EditableSetting(
                      label: 'Nama Perpustakaan',
                      value: settings['library_name'] ?? '',
                      dk: dk,
                      onSave: (v) {
                        ref
                            .read(databaseProvider)
                            .setSetting('library_name', v);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    _EditableSetting(
                      label: 'Durasi Pinjam (hari)',
                      value: settings['loan_duration_days'] ?? '7',
                      dk: dk,
                      isNumber: true,
                      onSave: (v) {
                        ref
                            .read(databaseProvider)
                            .setSetting('loan_duration_days', v);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    _EditableSetting(
                      label: 'Denda per Hari (Rp)',
                      value: settings['fine_per_day'] ?? '500',
                      dk: dk,
                      isNumber: true,
                      onSave: (v) {
                        ref
                            .read(databaseProvider)
                            .setSetting('fine_per_day', v);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    _EditableSetting(
                      label: 'Maks Buku per Santri',
                      value: settings['max_books_per_student'] ?? '3',
                      dk: dk,
                      isNumber: true,
                      onSave: (v) {
                        ref
                            .read(databaseProvider)
                            .setSetting('max_books_per_student', v);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),

          // Security
          _Section(
            title: 'Keamanan',
            icon: Icons.security_rounded,
            bg: bg,
            bd: bd,
            dk: dk,
            children: [
              _SettingRow(
                label: 'Ubah Username & Password',
                dk: dk,
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text('Ubah'),
                  onPressed: () => _showChangeCredentialDialog(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Backup & Restore
          _Section(
            title: 'Backup & Restore',
            icon: Icons.backup_rounded,
            bg: bg,
            bd: bd,
            dk: dk,
            children: [
              _SettingRow(
                label: 'Backup database ke file',
                dk: dk,
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Backup'),
                  onPressed: () => _backup(context, ref),
                ),
              ),
              _SettingRow(
                label: 'Restore dari file backup',
                dk: dk,
                trailing: OutlinedButton.icon(
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Restore'),
                  onPressed: () => _restore(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bd),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perpustakaan Pondok Pesantren v1.0',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c1,
                      ),
                    ),
                    Text(
                      'Create Mustofa No : 0813 5908 8246 ',
                      style: GoogleFonts.inter(fontSize: 12, color: c2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _backup(BuildContext ctx, WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      final dbPath = await db.getDatabasePath();
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Backup',
        fileName: 'perpustakaan_backup.db',
      );
      if (result != null) {
        await File(dbPath).copy(result);
        if (ctx.mounted)
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Backup berhasil!'),
              backgroundColor: AppColors.success,
            ),
          );
      }
    } catch (e) {
      if (ctx.mounted)
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Gagal backup: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
    }
  }

  Future<void> _restore(BuildContext ctx, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      if (result != null && result.files.single.path != null) {
        final db = ref.read(databaseProvider);
        final dbPath = await db.getDatabasePath();
        await File(result.files.single.path!).copy(dbPath);
        if (ctx.mounted)
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Restore berhasil! Restart aplikasi.'),
              backgroundColor: AppColors.success,
            ),
          );
      }
    } catch (e) {
      if (ctx.mounted)
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Gagal restore: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
    }
  }

  void _showChangeCredentialDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _ChangeCredentialDialog(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bg, bd;
  final bool dk;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.icon,
    required this.bg,
    required this.bd,
    required this.dk,
    required this.children,
  });
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: bd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dk
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final bool dk;
  final Widget trailing;
  const _SettingRow({
    required this.label,
    required this.dk,
    required this.trailing,
  });
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: dk
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _EditableSetting extends StatefulWidget {
  final String label, value;
  final bool dk, isNumber;
  final Function(String) onSave;
  const _EditableSetting({
    required this.label,
    required this.value,
    required this.dk,
    this.isNumber = false,
    required this.onSave,
  });
  @override
  State<_EditableSetting> createState() => _EditableSettingState();
}

class _EditableSettingState extends State<_EditableSetting> {
  bool _editing = false;
  late TextEditingController _c;
  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _EditableSetting old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _c.text = widget.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: widget.dk
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
        if (_editing) ...[
          SizedBox(
            width: 200,
            child: TextField(
              controller: _c,
              keyboardType: widget.isNumber ? TextInputType.number : null,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.success,
            ),
            onPressed: () {
              widget.onSave(_c.text);
              setState(() => _editing = false);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.danger,
            ),
            onPressed: () {
              _c.text = widget.value;
              setState(() => _editing = false);
            },
          ),
        ] else ...[
          Text(
            widget.value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.dk
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              size: 16,
              color: widget.dk
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () => setState(() => _editing = true),
          ),
        ],
      ],
    ),
  );
}

class _ChangeCredentialDialog extends ConsumerStatefulWidget {
  const _ChangeCredentialDialog();

  @override
  ConsumerState<_ChangeCredentialDialog> createState() =>
      _ChangeCredentialDialogState();
}

class _ChangeCredentialDialogState
    extends ConsumerState<_ChangeCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newUserController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authProvider).currentUser;
    if (currentUser != null) {
      _newUserController.text = currentUser.username;
    }
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newUserController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider).currentUser;
    if (currentUser == null) return;

    final db = ref.read(databaseProvider);
    final success = await db.updateAdminCredentials(
      currentUser.id,
      _oldPassController.text,
      _newUserController.text.trim(),
      _newPassController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Detail login berhasil diperbarui! Silakan login ulang.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      ref.read(authProvider.notifier).logout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password lama salah!'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Username & Password'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPassController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOld ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newUserController,
                decoration: const InputDecoration(
                  labelText: 'Username Baru',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
