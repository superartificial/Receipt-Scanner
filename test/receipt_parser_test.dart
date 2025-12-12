import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts_app/features/receipt_parsing/services/improved_receipt_parser.dart';
import 'package:receipts_app/features/receipt_parsing/domain/models/parsed_receipt.dart';

void main() {
  group('ImprovedReceiptParser Tests', () {
    late ImprovedReceiptParser parser;

    setUp(() {
      parser = ImprovedReceiptParser();
    });

    test('1. Restaurant Receipt with Tip', () async {
      final receipt = await _loadReceipt('test_receipts/1_restaurant_with_tip.txt');
      final parsed = parser.parse(receipt);

      print('\n=== Restaurant Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('OLIVE'));
      expect(parsed.total, closeTo(105.84, 0.01), reason: 'Should extract total');
      expect(parsed.subtotal, closeTo(98.92, 0.01), reason: 'Should extract subtotal');
      expect(parsed.tax, closeTo(6.92, 0.01), reason: 'Should extract tax');
      expect(parsed.date, isNotNull, reason: 'Should extract date');
      expect(parsed.paymentMethod, contains('Visa'), reason: 'Should extract payment method');
      expect(parsed.category, equals('Dining'), reason: 'Should categorize as Dining');
      expect(parsed.lineItems.isNotEmpty, true, reason: 'Should extract line items');
    });

    test('2. Gas Station Receipt', () async {
      final receipt = await _loadReceipt('test_receipts/2_gas_station.txt');
      final parsed = parser.parse(receipt);

      print('\n=== Gas Station Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('SHELL'));
      expect(parsed.total, closeTo(73.42, 0.01), reason: 'Should extract total');
      expect(parsed.subtotal, closeTo(68.62, 0.01), reason: 'Should extract subtotal');
      expect(parsed.tax, closeTo(4.80, 0.01), reason: 'Should extract tax');
      expect(parsed.date, isNotNull, reason: 'Should extract date');
      expect(parsed.category, equals('Gas'), reason: 'Should categorize as Gas');
    });

    test('3. UK Tesco Receipt (DD/MM/YYYY format)', () async {
      final receipt = await _loadReceipt('test_receipts/3_uk_tesco.txt');
      final parsed = parser.parse(receipt);

      print('\n=== UK Tesco Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('TESCO'));
      expect(parsed.total, closeTo(14.98, 0.01), reason: 'Should extract total');
      expect(parsed.date, isNotNull, reason: 'Should extract DD/MM/YYYY date');
      expect(parsed.paymentMethod, isNotNull, reason: 'Should extract payment method');
      expect(parsed.category, equals('Groceries'), reason: 'Should categorize as Groceries');
    });

    test('4. CVS Pharmacy Receipt', () async {
      final receipt = await _loadReceipt('test_receipts/4_cvs_pharmacy.txt');
      final parsed = parser.parse(receipt);

      print('\n=== CVS Pharmacy Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('CVS'));
      expect(parsed.total, closeTo(57.29, 0.01), reason: 'Should extract total');
      expect(parsed.subtotal, closeTo(54.45, 0.01), reason: 'Should extract subtotal');
      expect(parsed.tax, closeTo(2.84, 0.01), reason: 'Should extract tax');
      expect(parsed.category, equals('Pharmacy'), reason: 'Should categorize as Pharmacy');
    });

    test('5. Starbucks Coffee Shop Receipt', () async {
      final receipt = await _loadReceipt('test_receipts/5_starbucks.txt');
      final parsed = parser.parse(receipt);

      print('\n=== Starbucks Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('STARBUCKS'));
      expect(parsed.total, closeTo(28.47, 0.01), reason: 'Should extract total');
      expect(parsed.subtotal, closeTo(26.15, 0.01), reason: 'Should extract subtotal');
      expect(parsed.tax, closeTo(2.32, 0.01), reason: 'Should extract tax');
      expect(parsed.category, equals('Dining'), reason: 'Should categorize as Dining');
    });

    test('6. Target Receipt with Discounts', () async {
      final receipt = await _loadReceipt('test_receipts/6_target_with_discounts.txt');
      final parsed = parser.parse(receipt);

      print('\n=== Target Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('TARGET'));
      expect(parsed.total, closeTo(123.50, 0.01), reason: 'Should extract total');
      expect(parsed.subtotal, closeTo(116.95, 0.01), reason: 'Should extract subtotal');
      expect(parsed.tax, closeTo(6.55, 0.01), reason: 'Should extract tax');
      expect(parsed.category, equals('Retail'), reason: 'Should categorize as Retail');
    });

    test('7. Home Depot Receipt', () async {
      final receipt = await _loadReceipt('test_receipts/7_home_depot.txt');
      final parsed = parser.parse(receipt);

      print('\n=== Home Depot Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('HOME DEPOT'));
      expect(parsed.total, closeTo(206.84, 0.01), reason: 'Should extract total');
      expect(parsed.subtotal, closeTo(194.22, 0.01), reason: 'Should extract subtotal');
      expect(parsed.tax, closeTo(12.62, 0.01), reason: 'Should extract tax');
      expect(parsed.category, equals('Retail'), reason: 'Should categorize as Retail');
    });

    test('8. German ALDI Receipt (EUR, German text)', () async {
      final receipt = await _loadReceipt('test_receipts/8_eu_germany_aldi.txt');
      final parsed = parser.parse(receipt);

      print('\n=== German ALDI Receipt ===');
      _printParsedReceipt(parsed);

      expect(parsed.vendorName, isNotNull, reason: 'Should extract vendor name');
      expect(parsed.vendorName?.toUpperCase(), contains('ALDI'));
      expect(parsed.total, closeTo(17.03, 0.01), reason: 'Should extract total');
      expect(parsed.date, isNotNull, reason: 'Should extract DD.MM.YYYY date');
    });

    test('Summary: Overall Parser Performance', () async {
      final receipts = [
        'test_receipts/1_restaurant_with_tip.txt',
        'test_receipts/2_gas_station.txt',
        'test_receipts/3_uk_tesco.txt',
        'test_receipts/4_cvs_pharmacy.txt',
        'test_receipts/5_starbucks.txt',
        'test_receipts/6_target_with_discounts.txt',
        'test_receipts/7_home_depot.txt',
        'test_receipts/8_eu_germany_aldi.txt',
      ];

      var totalTests = 0;
      var vendorSuccess = 0;
      var totalSuccess = 0;
      var dateSuccess = 0;
      var taxSuccess = 0;
      var categorySuccess = 0;

      print('\n\n=== PARSER PERFORMANCE SUMMARY ===\n');

      for (final path in receipts) {
        final receipt = await _loadReceipt(path);
        final parsed = parser.parse(receipt);
        totalTests++;

        if (parsed.vendorName != null) vendorSuccess++;
        if (parsed.total != null) totalSuccess++;
        if (parsed.date != null) dateSuccess++;
        if (parsed.tax != null) taxSuccess++;
        if (parsed.category != null) categorySuccess++;

        print('${path.split('/').last}:');
        print('  Vendor: ${parsed.vendorName ?? "FAILED"}');
        print('  Total: ${parsed.total != null ? "\$${parsed.total!.toStringAsFixed(2)}" : "FAILED"}');
        print('  Date: ${parsed.date != null ? parsed.date.toString().split(' ')[0] : "FAILED"}');
        print('  Tax: ${parsed.tax != null ? "\$${parsed.tax!.toStringAsFixed(2)}" : "FAILED"}');
        print('  Category: ${parsed.category ?? "FAILED"}');
        print('  Line Items: ${parsed.lineItems.length}');
        print('');
      }

      print('OVERALL RESULTS:');
      print('Vendor Detection:  $vendorSuccess/$totalTests (${(vendorSuccess / totalTests * 100).toStringAsFixed(1)}%)');
      print('Total Extraction:  $totalSuccess/$totalTests (${(totalSuccess / totalTests * 100).toStringAsFixed(1)}%)');
      print('Date Extraction:   $dateSuccess/$totalTests (${(dateSuccess / totalTests * 100).toStringAsFixed(1)}%)');
      print('Tax Extraction:    $taxSuccess/$totalTests (${(taxSuccess / totalTests * 100).toStringAsFixed(1)}%)');
      print('Category Inference: $categorySuccess/$totalTests (${(categorySuccess / totalTests * 100).toStringAsFixed(1)}%)');
    });
  });
}

Future<String> _loadReceipt(String path) async {
  final file = File(path);
  return await file.readAsString();
}

void _printParsedReceipt(ParsedReceipt parsed) {
  print('Vendor: ${parsed.vendorName ?? "NOT FOUND"}');
  print('Date: ${parsed.date ?? "NOT FOUND"}');
  print('Total: ${parsed.total != null ? "\$${parsed.total!.toStringAsFixed(2)}" : "NOT FOUND"}');
  print('Subtotal: ${parsed.subtotal != null ? "\$${parsed.subtotal!.toStringAsFixed(2)}" : "NOT FOUND"}');
  print('Tax: ${parsed.tax != null ? "\$${parsed.tax!.toStringAsFixed(2)}" : "NOT FOUND"}');
  print('Payment: ${parsed.paymentMethod ?? "NOT FOUND"}');
  print('Receipt #: ${parsed.receiptNumber ?? "NOT FOUND"}');
  print('Category: ${parsed.category ?? "NOT FOUND"}');
  print('Line Items: ${parsed.lineItems.length}');
  if (parsed.lineItems.isNotEmpty) {
    print('  Items:');
    for (final item in parsed.lineItems.take(3)) {
      print('    - ${item.name}: \$${item.price.toStringAsFixed(2)}');
    }
    if (parsed.lineItems.length > 3) {
      print('    ... and ${parsed.lineItems.length - 3} more');
    }
  }
}
