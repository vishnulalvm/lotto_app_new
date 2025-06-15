import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/core/utils/barcode_validator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  DateTime selectedDate = DateTime.now();
  String? lastScannedCode;
  bool isProcessing = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Barcode Scanner',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanner
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (isProcessing) return;
                    
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final scannedValue = barcode.rawValue ?? '';
                      if (scannedValue.isNotEmpty && scannedValue != lastScannedCode) {
                        _handleScannedBarcode(scannedValue);
                        break;
                      }
                    }
                  },
                ),
                // Overlay
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.primaryColor,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 200,
                ),
                // Loading indicator
                if (isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                // Instruction text
                if (!isProcessing)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Scan Barcode in Lottery for Get your Result',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.cardTheme.color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date chooser button
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: _buildDateChooserButton(context, theme),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.flash_on,
                      label: 'Flash',
                      isActive: isFlashOn,
                      onTap: () {
                        setState(() {
                          isFlashOn = !isFlashOn;
                          cameraController.toggleTorch();
                        });
                      },
                      theme: theme,
                    ),
                    _buildActionButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: _pickImageFromGallery,
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChooserButton(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: isProcessing ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? theme.primaryColor : theme.iconTheme.color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      debugPrint('Image picked from gallery: ${image.path}');
      // You can implement image-based barcode scanning here
    }
  }

  void _handleScannedBarcode(String barcodeValue) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      lastScannedCode = barcodeValue;
    });

    // Validate barcode format
    if (!BarcodeValidator.isValidLotteryTicket(barcodeValue)) {
      setState(() {
        isProcessing = false;
      });
      
      _showValidationErrorDialog(BarcodeValidator.getValidationError(barcodeValue));
      return;
    }

    // Format date for API
    final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    // Navigate to scratch card with ticket data
    final ticketData = {
      'ticketNumber': BarcodeValidator.cleanTicketNumber(barcodeValue),
      'date': formattedDate,
      'phoneNumber': '62389700', // You might want to get this from user input
    };

    setState(() {
      isProcessing = false;
    });

    context.push('/result/scratch', extra: ticketData);
  }

  void _showValidationErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Barcode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              const SizedBox(height: 16),
              const Text(
                'Please scan a proper lottery ticket barcode.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Valid format: RP133796',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}