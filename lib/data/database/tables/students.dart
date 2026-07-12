import 'package:drift/drift.dart';

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nis => text().withLength(min: 1, max: 50).unique()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get classRoom => text().withDefault(const Constant(''))();
  TextColumn get gender => text().withDefault(const Constant('L'))(); // L or P
  TextColumn get status =>
      text().withDefault(const Constant('aktif'))(); // aktif, alumni
  TextColumn get photo => text().withDefault(const Constant(''))();
  TextColumn get phoneNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
