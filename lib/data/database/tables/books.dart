import 'package:drift/drift.dart';

class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 50).unique()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get author => text().withLength(min: 1, max: 255)();
  TextColumn get publisher => text().withDefault(const Constant(''))();
  IntColumn get year => integer().withDefault(const Constant(0))();
  TextColumn get category => text().withDefault(const Constant('Umum'))();
  IntColumn get totalQty => integer().withDefault(const Constant(1))();
  IntColumn get availableQty => integer().withDefault(const Constant(1))();
  TextColumn get shelfLocation => text().withDefault(const Constant(''))();
  TextColumn get coverImage => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
