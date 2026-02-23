import 'package:drift/drift.dart';

import 'books.dart';
import 'students.dart';
import 'users.dart';

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer().references(Students, #id)();
  IntColumn get bookId => integer().references(Books, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get loanDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get returnDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('dipinjam'),
  )(); // dipinjam, dikembalikan, terlambat, hilang
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
