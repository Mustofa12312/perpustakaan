import 'package:drift/drift.dart';
import 'users.dart';

class StockOpnames extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get opnameDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get conductedBy =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get status =>
      text().withDefault(const Constant('in_progress'))(); // in_progress, completed
  TextColumn get notes => text().nullable()();
}
