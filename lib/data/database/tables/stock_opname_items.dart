import 'package:drift/drift.dart';
import 'stock_opnames.dart';
import 'books.dart';

class StockOpnameItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get opnameId =>
      integer().references(StockOpnames, #id, onDelete: KeyAction.cascade)();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get expectedQty => integer()();
  IntColumn get actualQty => integer().withDefault(const Constant(0))();
}
