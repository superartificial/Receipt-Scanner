import 'package:intl/intl.dart';
import '../domain/models/parsed_receipt.dart';

/// Enhanced universal receipt parser using intelligent heuristics
/// Works with receipts from any vendor, country, or format
class ImprovedReceiptParser {
  /// Parse OCR text into structured receipt data
  ParsedReceipt parse(String ocrText) {
    final lines = _preprocessText(ocrText);

    // Extract all possible prices first
    final allPrices = _extractAllPrices(ocrText);

    return ParsedReceipt(
      vendorName: _extractVendorSmart(lines),
      date: _extractDateSmart(ocrText),
      total: _extractTotalSmart(ocrText, allPrices),
      subtotal: _extractSubtotal(ocrText, allPrices),
      tax: _extractTax(ocrText),
      paymentMethod: _extractPaymentMethod(ocrText),
      receiptNumber: _extractReceiptNumber(ocrText),
      category: _inferCategorySmart(ocrText),
      lineItems: _extractLineItemsSmart(lines),
      confidence: 0.0,
      rawText: ocrText,
    );
  }

  /// Preprocess text into clean lines
  List<String> _preprocessText(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Extract vendor using intelligent heuristics
  String? _extractVendorSmart(List<String> lines) {
    if (lines.isEmpty) return null;

    // Strategy 0: Check for well-known brand patterns first (highest priority)
    final brandPatterns = [
      RegExp(r'CVS/?pharmacy', caseSensitive: false),
      RegExp(r'Walgreens', caseSensitive: false),
      RegExp(r'Walmart', caseSensitive: false),
      RegExp(r'Target', caseSensitive: false),
      RegExp(r'Starbucks', caseSensitive: false),
      RegExp(r'Home\s+Depot', caseSensitive: false),
      RegExp(r'Tesco', caseSensitive: false),
      RegExp(r'Aldi', caseSensitive: false),
    ];

    for (final line in lines.take(5)) {
      for (final pattern in brandPatterns) {
        if (pattern.hasMatch(line)) {
          return _cleanVendorName(line);
        }
      }
    }

    // Strategy 1: First few lines that look like business names
    for (int i = 0; i < lines.length.min(8); i++) {
      final line = lines[i];

      // Skip if it looks like an address or phone
      if (_looksLikeAddress(line) || _looksLikePhone(line)) continue;

      // Skip if it contains state/zip pattern (city, state zip)
      if (RegExp(r',\s+[A-Z]{2}\s+\d{5}').hasMatch(line)) continue;

      // Skip if it's too long (likely not a business name)
      if (line.length > 40) continue;

      // Skip if it's all numbers
      if (RegExp(r'^\d+$').hasMatch(line)) continue;

      // Skip if it looks like a store number (e.g., "Store #1234", "Store 09845")
      if (RegExp(r'^store\s*#?\s*\d+', caseSensitive: false).hasMatch(line)) continue;

      // Skip if it's mostly numbers (like T-2847, #8472)
      final letterCount = line.split('').where((c) => RegExp(r'[a-zA-Z]').hasMatch(c)).length;
      final digitCount = line.split('').where((c) => RegExp(r'\d').hasMatch(c)).length;
      if (digitCount > letterCount) continue;

      // Good candidate if:
      // - Mostly uppercase or title case
      // - Between 3-40 characters
      // - Contains letters
      if (line.length >= 3 &&
          line.length <= 40 &&
          RegExp(r'[a-zA-Z]{3,}').hasMatch(line)) {

        // Calculate uppercase ratio from letters only (ignore special chars like /)
        final letters = line.split('').where((c) => RegExp(r'[a-zA-Z]').hasMatch(c)).toList();
        if (letters.isEmpty) continue;

        final upperCount = letters.where((c) => c == c.toUpperCase()).length;
        final upperRatio = upperCount / letters.length;

        if (upperRatio > 0.5) {
          return _cleanVendorName(line);
        }
      }
    }

    // Strategy 2: Look for common business suffixes
    for (final line in lines.take(10)) {
      if (RegExp(r'\b(LLC|Inc|Corp|Ltd|Co|Store|Market|Shop)\b', caseSensitive: false).hasMatch(line)) {
        return _cleanVendorName(line);
      }
    }

    return null;
  }

  /// Extract total using multiple strategies
  double? _extractTotalSmart(String text, List<double> allPrices) {
    // Strategy 1: Look for explicit "TOTAL" keyword (most reliable)
    // IMPORTANT: Must NOT match "SUBTOTAL" or "SUB TOTAL"
    final totalPatterns = [
      // Match TOTAL but not SUBTOTAL (negative lookbehind)
      RegExp(r'(?<!sub[\s-]?)(?<!sub)(?:grand\s+)?total[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'\btotal[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'amount\s+due[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'balance[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'total\s+amount[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'net\s+total[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      // German: SUMME
      RegExp(r'summe[\s:]*(?:EUR|€|[$£])?\s*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    // First pass: Try to find TOTAL keyword (prioritize this over position-based)
    for (final pattern in totalPatterns) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        // Get the LAST match (in case there are multiple totals, the last is usually correct)
        final match = matches.last;
        final priceStr = match.group(1);
        if (priceStr != null) {
          // Verify this is not in a "subtotal" line
          final lineStart = text.lastIndexOf('\n', match.start);
          final lineEnd = text.indexOf('\n', match.start);
          final fullLine = text.substring(
            lineStart == -1 ? 0 : lineStart,
            lineEnd == -1 ? text.length : lineEnd
          ).toLowerCase();

          // Skip if line contains "subtotal" or "sub total"
          if (fullLine.contains('subtotal') || fullLine.contains('sub total')) {
            continue;
          }

          return _parsePrice(priceStr);
        }
      }
    }

    // Strategy 2: Total is often the last or second-to-last price
    if (allPrices.isNotEmpty) {
      // Get prices from last 20% of text (where totals usually are)
      final textLines = text.split('\n');
      final lastSection = textLines.skip(textLines.length - (textLines.length * 0.2).ceil()).join('\n');
      final lastPrices = _extractAllPrices(lastSection);

      if (lastPrices.isNotEmpty) {
        // Return largest price in last section
        return lastPrices.reduce((a, b) => a > b ? a : b);
      }
    }

    return null;
  }

  /// Extract subtotal
  double? _extractSubtotal(String text, List<double> allPrices) {
    final patterns = [
      RegExp(r'sub[\s-]?total[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'subtotal[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parsePrice(match.group(1)!);
      }
    }
    return null;
  }

  /// Extract tax
  double? _extractTax(String text) {
    final patterns = [
      // Tax with percentage in parentheses: "Tax (7%)  $6.92"
      RegExp(r'(?:sales?\s+)?tax\s*\([^)]*\)[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      // Tax with percentage: "Tax 7%  $6.92"
      RegExp(r'(?:sales?\s+)?tax\s+\d+\.?\d*%[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      // Standard tax patterns
      RegExp(r'(?:sales?\s+)?tax[\s:]+[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'vat[\s:@]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'gst[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'hst[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'mwst\.?[\s:]*[$£€]?\s*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parsePrice(match.group(1)!);
      }
    }
    return null;
  }

  /// Extract date with multiple format support
  DateTime? _extractDateSmart(String text) {
    // Common date patterns including European format with dots (DD.MM.YYYY)
    final patterns = [
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})'),  // Handles /, -, and . separators
      RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{2,4})', caseSensitive: false),
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        try {
          final dateStr = match.group(0)!;

          // Try multiple date formats including European variants
          final formats = [
            'MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd',
            'M/d/yyyy', 'd/M/yyyy', 'yyyy/MM/dd',
            'dd.MM.yyyy', 'd.M.yyyy', 'MM.dd.yyyy',  // European with dots
            'dd-MM-yyyy', 'd-M-yyyy', 'MM-dd-yyyy',  // With dashes
            'dd MMM yyyy', 'MMM dd, yyyy', 'd MMM yyyy',
            'dd MMMM yyyy', 'MMMM dd, yyyy',
          ];

          for (final format in formats) {
            try {
              final parsed = DateFormat(format).parseLoose(dateStr);
              // Sanity check: date should be between 2000 and now
              if (parsed.year >= 2000 && parsed.year <= DateTime.now().year) {
                return parsed;
              }
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

    final methods = {
      'visa': 'Visa',
      'mastercard': 'Mastercard',
      'master card': 'Mastercard',
      'amex': 'American Express',
      'american express': 'American Express',
      'discover': 'Discover',
      'cash': 'Cash',
      'debit': 'Debit Card',
      'credit': 'Credit Card',
      'card': 'Card',
    };

    for (final entry in methods.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Extract receipt/transaction number
  String? _extractReceiptNumber(String text) {
    final patterns = [
      RegExp(r'receipt\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'trans(?:action)?[\s#]*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'invoice\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'order\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'ref(?:erence)?\s*#?\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Infer category from content
  String? _inferCategorySmart(String text) {
    final lowerText = text.toLowerCase();

    // Check specific brands first (most specific to least specific)

    // Coffee shops / Cafes (check before groceries since they may have food items)
    if (RegExp(r'\b(starbucks|cafe|coffee\s+shop|coffee\s+house|barista|latte|espresso|cappuccino)\b').hasMatch(lowerText)) {
      return 'Dining';
    }

    // Restaurants (check before groceries)
    if (RegExp(r'\b(restaurant|dining|bistro|grill|eatery|menu|server|table|waiter|gratuity|tip)\b').hasMatch(lowerText)) {
      return 'Dining';
    }

    // Gas stations (be specific to avoid false positives on "gallon" in grocery items)
    if (RegExp(r'\b(gas\s+station|fuel|price/gal|shell|exxon|chevron|bp\b|mobil|unleaded|diesel|pump\s*\d)\b').hasMatch(lowerText)) {
      return 'Gas';
    }

    // Pharmacy/Health
    if (RegExp(r'\b(pharmacy|drug|prescription|rx|medicine|cvs|walgreens|rite\s+aid)\b').hasMatch(lowerText)) {
      return 'Pharmacy';
    }

    // Multi-department retailers (Target, Walmart) - categorize as Retail even if they have grocery sections
    if (RegExp(r'\b(target|walmart)\b').hasMatch(lowerText) &&
        RegExp(r'\b(home\s+depot|lowes)\b').hasMatch(lowerText) == false) {
      return 'Retail';
    }

    // Pure grocery stores (check after multi-department retailers)
    if (RegExp(r'\b(grocery|supermarket|tesco|aldi|kroger|safeway)\b').hasMatch(lowerText)) {
      return 'Groceries';
    }

    // Hardware/Home improvement
    if (RegExp(r'\b(home\s+depot|lowes|hardware)\b').hasMatch(lowerText)) {
      return 'Retail';
    }

    // General retail
    if (RegExp(r'\b(retail|mall|store)\b').hasMatch(lowerText)) {
      return 'Retail';
    }

    return 'Other';
  }

  /// Extract line items using smart heuristics
  List<ParsedLineItem> _extractLineItemsSmart(List<String> lines) {
    final items = <ParsedLineItem>[];

    // Find the section with items (between header and totals)
    int startIdx = 0;
    int endIdx = lines.length;

    // Skip header (first few lines)
    for (int i = 0; i < lines.length.min(5); i++) {
      if (_looksLikeItemLine(lines[i])) {
        startIdx = i;
        break;
      }
    }

    // Find where totals start (from bottom)
    for (int i = lines.length - 1; i >= 0; i--) {
      if (_looksLikeTotalLine(lines[i])) {
        endIdx = i;
        break;
      }
    }

    // Extract items from the middle section
    for (int i = startIdx; i < endIdx; i++) {
      final line = lines[i];

      if (_looksLikeItemLine(line) && !_looksLikeTotalLine(line)) {
        final item = _parseItemLine(line);
        if (item != null) {
          items.add(item);
        }
      }
    }

    return items;
  }

  /// Check if line looks like an item line
  bool _looksLikeItemLine(String line) {
    // Has a price pattern and some text
    return RegExp(r'[a-zA-Z]{2,}.*?\d+[.,]\d{2}').hasMatch(line) &&
           !_looksLikeTotalLine(line);
  }

  /// Parse a single item line
  ParsedLineItem? _parseItemLine(String line) {
    // Pattern: Text followed by price
    // Examples:
    // "Milk 2%        $3.99"
    // "Bread          £2.49"
    // "Coffee  €1.99"

    final match = RegExp(r'^(.+?)\s{2,}[$£€]?\s*(\d+[.,]\d{2})$').firstMatch(line);
    if (match != null) {
      final name = match.group(1)!.trim();
      final price = _parsePrice(match.group(2)!);

      if (price != null && name.length > 1 && name.length < 100) {
        return ParsedLineItem(name: name, price: price);
      }
    }

    // Alternative pattern: Price at end with less spacing
    final match2 = RegExp(r'^(.+?)\s+[$£€]?\s*(\d+[.,]\d{2})$').firstMatch(line);
    if (match2 != null) {
      final name = match2.group(1)!.trim();
      final price = _parsePrice(match2.group(2)!);

      if (price != null && name.length > 2 && name.length < 100 && !_containsTotalKeyword(name)) {
        return ParsedLineItem(name: name, price: price);
      }
    }

    return null;
  }

  /// Extract all prices from text for analysis
  List<double> _extractAllPrices(String text) {
    final prices = <double>[];
    // Support multiple currency symbols: $, £, €, and EUR
    final pattern = RegExp(r'[$£€]?\s*(\d+[.,]\d{2})');

    for (final match in pattern.allMatches(text)) {
      final price = _parsePrice(match.group(1)!);
      if (price != null && price > 0 && price < 10000) {
        prices.add(price);
      }
    }

    return prices;
  }

  /// Check if line contains total-related keywords
  bool _looksLikeTotalLine(String line) {
    final lowerLine = line.toLowerCase();
    return RegExp(r'\b(total|subtotal|sub total|tax|amount|balance|due|change|tender|payment)\b')
        .hasMatch(lowerLine);
  }

  bool _containsTotalKeyword(String text) {
    return _looksLikeTotalLine(text);
  }

  bool _looksLikeAddress(String line) {
    return RegExp(r'\d+\s+\w+\s+(st|street|ave|avenue|rd|road|blvd|boulevard|dr|drive|ln|lane)', caseSensitive: false)
        .hasMatch(line);
  }

  bool _looksLikePhone(String line) {
    return RegExp(r'\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}').hasMatch(line);
  }

  String _cleanVendorName(String name) {
    // Remove common noise
    return name
        .replaceAll(RegExp(r'[#*]+'), '')
        .trim()
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  double? _parsePrice(String priceStr) {
    try {
      final normalized = priceStr.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }
}

extension on int {
  int min(int other) => this < other ? this : other;
}
