import '../models/database.dart';

abstract class ReceiptLocalDataSource {
  Future<List<Receipt>> getAllReceipts();
  Future<Receipt?> getReceiptById(int id);
  Future<List<LineItem>> getLineItemsForReceipt(int receiptId);
  Future<int> insertReceipt(ReceiptsCompanion receipt);
  Future<int> insertLineItem(LineItemsCompanion lineItem);
  Future<bool> updateReceipt(Receipt receipt);
  Future<int> deleteReceipt(int id);
  Future<int> insertReceiptWithLineItems(
    ReceiptsCompanion receipt,
    List<LineItemsCompanion> items,
  );
  Future<List<Receipt>> searchReceiptsByVendor(String query);
  Future<List<Receipt>> getReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<Receipt>> getReceiptsByCategory(String category);
  Future<double> getTotalSpending();
  Future<Map<String, double>> getSpendingByCategory();
}

class ReceiptLocalDataSourceImpl implements ReceiptLocalDataSource {
  final AppDatabase database;

  ReceiptLocalDataSourceImpl(this.database);

  @override
  Future<List<Receipt>> getAllReceipts() => database.getAllReceipts();

  @override
  Future<Receipt?> getReceiptById(int id) => database.getReceiptById(id);

  @override
  Future<List<LineItem>> getLineItemsForReceipt(int receiptId) =>
      database.getLineItemsForReceipt(receiptId);

  @override
  Future<int> insertReceipt(ReceiptsCompanion receipt) =>
      database.insertReceipt(receipt);

  @override
  Future<int> insertLineItem(LineItemsCompanion lineItem) =>
      database.insertLineItem(lineItem);

  @override
  Future<bool> updateReceipt(Receipt receipt) =>
      database.updateReceipt(receipt);

  @override
  Future<int> deleteReceipt(int id) => database.deleteReceipt(id);

  @override
  Future<int> insertReceiptWithLineItems(
    ReceiptsCompanion receipt,
    List<LineItemsCompanion> items,
  ) =>
      database.insertReceiptWithLineItems(receipt, items);

  @override
  Future<List<Receipt>> searchReceiptsByVendor(String query) =>
      database.searchReceiptsByVendor(query);

  @override
  Future<List<Receipt>> getReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) =>
      database.getReceiptsByDateRange(startDate, endDate);

  @override
  Future<List<Receipt>> getReceiptsByCategory(String category) =>
      database.getReceiptsByCategory(category);

  @override
  Future<double> getTotalSpending() => database.getTotalSpending();

  @override
  Future<Map<String, double>> getSpendingByCategory() =>
      database.getSpendingByCategory();
}
