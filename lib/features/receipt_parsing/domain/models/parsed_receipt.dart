import 'package:equatable/equatable.dart';

/// Model representing a parsed receipt with extracted data
class ParsedReceipt extends Equatable {
  final String? vendorName;
  final DateTime? date;
  final double? total;
  final double? subtotal;
  final double? tax;
  final String? paymentMethod;
  final String? receiptNumber;
  final String? category;
  final List<ParsedLineItem> lineItems;
  final double confidence;
  final String rawText;

  const ParsedReceipt({
    this.vendorName,
    this.date,
    this.total,
    this.subtotal,
    this.tax,
    this.paymentMethod,
    this.receiptNumber,
    this.category,
    this.lineItems = const [],
    this.confidence = 0.0,
    required this.rawText,
  });

  /// Returns true if all critical fields were successfully extracted
  bool get isComplete {
    return vendorName != null &&
           date != null &&
           total != null &&
           confidence > 0.5;
  }

  /// Returns true if parsing was partially successful
  bool get isPartial {
    return vendorName != null ||
           date != null ||
           total != null;
  }

  @override
  List<Object?> get props => [
        vendorName,
        date,
        total,
        subtotal,
        tax,
        paymentMethod,
        receiptNumber,
        category,
        lineItems,
        confidence,
        rawText,
      ];

  ParsedReceipt copyWith({
    String? vendorName,
    DateTime? date,
    double? total,
    double? subtotal,
    double? tax,
    String? paymentMethod,
    String? receiptNumber,
    String? category,
    List<ParsedLineItem>? lineItems,
    double? confidence,
    String? rawText,
  }) {
    return ParsedReceipt(
      vendorName: vendorName ?? this.vendorName,
      date: date ?? this.date,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      category: category ?? this.category,
      lineItems: lineItems ?? this.lineItems,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
    );
  }
}

/// Model representing a single line item on a receipt
class ParsedLineItem extends Equatable {
  final String name;
  final double? quantity;
  final double? unitPrice;
  final double price;
  final String? category;

  const ParsedLineItem({
    required this.name,
    this.quantity,
    this.unitPrice,
    required this.price,
    this.category,
  });

  @override
  List<Object?> get props => [
        name,
        quantity,
        unitPrice,
        price,
        category,
      ];

  ParsedLineItem copyWith({
    String? name,
    double? quantity,
    double? unitPrice,
    double? price,
    String? category,
  }) {
    return ParsedLineItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }
}
