import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text().withLength(min: 1, max: 255)();
  TextColumn get role =>
      text().withDefault(const Constant('operator'))(); // admin, operator
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
