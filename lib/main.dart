import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'ui/screens/login/login_screen.dart';
import 'ui/widgets/sidebar.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/books/book_list_screen.dart';
import 'ui/screens/students/student_list_screen.dart';
import 'ui/screens/loans/loan_screen.dart';
import 'ui/screens/loans/return_screen.dart';
import 'ui/screens/fines/fine_screen.dart';
import 'ui/screens/reports/reports_screen.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'ui/screens/attendance/attendance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1024, 680),
    center: true,
    title: 'Perpustakaan Pondok Pesantren',
    backgroundColor: Colors.transparent,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: PerpustakaanApp()));
}

class PerpustakaanApp extends ConsumerWidget {
  const PerpustakaanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Perpustakaan Pondok Pesantren',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      home: authState.isLoggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);

    final screens = <Widget>[
      const DashboardScreen(), // 0
      const BookListScreen(), // 1
      const StudentListScreen(), // 2
      const AttendanceScreen(), // 3
      const LoanScreen(), // 4
      const ReturnScreen(), // 5
      const FineScreen(), // 6
      const ReportsScreen(), // 7
      const SettingsScreen(), // 8
    ];

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(selectedIndex),
                child: screens[selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
