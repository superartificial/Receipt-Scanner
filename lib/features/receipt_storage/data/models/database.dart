import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Receipts table definition
@DataClassName('Receipt')
class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get vendorName => text().nullable()();
  DateTimeColumn get receiptDate => dateTime().nullable()();
  RealColumn get totalAmount => real().nullable()();
  RealColumn get subtotal => real().nullable()();
  RealColumn get taxAmount => real().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get receiptNumber => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get imagePath => text()();
  TextColumn get ocrText => text()();
  TextColumn get llmResponseJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
}

// Line items table definition
@DataClassName('LineItem')
class LineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId =>
      integer().references(Receipts, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemName => text()();
  RealColumn get quantity => real().nullable()();
  RealColumn get unitPrice => real().nullable()();
  RealColumn get totalPrice => real()();
  TextColumn get category => text().nullable()();
  IntColumn get lineNumber => integer().nullable()();
}

// Database class
@DriftDatabase(tables: [Receipts, LineItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // CRUD operations for Receipts

  // Get all receipts
  Future<List<Receipt>> getAllReceipts() => select(receipts).get();

  // Get receipt by ID
  Future<Receipt?> getReceiptById(int id) =>
      (select(receipts)..where((r) => r.id.equals(id))).getSingleOrNull();

  // Get receipts with line items
  Future<List<Receipt>> getReceiptsWithLineItems() async {
    return await select(receipts).get();
  }

  // Get line items for a receipt
  Future<List<LineItem>> getLineItemsForReceipt(int receiptId) =>
      (select(lineItems)..where((li) => li.receiptId.equals(receiptId))).get();

  // Insert receipt
  Future<int> insertReceipt(ReceiptsCompanion receipt) =>
      into(receipts).insert(receipt);

  // Insert line item
  Future<int> insertLineItem(LineItemsCompanion lineItem) =>
      into(lineItems).insert(lineItem);

  // Update receipt
  Future<bool> updateReceipt(Receipt receipt) => update(receipts).replace(receipt);

  // Delete receipt (cascade deletes line items)
  Future<int> deleteReceipt(int id) =>
      (delete(receipts)..where((r) => r.id.equals(id))).go();

  // Insert receipt with line items (transaction)
  Future<int> insertReceiptWithLineItems(
    ReceiptsCompanion receipt,
    List<LineItemsCompanion> items,
  ) async {
    return await transaction(() async {
      final receiptId = await into(receipts).insert(receipt);

      for (final item in items) {
        await into(lineItems).insert(
          item.copyWith(receiptId: Value(receiptId)),
        );
      }

      return receiptId;
    });
  }

  // Search receipts by vendor name
  Future<List<Receipt>> searchReceiptsByVendor(String query) =>
      (select(receipts)
            ..where((r) => r.vendorName.like('%$query%')))
          .get();

  // Get receipts by date range
  Future<List<Receipt>> getReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) =>
      (select(receipts)
            ..where((r) => r.receiptDate.isBiggerOrEqualValue(startDate))
            ..where((r) => r.receiptDate.isSmallerOrEqualValue(endDate)))
          .get();

  // Get receipts by category
  Future<List<Receipt>> getReceiptsByCategory(String category) =>
      (select(receipts)..where((r) => r.category.equals(category))).get();

  // Get total spending
  Future<double> getTotalSpending() async {
    final query = selectOnly(receipts)..addColumns([receipts.totalAmount.sum()]);
    final result = await query.getSingleOrNull();
    return result?.read(receipts.totalAmount.sum()) ?? 0.0;
  }

  // Get total spending by category
  Future<Map<String, double>> getSpendingByCategory() async {
    final query = select(receipts);
    final results = await query.get();

    final categoryTotals = <String, double>{};
    for (final receipt in results) {
      final category = receipt.category ?? 'Uncategorized';
      final amount = receipt.totalAmount ?? 0.0;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }

    return categoryTotals;
  }
}

// Helper function to open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'receipts.sqlite'));
    return NativeDatabase(file);
  });
}
