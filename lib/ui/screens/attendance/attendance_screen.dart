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

  @override
  void dispose() {
    _nisController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitAttendance(String nis) async {
    if (nis.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _message = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final result = await db.logAttendance(nis, _selectedPurpose);

      if (result.status == LogStatus.studentNotFound) {
        throw 'Santri dengan NIS $nis tidak ditemukan';
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
      setState(() => _isProcessing = false);
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
                    'Daftar Hadir (Visitor)',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: c1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan kartu santri atau ketik NIS untuk mencatat kehadiran',
                    style: GoogleFonts.inter(fontSize: 14, color: c2),
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
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
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
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 64,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Silakan Scan Barcode / Ketik NIS',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: c1,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _nisController,
                              focusNode: _focusNode,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                hintText: _isProcessing
                                    ? 'Memproses...'
                                    : 'NIS SANTRI',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                  color: c2.withAlpha(100),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.black26
                                    : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: _submitAttendance,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Tujuan Kunjungan:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: c2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
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
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: selected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: isDark
                                      ? Colors.black26
                                      : Colors.white,
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
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bd = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Kehadiran Terbaru',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withAlpha(20),
                            child: Text(
                              item.student.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.student.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: c1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.student.nis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: c2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat(
                                  'HH:mm',
                                ).format(item.attendance.checkInTime),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (item.attendance.checkOutTime != null)
                                Text(
                                  DateFormat(
                                    'HH:mm',
                                  ).format(item.attendance.checkOutTime!),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                )
                              else
                                Text(
                                  'Aktif',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bd = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                'Santri Paling Sering Hadir (Top 5)',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
