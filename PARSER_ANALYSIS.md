# Receipt Parser Analysis & Improvement Plan

## Test Results Summary (8 Diverse Receipts)

### Overall Performance
- ✅ **Vendor Detection:** 8/8 (100.0%)
- ✅ **Date Extraction:** 7/8 (87.5%)
- ⚠️ **Total Extraction:** 7/8 (87.5%) - *but often extracts subtotal instead*
- ❌ **Tax Extraction:** 1/8 (12.5%) - **CRITICAL ISSUE**
- ✅ **Category Inference:** 8/8 (100.0%)

---

## Critical Issues Found

### 1. Tax Extraction Failing (12.5% success rate)

**Problem:** Tax patterns not matching common formats

**Examples of Missed Patterns:**
- `Tax (7%)                $6.92` - Restaurant
- `Tax (8.875%)            $2.32` - Starbucks
- `Sales Tax (6.5%)       $12.62` - Home Depot
- `Tax 5.6%                $6.55` - Target
- `MwSt.` - German tax (Mehrwertsteuer)

**Current Pattern:**
```dart
RegExp(r'(?:sales?\s+)?tax[\s:]*\$?\s*(\d+[.,]\d{2})', caseSensitive: false)
```

**Issue:** Doesn't handle tax patterns with percentage in parentheses

---

### 2. Total vs Subtotal Confusion (87.5% extract wrong value)

**Problem:** Parser extracts SUBTOTAL when looking for TOTAL

**Examples:**
- Restaurant: Found $98.92 (subtotal) instead of $105.84 (total)
- Gas Station: Found $56.62 (fuel total) instead of $73.42 (total)
- Starbucks: Found $26.15 (subtotal) instead of $28.47 (total)
- Target: Found $116.95 (subtotal) instead of $123.50 (total)
- Home Depot: Found $194.22 (subtotal) instead of $206.84 (total)

**Root Cause:**
- Current logic uses "last price in bottom 20%" as fallback
- SUBTOTAL appears before TOTAL, and is often the larger section
- Need to prioritize "TOTAL" keyword match over position-based extraction

---

### 3. International Format Support

#### Currency Symbols
- ✅ US Dollar ($) - Works
- ❌ British Pound (£) - **NOT RECOGNIZED**
- ❌ Euro (EUR, €) - **NOT RECOGNIZED**

**UK Tesco Example:** Total £14.98 not found at all

#### Date Formats
- ✅ MM/DD/YYYY - Works
- ✅ DD/MM/YYYY - Works (15/11/2024 parsed correctly)
- ❌ DD.MM.YYYY - **FAILS** (18.11.2024 not recognized in German receipt)

**German ALDI:** Date field shows `Datum: 18.11.2024` but parser returns null

---

### 4. Vendor Name Extraction Issues

**CVS Receipt:**
- Expected: "CVS" or "CVS Pharmacy"
- Actual: "Store 09845"

**Issue:** First prominent line was "CVS/pharmacy" but parser picked up "Store #09845" instead

---

### 5. Category Classification Issues

**Starbucks Receipt:**
- Expected: "Dining" (coffee shop = restaurant category)
- Actual: "Groceries"

**Issue:** Pattern matching for "coffee" found, but categorized as grocery instead of dining

---

## Edge Cases Discovered

### 1. Tax Format Variations
- `Tax (7%)` - Percentage in parentheses
- `Tax 7%` - Percentage without parentheses
- `Sales Tax` vs `Tax` vs `VAT` vs `GST` vs `HST` vs `MwSt.`
- Tax shown as: `A= 7%   14,51    1,02   15,53` (German itemized format)

### 2. Total/Subtotal Context Clues
- "TOTAL" appears after "SUBTOTAL"
- Sometimes labeled as:
  - `TOTAL`
  - `GRAND TOTAL`
  - `AMOUNT DUE`
  - `BALANCE`
  - `SUMME` (German)
- Subtotal often larger numeric section with more items

### 3. Suggested Gratuity (Tips)
- Not actual totals, but can be misidentified
- Example: `18%    $19.05` on restaurant receipts
- Should be ignored in total extraction

### 4. Multiple Price Columns
**Gas Station:**
```
Gallons: 14.523 gal
Price/Gal: $3.899
Fuel Total: $56.62    <- Not the receipt total
```

### 5. Discounts & Coupons
- Negative values: `-$2.00`, `-$5.00`
- Can affect subtotal/total calculations
- "TOTAL SAVINGS" section separate from main total

### 6. Line Item Complexity
**Modifiers/Add-ons:**
```
Grande Latte            $5.45
  +Oat Milk             $0.70
  +Extra Shot           $0.90
```
Currently parsed as 3 separate items instead of 1 item with modifiers

**Quantity Pricing:**
```
2x4x8 Lumber (6)         $4.97 ea
                        $29.82
```
Parser misses quantity multiplier

---

## Improvement Priorities

### Priority 1: Fix Tax Extraction (Critical)
- [ ] Add pattern for `Tax (X%)`
- [ ] Add pattern for `Tax X%`
- [ ] Add German `MwSt.` pattern
- [ ] Add international variants (VAT, GST, HST)

### Priority 2: Fix Total vs Subtotal Logic
- [ ] Prioritize explicit "TOTAL" keyword over position
- [ ] Add "GRAND TOTAL", "AMOUNT DUE" patterns
- [ ] Ensure TOTAL trumps SUBTOTAL when both present
- [ ] Add German "SUMME" pattern

### Priority 3: International Support
- [ ] Add £, €, EUR currency symbol support
- [ ] Add DD.MM.YYYY date format (dots as separators)
- [ ] Add German/European date parsing
- [ ] Add comma as decimal separator (European format)

### Priority 4: Vendor Name Accuracy
- [ ] Better handling of vendor/business name vs store number
- [ ] Prioritize brand name over store ID

### Priority 5: Category Improvements
- [ ] Move coffee shops to "Dining" instead of "Groceries"
- [ ] Add hardware store category detection

### Priority 6: Line Item Enhancements
- [ ] Handle item modifiers (+Oat Milk, +Extra Shot)
- [ ] Parse quantity indicators (x2, (6), etc.)
- [ ] Handle multi-line pricing (ea vs total)

---

## Test Coverage Achieved

### Receipt Types Tested
1. ✅ Restaurant (with tips/gratuity)
2. ✅ Gas Station (with volume/unit pricing)
3. ✅ UK Grocery (DD/MM/YYYY, £ currency)
4. ✅ Pharmacy (coupons, rewards, prescriptions)
5. ✅ Coffee Shop (modifiers, add-ons)
6. ✅ Retail with Discounts (multiple discount types)
7. ✅ Hardware Store (quantity pricing, SKUs)
8. ✅ German/EU Receipt (different language, EUR, DD.MM.YYYY)

### Format Variations Tested
- Multiple date formats (MM/DD/YYYY, DD/MM/YYYY, DD.MM.YYYY)
- Multiple currency symbols ($, £, EUR)
- Different tax representations
- Discount handling
- Suggested gratuity
- Loyalty programs (CVS ExtraBucks, Target Circle, Tesco Clubcard)
- Multiple payment types (Visa, Mastercard, Debit, Contactless)

---

## Next Steps

1. **Implement Priority 1-3 fixes** to improve parser accuracy from 87.5% to 95%+
2. **Re-run test suite** to validate improvements
3. **Add more edge case receipts** (Asian markets, online receipts, handwritten receipts)
4. **Create visual parser debugger** to help identify parsing issues in production
5. **Add confidence scoring** based on successful field extraction
