import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';
import '../../widgets/csv_import_dialog.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = _searchQuery.isEmpty
        ? ref.watch(studentsProvider)
        : ref.watch(studentSearchProvider(_searchQuery));

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
                      'Data Santri',
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
                      'Kelola data santri perpustakaan',
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
                      importType: ImportType.students,
                      database: db,
                    ),
                  );
                  if (imported == true) {
                    ref.invalidate(studentsProvider);
                  }
                },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Import CSV'),
              ),
              const SizedBox(width: 10),
              // Delete all button
              OutlinedButton.icon(
                onPressed: () => _deleteAllStudents(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Hapus Semua'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showStudentForm(context),
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: const Text('Tambah Santri'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama, NIS, atau kelas santri...',
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
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 64,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada data santri',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _StudentListItem(
                          student: student,
                          isDark: isDark,
                          onEdit: () =>
                              _showStudentForm(context, student: student),
                          onDelete: () => _deleteStudent(student),
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

  void _showStudentForm(BuildContext context, {Student? student}) {
    showDialog(
      context: context,
      builder: (context) => _StudentFormDialog(student: student),
    );
  }

  Future<void> _deleteStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Santri'),
        content: Text('Yakin ingin menghapus "${student.name}"?'),
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
      await ref.read(databaseProvider).deleteStudent(student.id);
      ref.invalidate(studentsProvider);
      ref.invalidate(dashboardStatsProvider);
    }
  }

  Future<void> _deleteAllStudents(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus SEMUA Santri?'),
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
              'Tindakan ini tidak dapat dibatalkan! Semua data santri akan hilang permanen.',
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
      await ref.read(databaseProvider).deleteAllStudents();
      ref.invalidate(studentsProvider);
      ref.invalidate(dashboardStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua data santri berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

class _StudentListItem extends StatelessWidget {
  final Student student;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentListItem({
    required this.student,
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
          CircleAvatar(
            radius: 22,
            backgroundColor: student.gender == 'L'
                ? AppColors.info.withAlpha(25)
                : AppColors.accent.withAlpha(25),
            backgroundImage: student.photo.isNotEmpty
                ? MemoryImage(base64Decode(student.photo))
                : null,
            child: student.photo.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    color: student.gender == 'L'
                        ? AppColors.info
                        : AppColors.accent,
                    size: 22,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIS: ${student.nis}',
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
          SizedBox(
            width: 120,
            child: Text(
              student.classRoom,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: student.status == 'aktif'
                  ? AppColors.success.withAlpha(20)
                  : AppColors.darkTextSecondary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              student.status == 'aktif' ? 'Aktif' : 'Alumni',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: student.status == 'aktif'
                    ? AppColors.success
                    : AppColors.darkTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
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

class _StudentFormDialog extends ConsumerStatefulWidget {
  final Student? student;
  const _StudentFormDialog({this.student});

  @override
  ConsumerState<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nisC;
  late final TextEditingController _nameC;
  late final TextEditingController _classC;
  String _gender = 'L';
  String _status = 'aktif';
  String _photoBase64 = '';

  @override
  void initState() {
    super.initState();
    _nisC = TextEditingController(text: widget.student?.nis ?? '');
    _nameC = TextEditingController(text: widget.student?.name ?? '');
    _classC = TextEditingController(text: widget.student?.classRoom ?? '');
    _gender = widget.student?.gender ?? 'L';
    _status = widget.student?.status ?? 'aktif';
    _photoBase64 = widget.student?.photo ?? '';
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final bytes = await File(result.files.single.path!).readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _photoBase64 = '';
    });
  }

  @override
  void dispose() {
    _nisC.dispose();
    _nameC.dispose();
    _classC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Santri' : 'Tambah Santri Baru',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      backgroundImage: _photoBase64.isNotEmpty
                          ? MemoryImage(base64Decode(_photoBase64))
                          : null,
                      child: _photoBase64.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: Text(
                            _photoBase64.isEmpty ? 'Tambah Foto' : 'Ganti Foto',
                          ),
                        ),
                        if (_photoBase64.isNotEmpty)
                          TextButton(
                            onPressed: _removePhoto,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            child: const Text('Hapus'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nisC,
                decoration: InputDecoration(
                  labelText: 'NIS *',
                  hintText: 'Nomor Induk Santri',
                  labelStyle: GoogleFonts.inter(fontSize: 13),
                ),
                validator: (v) => v?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameC,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap *',
                  hintText: 'Masukkan nama santri',
                  labelStyle: GoogleFonts.inter(fontSize: 13),
                ),
                validator: (v) => v?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classC,
                decoration: InputDecoration(
                  labelText: 'Kelas / Kamar',
                  hintText: 'Contoh: Kelas 3A atau Kamar Al-Fatih',
                  labelStyle: GoogleFonts.inter(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Jenis Kelamin',
                        labelStyle: GoogleFonts.inter(fontSize: 13),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'L'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        labelStyle: GoogleFonts.inter(fontSize: 13),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'alumni',
                          child: Text('Alumni'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'aktif'),
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
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Santri'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);

    if (widget.student != null) {
      await db.updateStudent(
        widget.student!.copyWith(
          nis: _nisC.text.trim(),
          name: _nameC.text.trim(),
          classRoom: _classC.text.trim(),
          gender: _gender,
          status: _status,
          photo: _photoBase64,
        ),
      );
    } else {
      await db.insertStudent(
        StudentsCompanion.insert(
          nis: _nisC.text.trim(),
          name: _nameC.text.trim(),
          classRoom: drift.Value(_classC.text.trim()),
          gender: drift.Value(_gender),
          status: drift.Value(_status),
          photo: drift.Value(_photoBase64),
        ),
      );
    }

    ref.invalidate(studentsProvider);
    ref.invalidate(dashboardStatsProvider);
    if (mounted) Navigator.pop(context);
  }
}
