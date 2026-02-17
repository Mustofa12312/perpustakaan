import 'package:drift/drift.dart';
import 'students.dart';

class Attendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer().references(Students, #id)();
  DateTimeColumn get checkInTime =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get checkOutTime => dateTime().nullable()();
  TextColumn get purpose =>
      text().nullable()(); // Reading, Borrowing, Returning, etc.
}
