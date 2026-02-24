import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/database/app_database.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final _nisController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isProcessing = false;
  String? _message;
  bool _isError = false;
  String _selectedPurpose = 'Membaca';
  final List<String> _purposes = [
    'Membaca',
    'Pinjam Buku',
    'Kembali Buku',
    'Belajar',
    'Lainnya',
  ];
  Timer? _debounce;
  List<Student> _suggestions = [];
  bool _isLoadingSuggestions = false;

  @override
  void dispose() {
    _nisController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitAttendance(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _message = null;
    });

    try {
      final db = ref.read(databaseProvider);
      // Attempt to log directly (assumes query is NIS)
      final result = await db.logAttendance(cleanQuery, _selectedPurpose);

      if (result.status == LogStatus.studentNotFound) {
        // If not found as NIS, try searching as Name or NIS partial match
        final searchResults = await db.searchStudents(cleanQuery);

        if (searchResults.isNotEmpty) {
          // Found potential matches, show dialog to let user pick
          if (mounted) {
            setState(() => _isProcessing = false);
            _showSearchDialog(initialQuery: cleanQuery);
          }
          return;
        }

        throw 'Santri dengan NIS/Nama "$query" tidak ditemukan';
      }

      setState(() {
        final studentName = result.student?.name ?? '';
        if (result.status == LogStatus.checkOutSuccess) {
          _message = 'Sampai Jumpa, $studentName! (Check-Out)';
          _isError = false;
        } else {
          _message = 'Selamat Datang, $studentName! (Check-In)';
          _isError = false;
        }
        _nisController.clear();
        _suggestions = [];
      });

      ref.invalidate(recentAttendancesProvider);
      ref.invalidate(topVisitorsProvider);

      // Auto focus back for next scan
      _focusNode.requestFocus();
    } catch (e) {
      setState(() {
        _message = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showSearchDialog({String? initialQuery}) async {
    final selectedNis = await showDialog<String>(
      context: context,
      builder: (context) => _SearchStudentDialog(initialQuery: initialQuery),
    );

    if (selectedNis != null) {
      _submitAttendance(selectedNis);
    }
  }

  void _onMainSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoadingSuggestions = true);
      try {
        final db = ref.read(databaseProvider);
        final results = await db.searchStudents(query);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingSuggestions = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c1 = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bd = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekam Kehadiran',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: c1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Silakan scan barcode pada kartu santri atau ketik NIS secara manual',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: c2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Section
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 40 : 10),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(
                                  isDark ? 30 : 15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 56,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Scan Barcode / Ketik Nama',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: c1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _nisController,
                              focusNode: _focusNode,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: _isProcessing
                                    ? 'MEMPROSES...'
                                    : 'NIS / NAMA',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4,
                                  color: c2.withAlpha(120),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1E293B) // Slate 800
                                    : const Color(0xFFF1F5F9), // Slate 100
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onSubmitted: _submitAttendance,
                              onChanged: _onMainSearchChanged,
                            ),
                            if (_isLoadingSuggestions)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            if (_suggestions.isNotEmpty && !_isProcessing)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  border: Border.all(color: bd),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, __) =>
                                      Divider(height: 1, color: bd),
                                  itemBuilder: (context, index) {
                                    final student = _suggestions[index];
                                    return ListTile(
                                      visualDensity: VisualDensity.compact,
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primary
                                            .withAlpha(30),
                                        child: Text(
                                          student.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        student.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: c1,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'NIS: ${student.nis}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: c2,
                                        ),
                                      ),
                                      onTap: () {
                                        _submitAttendance(student.nis);
                                        setState(() => _suggestions = []);
                                      },
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _showSearchDialog,
                              icon: Icon(
                                Icons.person_search_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              label: Text(
                                'Cari Siswa Manual (Nama/NIS)',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Tujuan Kunjungan Terpilih',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: c2,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: _purposes.map((p) {
                                final selected = _selectedPurpose == p;
                                return ChoiceChip(
                                  label: Text(
                                    p,
                                    style: GoogleFonts.inter(
                                      color: selected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  selected: selected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.primary
                                        : (isDark
                                              ? Colors.white12
                                              : Colors.black12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  showCheckmark: false,
                                  labelStyle: GoogleFonts.inter(
                                    color: selected ? Colors.white : c1,
                                  ),
                                  onSelected: (val) {
                                    if (val)
                                      setState(() => _selectedPurpose = p);
                                    // Keep focus on text field
                                    _focusNode.requestFocus();
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            if (_message != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      (_isError
                                              ? AppColors.danger
                                              : AppColors.success)
                                          .withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        (_isError
                                                ? AppColors.danger
                                                : AppColors.success)
                                            .withAlpha(50),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isError
                                          ? Icons.error_outline
                                          : Icons.check_circle_outline,
                                      color: _isError
                                          ? AppColors.danger
                                          : AppColors.success,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _message!,
                                        style: GoogleFonts.inter(
                                          color: _isError
                                              ? AppColors.danger
                                              : AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Top Visitors Graph Section
                      Expanded(child: _TopVisitorsChart(isDark: isDark)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Recent History Section
                Expanded(flex: 2, child: _RecentAttendanceList(isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAttendanceList extends ConsumerWidget {
  final bool isDark;
  const _RecentAttendanceList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentAttendancesProvider);
    final c1 = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final bd = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Kehadiran Hari Ini',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: c1,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
          ),
          Expanded(
            child: recentAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada data hari ini',
                      style: GoogleFonts.inter(color: c2),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC), // Slate 800 or Slate 50
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withAlpha(
                              isDark ? 40 : 25,
                            ),
                            child: Text(
                              item.student.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.student.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c1,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.student.nis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: c2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat(
                                    'HH:mm',
                                  ).format(item.attendance.checkInTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              if (item.attendance.checkOutTime != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(item.attendance.checkOutTime!),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Aktif',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopVisitorsChart extends ConsumerWidget {
  final bool isDark;
  const _TopVisitorsChart({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topVisitorsAsync = ref.watch(topVisitorsProvider);
    final c1 = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final bd = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Santri Paling Rajin (Bulan Ini)',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: c1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: topVisitorsAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'Data tidak cukup',
                      style: GoogleFonts.inter(color: c2),
                    ),
                  );
                }

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        (data
                                    .map((e) => e.visitCount)
                                    .reduce((a, b) => a > b ? a : b) +
                                1)
                            .toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${data[group.x].student.name}\n${rod.toY.toInt()} Kehadiran',
                            GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < data.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  data[index].student.name.split(' ')[0],
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: c2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].visitCount.toDouble(),
                            color: AppColors.primary,
                            width: 32,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 0,
                              color: AppColors.primary.withAlpha(10),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchStudentDialog extends ConsumerStatefulWidget {
  final String? initialQuery;
  const _SearchStudentDialog({this.initialQuery});

  @override
  ConsumerState<_SearchStudentDialog> createState() =>
      _SearchStudentDialogState();
}

class _SearchStudentDialogState extends ConsumerState<_SearchStudentDialog> {
  final _searchController = TextEditingController();
  List<Student> _results = [];
  bool _isLoading = false;
  Timer? _debounce;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
        _searchFocus.requestFocus();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final results = await db.searchStudents(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c1 = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final c2 = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cari Siswa',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: c2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: 'Ketik Nama atau NIS...',
                  prefixIcon: Icon(Icons.search, color: c2),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: GoogleFonts.inter(color: c2),
                ),
                style: GoogleFonts.inter(color: c1),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: c2.withAlpha(100),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Mulai ketik untuk mencari...'
                                  : 'Tidak ada data ditemukan',
                              style: GoogleFonts.inter(color: c2),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final student = _results[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withAlpha(30),
                              child: Text(
                                student.name.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              student.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: c1,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'NIS: ${student.nis} • Kelas: ${student.classRoom}',
                              style: GoogleFonts.inter(color: c2, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, student.nis);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'Hadir',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
