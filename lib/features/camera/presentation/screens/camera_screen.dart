import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../ocr/services/text_recognition_service.dart';
import '../../../receipt_parsing/services/improved_receipt_parser.dart';
import 'receipt_preview_screen.dart';

/// Screen for capturing receipt images and processing them
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognitionService _ocrService = TextRecognitionService();
  final ImprovedReceiptParser _parser = ImprovedReceiptParser();

  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    // Check camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _statusMessage = 'Camera permission denied';
      });
      return;
    }

    // Capture image
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      await _processImage(image.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      await _processImage(image.path);
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing receipt...';
    });

    try {
      // Step 1: OCR - Extract text from image
      setState(() => _statusMessage = 'Reading text...');
      final ocrResult = await _ocrService.extractTextWithDetails(imagePath);

      // Step 2: Parse - Extract structured data
      setState(() => _statusMessage = 'Parsing receipt data...');
      final parsedReceipt = _parser.parse(ocrResult.text);

      // Step 3: Navigate to preview/edit screen
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPreviewScreen(
              imagePath: imagePath,
              parsedReceipt: parsedReceipt,
              ocrConfidence: ocrResult.confidence,
              rawOcrText: ocrResult.text,
            ),
          ),
        );

        // If saved, go back to home
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage ?? 'Processing...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'Scan a Receipt',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Take a photo or select from gallery',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _captureFromCamera,
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text(
                        'Take Photo',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(200, 56),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library, size: 28),
                      label: const Text(
                        'Choose from Gallery',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(200, 56),
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
