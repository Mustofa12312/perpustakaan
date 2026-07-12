import 'package:drift/drift.dart';

import 'loans.dart';

class Fines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get loanId =>
      integer().references(Loans, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  IntColumn get daysLate => integer().withDefault(const Constant(0))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
