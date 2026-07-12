import 'package:drift/drift.dart';

import 'books.dart';
import 'students.dart';
import 'users.dart';

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get loanDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get returnDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('dipinjam'),
  )(); // dipinjam, dikembalikan, terlambat, hilang
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
