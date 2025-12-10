import 'package:equatable/equatable.dart';

class ReceiptEntity extends Equatable {
  final int? id;
  final String? vendorName;
  final DateTime? receiptDate;
  final double? totalAmount;
  final double? subtotal;
  final double? taxAmount;
  final String? paymentMethod;
  final String? receiptNumber;
  final String? category;
  final String imagePath;
  final String ocrText;
  final String llmResponseJson;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final List<LineItemEntity>? lineItems;

  const ReceiptEntity({
    this.id,
    this.vendorName,
    this.receiptDate,
    this.totalAmount,
    this.subtotal,
    this.taxAmount,
    this.paymentMethod,
    this.receiptNumber,
    this.category,
    required this.imagePath,
    required this.ocrText,
    required this.llmResponseJson,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.lineItems,
  });

  @override
  List<Object?> get props => [
        id,
        vendorName,
        receiptDate,
        totalAmount,
        subtotal,
        taxAmount,
        paymentMethod,
        receiptNumber,
        category,
        imagePath,
        ocrText,
        llmResponseJson,
        createdAt,
        updatedAt,
        isVerified,
        lineItems,
      ];

  ReceiptEntity copyWith({
    int? id,
    String? vendorName,
    DateTime? receiptDate,
    double? totalAmount,
    double? subtotal,
    double? taxAmount,
    String? paymentMethod,
    String? receiptNumber,
    String? category,
    String? imagePath,
    String? ocrText,
    String? llmResponseJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    List<LineItemEntity>? lineItems,
  }) {
    return ReceiptEntity(
      id: id ?? this.id,
      vendorName: vendorName ?? this.vendorName,
      receiptDate: receiptDate ?? this.receiptDate,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      ocrText: ocrText ?? this.ocrText,
      llmResponseJson: llmResponseJson ?? this.llmResponseJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}

class LineItemEntity extends Equatable {
  final int? id;
  final int? receiptId;
  final String itemName;
  final double? quantity;
  final double? unitPrice;
  final double totalPrice;
  final String? category;
  final int? lineNumber;

  const LineItemEntity({
    this.id,
    this.receiptId,
    required this.itemName,
    this.quantity,
    this.unitPrice,
    required this.totalPrice,
    this.category,
    this.lineNumber,
  });

  @override
  List<Object?> get props => [
        id,
        receiptId,
        itemName,
        quantity,
        unitPrice,
        totalPrice,
        category,
        lineNumber,
      ];

  LineItemEntity copyWith({
    int? id,
    int? receiptId,
    String? itemName,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? category,
    int? lineNumber,
  }) {
    return LineItemEntity(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      category: category ?? this.category,
      lineNumber: lineNumber ?? this.lineNumber,
    );
  }
}
