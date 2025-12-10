import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../datasources/drift_datasource.dart';
import '../models/database.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final ReceiptLocalDataSource localDataSource;

  ReceiptRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ReceiptEntity>>> getAllReceipts() async {
    try {
      final receipts = await localDataSource.getAllReceipts();
      final receiptEntities = <ReceiptEntity>[];

      for (final receipt in receipts) {
        final lineItems =
            await localDataSource.getLineItemsForReceipt(receipt.id);
        receiptEntities.add(_mapToEntity(receipt, lineItems));
      }

      return Right(receiptEntities);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get receipts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ReceiptEntity>> getReceiptById(int id) async {
    try {
      final receipt = await localDataSource.getReceiptById(id);
      if (receipt == null) {
        return const Left(DatabaseFailure('Receipt not found'));
      }

      final lineItems = await localDataSource.getLineItemsForReceipt(id);
      return Right(_mapToEntity(receipt, lineItems));
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get receipt by id: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<LineItemEntity>>> getLineItemsForReceipt(
      int receiptId) async {
    try {
      final lineItems =
          await localDataSource.getLineItemsForReceipt(receiptId);
      return Right(lineItems.map(_mapLineItemToEntity).toList());
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get line items: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> saveReceipt(
    ReceiptEntity receipt,
    List<LineItemEntity> lineItems,
  ) async {
    try {
      final receiptCompanion = _mapToCompanion(receipt);
      final lineItemCompanions =
          lineItems.map(_mapLineItemToCompanion).toList();

      final receiptId = await localDataSource.insertReceiptWithLineItems(
        receiptCompanion,
        lineItemCompanions,
      );

      return Right(receiptId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to save receipt: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateReceipt(ReceiptEntity receipt) async {
    try {
      if (receipt.id == null) {
        return const Left(ValidationFailure('Receipt ID cannot be null'));
      }

      final dbReceipt = await localDataSource.getReceiptById(receipt.id!);
      if (dbReceipt == null) {
        return const Left(DatabaseFailure('Receipt not found'));
      }

      final updatedReceipt = Receipt(
        id: receipt.id!,
        vendorName: receipt.vendorName,
        receiptDate: receipt.receiptDate,
        totalAmount: receipt.totalAmount,
        subtotal: receipt.subtotal,
        taxAmount: receipt.taxAmount,
        paymentMethod: receipt.paymentMethod,
        receiptNumber: receipt.receiptNumber,
        category: receipt.category,
        imagePath: receipt.imagePath,
        ocrText: receipt.ocrText,
        llmResponseJson: receipt.llmResponseJson,
        createdAt: receipt.createdAt,
        updatedAt: DateTime.now(),
        isVerified: receipt.isVerified,
      );

      final result = await localDataSource.updateReceipt(updatedReceipt);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update receipt: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceipt(int id) async {
    try {
      await localDataSource.deleteReceipt(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete receipt: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReceiptEntity>>> searchReceiptsByVendor(
      String query) async {
    try {
      final receipts = await localDataSource.searchReceiptsByVendor(query);
      final receiptEntities = <ReceiptEntity>[];

      for (final receipt in receipts) {
        final lineItems =
            await localDataSource.getLineItemsForReceipt(receipt.id);
        receiptEntities.add(_mapToEntity(receipt, lineItems));
      }

      return Right(receiptEntities);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to search receipts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReceiptEntity>>> getReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final receipts =
          await localDataSource.getReceiptsByDateRange(startDate, endDate);
      final receiptEntities = <ReceiptEntity>[];

      for (final receipt in receipts) {
        final lineItems =
            await localDataSource.getLineItemsForReceipt(receipt.id);
        receiptEntities.add(_mapToEntity(receipt, lineItems));
      }

      return Right(receiptEntities);
    } catch (e) {
      return Left(DatabaseFailure(
          'Failed to get receipts by date range: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReceiptEntity>>> getReceiptsByCategory(
      String category) async {
    try {
      final receipts = await localDataSource.getReceiptsByCategory(category);
      final receiptEntities = <ReceiptEntity>[];

      for (final receipt in receipts) {
        final lineItems =
            await localDataSource.getLineItemsForReceipt(receipt.id);
        receiptEntities.add(_mapToEntity(receipt, lineItems));
      }

      return Right(receiptEntities);
    } catch (e) {
      return Left(DatabaseFailure(
          'Failed to get receipts by category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalSpending() async {
    try {
      final total = await localDataSource.getTotalSpending();
      return Right(total);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get total spending: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getSpendingByCategory() async {
    try {
      final spending = await localDataSource.getSpendingByCategory();
      return Right(spending);
    } catch (e) {
      return Left(DatabaseFailure(
          'Failed to get spending by category: ${e.toString()}'));
    }
  }

  // Helper methods to map between database models and domain entities

  ReceiptEntity _mapToEntity(Receipt receipt, List<LineItem> lineItems) {
    return ReceiptEntity(
      id: receipt.id,
      vendorName: receipt.vendorName,
      receiptDate: receipt.receiptDate,
      totalAmount: receipt.totalAmount,
      subtotal: receipt.subtotal,
      taxAmount: receipt.taxAmount,
      paymentMethod: receipt.paymentMethod,
      receiptNumber: receipt.receiptNumber,
      category: receipt.category,
      imagePath: receipt.imagePath,
      ocrText: receipt.ocrText,
      llmResponseJson: receipt.llmResponseJson,
      createdAt: receipt.createdAt,
      updatedAt: receipt.updatedAt,
      isVerified: receipt.isVerified,
      lineItems: lineItems.map(_mapLineItemToEntity).toList(),
    );
  }

  LineItemEntity _mapLineItemToEntity(LineItem lineItem) {
    return LineItemEntity(
      id: lineItem.id,
      receiptId: lineItem.receiptId,
      itemName: lineItem.itemName,
      quantity: lineItem.quantity,
      unitPrice: lineItem.unitPrice,
      totalPrice: lineItem.totalPrice,
      category: lineItem.category,
      lineNumber: lineItem.lineNumber,
    );
  }

  ReceiptsCompanion _mapToCompanion(ReceiptEntity entity) {
    return ReceiptsCompanion(
      id: entity.id != null
          ? drift.Value(entity.id!)
          : const drift.Value.absent(),
      vendorName: drift.Value(entity.vendorName),
      receiptDate: drift.Value(entity.receiptDate),
      totalAmount: drift.Value(entity.totalAmount),
      subtotal: drift.Value(entity.subtotal),
      taxAmount: drift.Value(entity.taxAmount),
      paymentMethod: drift.Value(entity.paymentMethod),
      receiptNumber: drift.Value(entity.receiptNumber),
      category: drift.Value(entity.category),
      imagePath: drift.Value(entity.imagePath),
      ocrText: drift.Value(entity.ocrText),
      llmResponseJson: drift.Value(entity.llmResponseJson),
      createdAt: drift.Value(entity.createdAt),
      updatedAt: drift.Value(entity.updatedAt ?? DateTime.now()),
      isVerified: drift.Value(entity.isVerified),
    );
  }

  LineItemsCompanion _mapLineItemToCompanion(LineItemEntity entity) {
    return LineItemsCompanion(
      id: entity.id != null
          ? drift.Value(entity.id!)
          : const drift.Value.absent(),
      receiptId: entity.receiptId != null
          ? drift.Value(entity.receiptId!)
          : const drift.Value.absent(),
      itemName: drift.Value(entity.itemName),
      quantity: drift.Value(entity.quantity),
      unitPrice: drift.Value(entity.unitPrice),
      totalPrice: drift.Value(entity.totalPrice),
      category: drift.Value(entity.category),
      lineNumber: drift.Value(entity.lineNumber),
    );
  }
}
