import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class LoanScreen extends ConsumerStatefulWidget {
  const LoanScreen({super.key});
  @override
  ConsumerState<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends ConsumerState<LoanScreen> {
  Student? _student;
  Book? _book;
  int _days = 7;
  bool _busy = false;

  Future<void> _process() async {
    if (_student == null || _book == null) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      final auth = ref.read(authProvider);
      if (_book!.availableQty <= 0) {
        _err('Buku tidak tersedia');
        return;
      }
      final sMap = await db.getAllSettings();
      final max = int.tryParse(sMap['max_books_per_student'] ?? '3') ?? 3;
      final active = await db.getActiveLoansByStudent(_student!.id);
      if (active.length >= max) {
        _err('Batas maks $max buku');
        return;
      }
      final now = DateTime.now();
      await db.insertLoan(
        LoansCompanion.insert(
          studentId: _student!.id,
          bookId: _book!.id,
          userId: auth.currentUser?.id ?? 1,
          dueDate: now.add(Duration(days: _days)),
        ),
      );
      await db.updateBook(
        _book!.copyWith(availableQty: _book!.availableQty - 1),
      );
      ref.invalidate(booksProvider);
      ref.invalidate(activeLoansProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(loansWithDetailsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil! ${_book!.title} → ${_student!.name}'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _student = null;
          _book = null;
        });
      }
    } catch (e) {
      _err('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _err(String m) {
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c1 = dk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = dk ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = dk ? AppColors.darkSurface : AppColors.lightSurface;
    final bd = dk ? AppColors.darkBorder : AppColors.lightBorder;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peminjaman Buku',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catat peminjaman buku baru',
            style: GoogleFonts.inter(fontSize: 14, color: c2),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: bd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Form Peminjaman',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Pilih Santri',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Picker<Student>(
                          selected: _student,
                          hint: 'Ketik nama atau NIS...',
                          search: (q) =>
                              ref.read(databaseProvider).searchStudents(q),
                          label: (s) => '${s.name} (${s.nis})',
                          subLabel: (s) => '${s.nis} • ${s.classRoom}',
                          onSelect: (s) => setState(() => _student = s),
                          onClear: () => setState(() => _student = null),
                          isDark: dk,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Pilih Buku',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Picker<Book>(
                          selected: _book,
                          hint: 'Ketik judul atau kode...',
                          search: (q) async =>
                              (await ref.read(databaseProvider).searchBooks(q))
                                  .where((b) => b.availableQty > 0)
                                  .toList(),
                          label: (b) => '${b.title} (${b.code})',
                          subLabel: (b) =>
                              '${b.code} • ${b.author} • Sisa: ${b.availableQty}',
                          onSelect: (b) => setState(() => _book = b),
                          onClear: () => setState(() => _book = null),
                          isDark: dk,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Durasi Pinjam',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final d in [3, 5, 7, 14])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('$d hari'),
                                  selected: _days == d,
                                  selectedColor: AppColors.primary.withAlpha(
                                    30,
                                  ),
                                  onSelected: (s) {
                                    if (s) setState(() => _days = d);
                                  },
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed:
                                (_student != null && _book != null && !_busy)
                                ? _process
                                : null,
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_rounded),
                            label: Text(
                              _busy ? 'Memproses...' : 'Proses Peminjaman',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                            Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ringkasan',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: c1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _Sum('Santri', _student?.name ?? '-', dk),
                        _Sum('NIS', _student?.nis ?? '-', dk),
                        _Sum('Kelas', _student?.classRoom ?? '-', dk),
                        const Divider(height: 24),
                        _Sum('Buku', _book?.title ?? '-', dk),
                        _Sum('Kode', _book?.code ?? '-', dk),
                        _Sum('Pengarang', _book?.author ?? '-', dk),
                        const Divider(height: 24),
                        _Sum(
                          'Tgl Pinjam',
                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                          dk,
                        ),
                        _Sum(
                          'Batas Kembali',
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(DateTime.now().add(Duration(days: _days))),
                          dk,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Picker<T> extends StatefulWidget {
  final T? selected;
  final String hint;
  final bool isDark;
  final Future<List<T>> Function(String) search;
  final String Function(T) label;
  final String Function(T) subLabel;
  final void Function(T) onSelect;
  final VoidCallback onClear;
  const _Picker({
    this.selected,
    required this.hint,
    required this.isDark,
    required this.search,
    required this.label,
    required this.subLabel,
    required this.onSelect,
    required this.onClear,
  });
  @override
  State<_Picker<T>> createState() => _PickerState<T>();
}

class _PickerState<T> extends State<_Picker<T>> {
  final _c = TextEditingController();
  List<T> _r = [];
  bool _show = false;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selected != null)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withAlpha(50)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label(widget.selected as T),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: widget.onClear,
            ),
          ],
        ),
      );
    return Column(
      children: [
        TextField(
          controller: _c,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
          ),
          onChanged: (v) async {
            if (v.length >= 2) {
              final r = await widget.search(v);
              setState(() {
                _r = r;
                _show = r.isNotEmpty;
              });
            } else {
              setState(() {
                _r = [];
                _show = false;
              });
            }
          },
        ),
        if (_show)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _r.length,
              itemBuilder: (ctx, i) => ListTile(
                dense: true,
                title: Text(
                  widget.label(_r[i]),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  widget.subLabel(_r[i]),
                  style: GoogleFonts.inter(fontSize: 11),
                ),
                onTap: () {
                  widget.onSelect(_r[i]);
                  _c.clear();
                  setState(() => _show = false);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Sum extends StatelessWidget {
  final String l, v;
  final bool dk;
  final Color? color;
  const _Sum(this.l, this.v, this.dk, {this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            l,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: dk
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  color ??
                  (dk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    ),
  );
}
