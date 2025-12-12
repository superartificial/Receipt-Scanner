import 'package:intl/intl.dart';
import '../domain/models/parsed_receipt.dart';

/// Service that parses OCR text from receipts into structured data
/// Uses pattern matching and heuristics to extract information
class ReceiptParser {
  // Common vendor names to look for
  static const _commonVendors = [
    'walmart',
    'target',
    'costco',
    'kroger',
    'safeway',
    'whole foods',
    'trader joe',
    'cvs',
    'walgreens',
    'home depot',
    'lowes',
    'best buy',
    'amazon',
  ];

  /// Parse OCR text into structured receipt data
  ParsedReceipt parse(String ocrText) {
    final lines = ocrText.split('\n').map((l) => l.trim()).toList();

    return ParsedReceipt(
      vendorName: _extractVendor(lines, ocrText),
      date: _extractDate(ocrText),
      total: _extractTotal(ocrText),
      subtotal: _extractSubtotal(ocrText),
      tax: _extractTax(ocrText),
      paymentMethod: _extractPaymentMethod(ocrText),
      receiptNumber: _extractReceiptNumber(ocrText),
      category: _inferCategory(ocrText),
      lineItems: _extractLineItems(lines),
      confidence: 0.0, // Will be calculated based on fields extracted
      rawText: ocrText,
    );
  }

  /// Extract vendor name from receipt text
  String? _extractVendor(List<String> lines, String fullText) {
    final lowerText = fullText.toLowerCase();

    // Check for known vendors
    for (final vendor in _commonVendors) {
      if (lowerText.contains(vendor)) {
        return _capitalize(vendor);
      }
    }

    // Try first non-empty line if it's short and mostly uppercase
    for (final line in lines) {
      if (line.isEmpty) continue;

      if (line.length < 30 && line.length > 2) {
        // Check if it's mostly uppercase or title case
        final uppercaseRatio = line.split('').where((c) => c == c.toUpperCase()).length / line.length;
        if (uppercaseRatio > 0.6) {
          return line;
        }
      }

      // Only check first few non-empty lines
      if (lines.indexOf(line) > 5) break;
    }

    return null;
  }

  /// Extract total amount from receipt
  double? _extractTotal(String text) {
    final patterns = [
      RegExp(r'total[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'amount\s+due[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'balance[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'grand\s+total[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parsePrice(match.group(1)!);
      }
    }

    return null;
  }

  /// Extract subtotal amount
  double? _extractSubtotal(String text) {
    final pattern = RegExp(r'sub[\s-]?total[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match != null) {
      return _parsePrice(match.group(1)!);
    }
    return null;
  }

  /// Extract tax amount
  double? _extractTax(String text) {
    final patterns = [
      RegExp(r'tax[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'sales\s+tax[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'vat[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parsePrice(match.group(1)!);
      }
    }

    return null;
  }

  /// Extract date from receipt
  DateTime? _extractDate(String text) {
    // Common date formats
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'), // YYYY-MM-DD
      RegExp(r'(\w{3,9})\s+(\d{1,2}),?\s+(\d{2,4})'), // Month DD, YYYY
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          // Try different date formats
          final dateStr = match.group(0)!;

          // Try parsing common formats
          for (final format in ['MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd', 'MMM dd, yyyy', 'MMMM dd, yyyy']) {
            try {
              return DateFormat(format).parseLoose(dateStr);
            } catch (_) {
              continue;
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  /// Extract payment method
  String? _extractPaymentMethod(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('visa')) return 'Visa';
    if (lowerText.contains('mastercard') || lowerText.contains('master card')) return 'Mastercard';
    if (lowerText.contains('amex') || lowerText.contains('american express')) return 'American Express';
    if (lowerText.contains('discover')) return 'Discover';
    if (lowerText.contains('cash')) return 'Cash';
    if (lowerText.contains('debit')) return 'Debit Card';
    if (lowerText.contains('credit')) return 'Credit Card';

    return null;
  }

  /// Extract receipt/transaction number
  String? _extractReceiptNumber(String text) {
    final patterns = [
      RegExp(r'receipt\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'trans(?:action)?\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'invoice\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'#\s*(\d{4,})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Infer category based on vendor or items
  String? _inferCategory(String text) {
    final lowerText = text.toLowerCase();

    // Grocery stores
    if (_commonVendors.any((v) => ['walmart', 'kroger', 'safeway', 'whole foods', 'trader joe'].contains(v) && lowerText.contains(v))) {
      return 'Groceries';
    }

    // Restaurants
    if (lowerText.contains('restaurant') || lowerText.contains('cafe') || lowerText.contains('coffee')) {
      return 'Dining';
    }

    // Gas stations
    if (lowerText.contains('gas') || lowerText.contains('fuel') || lowerText.contains('shell') || lowerText.contains('exxon')) {
      return 'Gas';
    }

    // Pharmacies
    if (lowerText.contains('pharmacy') || lowerText.contains('cvs') || lowerText.contains('walgreens')) {
      return 'Pharmacy';
    }

    return 'Other';
  }

  /// Extract line items from receipt
  List<ParsedLineItem> _extractLineItems(List<String> lines) {
    final items = <ParsedLineItem>[];

    // Pattern: item description followed by price
    // Examples: "Milk 2%  $3.99" or "Bread          2.49"
    final itemPattern = RegExp(r'^(.+?)\s{2,}\$?\s*(\d+[.,]\d{2})$');

    for (final line in lines) {
      if (line.isEmpty) continue;

      // Skip lines that look like totals/headers
      if (_isTotalLine(line) || _isHeaderLine(line)) continue;

      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final priceStr = match.group(2)!;
        final price = _parsePrice(priceStr);

        if (price != null && name.length > 2 && name.length < 100) {
          items.add(ParsedLineItem(
            name: name,
            price: price,
          ));
        }
      }
    }

    return items;
  }

  /// Check if line is a total/summary line
  bool _isTotalLine(String line) {
    final lowerLine = line.toLowerCase();
    final skipWords = [
      'total',
      'subtotal',
      'sub total',
      'tax',
      'amount',
      'balance',
      'due',
      'change',
      'tender',
      'payment',
    ];

    return skipWords.any((word) => lowerLine.contains(word));
  }

  /// Check if line is a header/non-item line
  bool _isHeaderLine(String line) {
    final lowerLine = line.toLowerCase();
    final headerWords = [
      'store',
      'receipt',
      'thank you',
      'visit',
      'cashier',
      'register',
      'transaction',
      'date',
      'time',
    ];

    return headerWords.any((word) => lowerLine.contains(word));
  }

  /// Parse price string to double
  double? _parsePrice(String priceStr) {
    try {
      // Replace comma with period for European format
      final normalized = priceStr.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// Capitalize first letter of each word
  String _capitalize(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
