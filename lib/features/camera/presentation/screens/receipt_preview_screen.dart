import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../receipt_parsing/domain/models/parsed_receipt.dart';

/// Screen to preview and edit scanned receipt data before saving
class ReceiptPreviewScreen extends StatefulWidget {
  final String imagePath;
  final ParsedReceipt parsedReceipt;
  final double ocrConfidence;
  final String? rawOcrText;

  const ReceiptPreviewScreen({
    super.key,
    required this.imagePath,
    required this.parsedReceipt,
    required this.ocrConfidence,
    this.rawOcrText,
  });

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  late TextEditingController _vendorController;
  late TextEditingController _totalController;
  late TextEditingController _dateController;
  late TextEditingController _categoryController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController(
      text: widget.parsedReceipt.vendorName ?? '',
    );
    _totalController = TextEditingController(
      text: widget.parsedReceipt.total?.toStringAsFixed(2) ?? '',
    );
    _selectedDate = widget.parsedReceipt.date;
    _dateController = TextEditingController(
      text: _selectedDate != null
          ? DateFormat('MM/dd/yyyy').format(_selectedDate!)
          : '',
    );
    _categoryController = TextEditingController(
      text: widget.parsedReceipt.category ?? 'Other',
    );
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _totalController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _showRawText() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raw OCR Text'),
        content: SingleChildScrollView(
          child: SelectableText(
            widget.rawOcrText ?? 'No OCR text available',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _saveReceipt() {
    // TODO: Save to database
    // For now, just return the edited data
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.rawOcrText != null)
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: _showRawText,
              tooltip: 'View Raw OCR Text',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReceipt,
            tooltip: 'Save Receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt image preview
            Container(
              height: 200,
              color: Colors.black,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),

            // Parsing confidence indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _getConfidenceColor(),
              child: Row(
                children: [
                  Icon(
                    _getConfidenceIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getConfidenceMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Parsed data form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Vendor name
                  TextField(
                    controller: _vendorController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor / Store Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total amount
                  TextField(
                    controller: _totalController,
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Additional parsed info (read-only)
                  if (widget.parsedReceipt.subtotal != null ||
                      widget.parsedReceipt.tax != null ||
                      widget.parsedReceipt.paymentMethod != null) ...[
                    Text(
                      'Additional Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            if (widget.parsedReceipt.subtotal != null)
                              _buildInfoRow(
                                'Subtotal',
                                '\$${widget.parsedReceipt.subtotal!.toStringAsFixed(2)}',
                              ),
                            if (widget.parsedReceipt.tax != null)
                              _buildInfoRow(
                                'Tax',
                                '\$${widget.parsedReceipt.tax!.toStringAsFixed(2)}',
                              ),
                            if (widget.parsedReceipt.paymentMethod != null)
                              _buildInfoRow(
                                'Payment',
                                widget.parsedReceipt.paymentMethod!,
                              ),
                            if (widget.parsedReceipt.receiptNumber != null)
                              _buildInfoRow(
                                'Receipt #',
                                widget.parsedReceipt.receiptNumber!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Line items
                  if (widget.parsedReceipt.lineItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Items (${widget.parsedReceipt.lineItems.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.parsedReceipt.lineItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = widget.parsedReceipt.lineItems[index];
                          return ListTile(
                            title: Text(item.name),
                            trailing: Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveReceipt,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Receipt'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    if (widget.parsedReceipt.isComplete) {
      return Colors.green;
    } else if (widget.parsedReceipt.isPartial) {
      return Colors.orange;
    }
    return Colors.red;
  }

  IconData _getConfidenceIcon() {
    if (widget.parsedReceipt.isComplete) {
      return Icons.check_circle;
    } else if (widget.parsedReceipt.isPartial) {
      return Icons.warning;
    }
    return Icons.error;
  }

  String _getConfidenceMessage() {
    if (widget.parsedReceipt.isComplete) {
      return 'All key fields detected';
    } else if (widget.parsedReceipt.isPartial) {
      return 'Some fields need review';
    }
    return 'Please verify all fields';
  }
}
