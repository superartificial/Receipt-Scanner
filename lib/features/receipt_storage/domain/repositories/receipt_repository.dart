import 'package:dartz/dartz.dart';
import '../entities/receipt_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class ReceiptRepository {
  Future<Either<Failure, List<ReceiptEntity>>> getAllReceipts();
  Future<Either<Failure, ReceiptEntity>> getReceiptById(int id);
  Future<Either<Failure, List<LineItemEntity>>> getLineItemsForReceipt(
      int receiptId);
  Future<Either<Failure, int>> saveReceipt(
    ReceiptEntity receipt,
    List<LineItemEntity> lineItems,
  );
  Future<Either<Failure, bool>> updateReceipt(ReceiptEntity receipt);
  Future<Either<Failure, void>> deleteReceipt(int id);
  Future<Either<Failure, List<ReceiptEntity>>> searchReceiptsByVendor(
      String query);
  Future<Either<Failure, List<ReceiptEntity>>> getReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<ReceiptEntity>>> getReceiptsByCategory(
      String category);
  Future<Either<Failure, double>> getTotalSpending();
  Future<Either<Failure, Map<String, double>>> getSpendingByCategory();
}
