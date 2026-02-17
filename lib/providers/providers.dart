import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../data/database/app_database.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Auth state
class AuthState {
  final User? currentUser;
  final bool isLoggedIn;
  const AuthState({this.currentUser, this.isLoggedIn = false});
  AuthState copyWith({User? currentUser, bool? isLoggedIn}) => AuthState(
    currentUser: currentUser ?? this.currentUser,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
  );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login(String username, String password) async {
    final db = ref.read(databaseProvider);
    final user = await db.authenticateUser(username, password);
    if (user != null) {
      state = AuthState(currentUser: user, isLoggedIn: true);
      return true;
    }
    return false;
  }

  void logout() => state = const AuthState();
  bool get isAdmin => state.currentUser?.role == 'admin';
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Theme mode provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final db = ref.read(databaseProvider);
    final theme = await db.getSetting('theme_mode');
    state = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final db = ref.read(databaseProvider);
    await db.setSetting(
      'theme_mode',
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// Books provider
final booksProvider = StreamProvider<List<Book>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBooks();
});

final bookSearchProvider = FutureProvider.family<List<Book>, String>((
  ref,
  query,
) {
  final db = ref.watch(databaseProvider);
  if (query.isEmpty) return db.getAllBooks();
  return db.searchBooks(query);
});

// Students provider
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllStudents();
});

final studentSearchProvider = FutureProvider.family<List<Student>, String>((
  ref,
  query,
) {
  final db = ref.watch(databaseProvider);
  if (query.isEmpty) return db.getAllStudents();
  return db.searchStudents(query);
});

// Loans provider
final activeLoansProvider = StreamProvider<List<Loan>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActiveLoans();
});

final loansWithDetailsProvider =
    FutureProvider.family<List<LoanWithDetails>, String?>((ref, status) {
      final db = ref.watch(databaseProvider);
      return db.getLoansWithDetails(status: status);
    });

// Dashboard stats
class DashboardStats {
  final int totalBooks, totalStudents, activeLoans, overdueLoans;
  DashboardStats({
    required this.totalBooks,
    required this.totalStudents,
    required this.activeLoans,
    required this.overdueLoans,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(databaseProvider);
  return DashboardStats(
    totalBooks: await db.getTotalBooks(),
    totalStudents: await db.getTotalStudents(),
    activeLoans: await db.getActiveLoansCount(),
    overdueLoans: await db.getOverdueLoansCount(),
  );
});

// Attendance provider
final recentAttendancesProvider = FutureProvider<List<AttendanceWithStudent>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.getRecentAttendances();
});

final topVisitorsProvider = FutureProvider<List<TopVisitor>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getTopVisitors();
});

// Settings
final settingsProvider = FutureProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllSettings();
});

// Navigation
class SelectedNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedNavIndexProvider =
    NotifierProvider<SelectedNavIndexNotifier, int>(
      SelectedNavIndexNotifier.new,
    );
