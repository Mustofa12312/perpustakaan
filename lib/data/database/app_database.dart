import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'tables/books.dart';
import 'tables/students.dart';
import 'tables/loans.dart';
import 'tables/fines.dart';
import 'tables/users.dart';
import 'tables/settings.dart';
import 'tables/attendances.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Books, Students, Loans, Fines, Users, Settings, Attendances],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Seed default admin user
        await into(users).insert(
          UsersCompanion.insert(
            username: 'admin',
            passwordHash: _hashPassword('admin123'),
            fullName: 'Administrator',
            role: const Value('admin'),
          ),
        );
        // Seed default settings
        await batch((b) {
          b.insertAll(settings, [
            SettingsCompanion.insert(
              key: 'library_name',
              value: 'Perpustakaan Pondok Pesantren',
            ),
            SettingsCompanion.insert(key: 'loan_duration_days', value: '7'),
            SettingsCompanion.insert(key: 'fine_per_day', value: '500'),
            SettingsCompanion.insert(key: 'max_books_per_student', value: '3'),
            SettingsCompanion.insert(key: 'theme_mode', value: 'dark'),
          ]);
        });
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(attendances);
        }
        if (from < 3) {
          // Force reset/re-create admin account
          final hash = _hashPassword('admin123');
          await customStatement(
            'INSERT OR REPLACE INTO users (username, password_hash, full_name, role) '
            "VALUES ('admin', ?, 'Administrator', 'admin')",
            [hash],
          );
        }
        if (from < 4) {
          // Hard Reset
          await m.deleteTable('attendances');
          await m.deleteTable('fines');
          await m.deleteTable('loans');
          await m.deleteTable('books');
          await m.deleteTable('students');
          await m.deleteTable('users');
          await m.deleteTable('settings');

          await m.createAll();

          await into(users).insert(
            UsersCompanion.insert(
              username: 'admin',
              passwordHash: _hashPassword('admin123'),
              fullName: 'Administrator',
              role: const Value('admin'),
            ),
          );
          await batch((b) {
            b.insertAll(settings, [
              SettingsCompanion.insert(
                key: 'library_name',
                value: 'Perpustakaan Pondok Pesantren',
              ),
              SettingsCompanion.insert(key: 'loan_duration_days', value: '7'),
              SettingsCompanion.insert(key: 'fine_per_day', value: '500'),
              SettingsCompanion.insert(
                key: 'max_books_per_student',
                value: '3',
              ),
              SettingsCompanion.insert(key: 'theme_mode', value: 'dark'),
            ]);
          });
        }
      },
    );
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ==================== USER QUERIES ====================
  Future<User?> authenticateUser(String username, String password) async {
    final hash = _hashPassword(password);
    return (select(users)..where(
          (u) => u.username.equals(username) & u.passwordHash.equals(hash),
        ))
        .getSingleOrNull();
  }

  Future<bool> updateAdminCredentials(
    int userId,
    String currentPassword,
    String newUsername,
    String newPassword,
  ) async {
    final hash = _hashPassword(currentPassword);
    final user = await (select(
      users,
    )..where((u) => u.id.equals(userId))).getSingleOrNull();

    if (user == null || user.passwordHash != hash) {
      return false;
    }

    final newHash = _hashPassword(newPassword);
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        username: Value(newUsername),
        passwordHash: Value(newHash),
      ),
    );
    return true;
  }

  Future<List<User>> getAllUsers() => select(users).get();

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<bool> updateUser(User user) => update(users).replace(user);

  Future<int> deleteUser(int id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();

  // ==================== BOOK QUERIES ====================
  Future<List<Book>> getAllBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.asc(b.title)])).get();

  Stream<List<Book>> watchAllBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.asc(b.title)])).watch();

  Future<List<Book>> searchBooks(String query) {
    return (select(books)
          ..where(
            (b) =>
                b.title.like('%$query%') |
                b.author.like('%$query%') |
                b.code.like('%$query%') |
                b.category.like('%$query%'),
          )
          ..orderBy([(b) => OrderingTerm.asc(b.title)]))
        .get();
  }

  Future<int> insertBook(BooksCompanion book) => into(books).insert(book);

  Future<bool> updateBook(Book book) => update(books).replace(book);

  Future<int> deleteBook(int id) =>
      (delete(books)..where((b) => b.id.equals(id))).go();

  Future<Book?> getBookByCode(String code) =>
      (select(books)..where((b) => b.code.equals(code))).getSingleOrNull();

  // ==================== STUDENT QUERIES ====================
  Future<List<Student>> getAllStudents() =>
      (select(students)..orderBy([(s) => OrderingTerm.asc(s.name)])).get();

  Stream<List<Student>> watchAllStudents() =>
      (select(students)..orderBy([(s) => OrderingTerm.asc(s.name)])).watch();

  Future<List<Student>> searchStudents(String query) {
    return (select(students)
          ..where(
            (s) =>
                s.name.like('%$query%') |
                s.nis.like('%$query%') |
                s.classRoom.like('%$query%'),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .get();
  }

  Future<int> insertStudent(StudentsCompanion student) =>
      into(students).insert(student);

  Future<bool> updateStudent(Student student) =>
      update(students).replace(student);

  Future<int> deleteStudent(int id) =>
      (delete(students)..where((s) => s.id.equals(id))).go();

  // ==================== LOAN QUERIES ====================
  Future<List<Loan>> getAllLoans() =>
      (select(loans)..orderBy([(l) => OrderingTerm.desc(l.loanDate)])).get();

  Stream<List<Loan>> watchActiveLoans() =>
      (select(loans)
            ..where((l) => l.status.equals('dipinjam'))
            ..orderBy([(l) => OrderingTerm.desc(l.loanDate)]))
          .watch();

  Future<List<Loan>> getActiveLoansByStudent(int studentId) =>
      (select(loans)
            ..where(
              (l) =>
                  l.studentId.equals(studentId) & l.status.equals('dipinjam'),
            )
            ..orderBy([(l) => OrderingTerm.desc(l.loanDate)]))
          .get();

  Future<int> insertLoan(LoansCompanion loan) => into(loans).insert(loan);

  Future<bool> updateLoan(Loan loan) => update(loans).replace(loan);

  Future<Loan?> getLoanById(int id) =>
      (select(loans)..where((l) => l.id.equals(id))).getSingleOrNull();

  Future<List<Loan>> getOverdueLoans() {
    final now = DateTime.now();
    return (select(loans)
          ..where(
            (l) =>
                l.status.equals('dipinjam') & l.dueDate.isSmallerThanValue(now),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.dueDate)]))
        .get();
  }

  // ==================== FINE QUERIES ====================
  Future<List<Fine>> getAllFines() =>
      (select(fines)..orderBy([(f) => OrderingTerm.desc(f.createdAt)])).get();

  Future<int> insertFine(FinesCompanion fine) => into(fines).insert(fine);

  Future<bool> updateFine(Fine fine) => update(fines).replace(fine);

  Future<Fine?> getFineByLoanId(int loanId) =>
      (select(fines)..where((f) => f.loanId.equals(loanId))).getSingleOrNull();

  Future<List<Fine>> getUnpaidFines() =>
      (select(fines)..where((f) => f.isPaid.equals(false))).get();

  // ==================== SETTINGS QUERIES ====================
  Future<String?> getSetting(String key) async {
    final result = await (select(
      settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await (update(settings)..where((s) => s.key.equals(key))).write(
      SettingsCompanion(value: Value(value)),
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(settings).get();
    return {for (var row in rows) row.key: row.value};
  }

  // ==================== ATTENDANCE QUERIES ====================
  Future<int> insertAttendance(AttendancesCompanion entry) =>
      into(attendances).insert(entry);

  Future<List<AttendanceWithStudent>> getRecentAttendances() async {
    final query =
        select(attendances).join([
            innerJoin(students, students.id.equalsExp(attendances.studentId)),
          ])
          ..orderBy([OrderingTerm.desc(attendances.checkInTime)])
          ..limit(10);

    final rows = await query.get();
    return rows.map((row) {
      return AttendanceWithStudent(
        attendance: row.readTable(attendances),
        student: row.readTable(students),
      );
    }).toList();
  }

  Future<List<TopVisitor>> getTopVisitors() async {
    final count = attendances.id.count();
    final query = select(students).join([
      innerJoin(attendances, attendances.studentId.equalsExp(students.id)),
    ]);

    query.addColumns([count]);
    query.groupBy([students.id]);
    query.orderBy([OrderingTerm.desc(count)]);
    query.limit(5);

    final rows = await query.get();
    return rows.map((row) {
      return TopVisitor(
        student: row.readTable(students),
        visitCount: row.read(count) ?? 0,
      );
    }).toList();
  }

  // ==================== DASHBOARD STATS ====================
  Future<int> getTotalBooks() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_qty), 0) as total FROM books',
    ).getSingle();
    return result.read<int>('total');
  }

  Future<int> getTotalStudents() async {
    final result = await customSelect(
      'SELECT COUNT(*) as total FROM students WHERE status = ?',
      variables: [Variable.withString('aktif')],
    ).getSingle();
    return result.read<int>('total');
  }

  Future<int> getActiveLoansCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as total FROM loans WHERE status = ?',
      variables: [Variable.withString('dipinjam')],
    ).getSingle();
    return result.read<int>('total');
  }

  Future<int> getOverdueLoansCount() async {
    final now = DateTime.now().toIso8601String();
    final result = await customSelect(
      'SELECT COUNT(*) as total FROM loans WHERE status = ? AND due_date < ?',
      variables: [Variable.withString('dipinjam'), Variable.withString(now)],
    ).getSingle();
    return result.read<int>('total');
  }

  // ==================== LOAN WITH DETAILS ====================
  Future<List<LoanWithDetails>> getLoansWithDetails({String? status}) async {
    final query =
        '''
      SELECT 
        l.id as loan_id, l.loan_date, l.due_date, l.return_date, l.status as loan_status,
        s.id as student_id, s.nis, s.name as student_name, s.class_room,
        b.id as book_id, b.code as book_code, b.title as book_title, b.author as book_author,
        f.id as fine_id, f.amount as fine_amount, f.days_late, f.is_paid
      FROM loans l
      INNER JOIN students s ON l.student_id = s.id
      INNER JOIN books b ON l.book_id = b.id
      LEFT JOIN fines f ON f.loan_id = l.id
      ${status != null ? 'WHERE l.status = ?' : ''}
      ORDER BY l.loan_date DESC
    ''';

    final variables = status != null
        ? [Variable.withString(status)]
        : <Variable>[];
    final results = await customSelect(query, variables: variables).get();

    return results.map((row) {
      return LoanWithDetails(
        loanId: row.read<int>('loan_id'),
        loanDate: DateTime.parse(row.read<String>('loan_date')),
        dueDate: DateTime.parse(row.read<String>('due_date')),
        returnDate: row.readNullable<String>('return_date') != null
            ? DateTime.parse(row.read<String>('return_date'))
            : null,
        loanStatus: row.read<String>('loan_status'),
        studentId: row.read<int>('student_id'),
        nis: row.read<String>('nis'),
        studentName: row.read<String>('student_name'),
        classRoom: row.read<String>('class_room'),
        bookId: row.read<int>('book_id'),
        bookCode: row.read<String>('book_code'),
        bookTitle: row.read<String>('book_title'),
        bookAuthor: row.read<String>('book_author'),
        fineId: row.readNullable<int>('fine_id'),
        fineAmount: row.readNullable<int>('fine_amount'),
        daysLate: row.readNullable<int>('days_late'),
        isPaid: row.readNullable<bool>('is_paid'),
      );
    }).toList();
  }

  // ==================== RETURN BOOK TRANSACTION ====================
  Future<void> returnBook(int loanId, int finePerDay) async {
    await transaction(() async {
      final loan = await getLoanById(loanId);
      if (loan == null || loan.status == 'dikembalikan') return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(
        loan.dueDate.year,
        loan.dueDate.month,
        loan.dueDate.day,
      );
      final daysLate = today.difference(due).inDays;

      // Update loan status
      await (update(loans)..where((l) => l.id.equals(loanId))).write(
        LoansCompanion(
          returnDate: Value(now),
          status: const Value('dikembalikan'),
        ),
      );

      // Increase book available qty
      await customStatement(
        'UPDATE books SET available_qty = available_qty + 1 WHERE id = ?',
        [loan.bookId],
      );

      // Create fine if late
      if (daysLate > 0) {
        await into(fines).insert(
          FinesCompanion.insert(
            loanId: loanId,
            amount: Value(daysLate * finePerDay),
            daysLate: Value(daysLate),
          ),
        );
      }
    });
  }

  // ==================== BACKUP & RESTORE ====================
  Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'perpustakaan.db');
  }
}

class LoanWithDetails {
  final int loanId;
  final DateTime loanDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String loanStatus;
  final int studentId;
  final String nis;
  final String studentName;
  final String classRoom;
  final int bookId;
  final String bookCode;
  final String bookTitle;
  final String bookAuthor;
  final int? fineId;
  final int? fineAmount;
  final int? daysLate;
  final bool? isPaid;

  LoanWithDetails({
    required this.loanId,
    required this.loanDate,
    required this.dueDate,
    this.returnDate,
    required this.loanStatus,
    required this.studentId,
    required this.nis,
    required this.studentName,
    required this.classRoom,
    required this.bookId,
    required this.bookCode,
    required this.bookTitle,
    required this.bookAuthor,
    this.fineId,
    this.fineAmount,
    this.daysLate,
    this.isPaid,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'perpustakaan.db'));
    return NativeDatabase.createInBackground(file);
  });
}

class AttendanceWithStudent {
  final Attendance attendance;
  final Student student;
  AttendanceWithStudent({required this.attendance, required this.student});
}

class TopVisitor {
  final Student student;
  final int visitCount;
  TopVisitor({required this.student, required this.visitCount});
}
