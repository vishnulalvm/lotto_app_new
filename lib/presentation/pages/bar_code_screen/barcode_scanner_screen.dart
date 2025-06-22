import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
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
      helpText: 'select_date'.tr(),
      cancelText: 'cancel'.tr(),
      confirmText: 'confirm'.tr(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Reset scanner state when date changes
        lastScannedCode = null;
        isProcessing = false;
      });
      
      // Restart the scanner to enable scanning again with new date
      await _restartScanner();
      
      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('date_updated_scanner_ready'.tr()),
            backgroundColor: Theme.of(context).primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _restartScanner() async {
    try {
      // Stop the current scanner
      await cameraController.stop();
      // Small delay to ensure camera is properly stopped
      await Future.delayed(const Duration(milliseconds: 300));
      // Start the scanner again
      await cameraController.start();
    } catch (e) {
      debugPrint('Error restarting scanner: $e');
      // If restart fails, try to dispose and recreate the controller
      try {
        cameraController.dispose();
        cameraController = MobileScannerController();
      } catch (e) {
        debugPrint('Error recreating scanner controller: $e');
      }
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
          'barcode_scanner'.tr(),
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
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'processing'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Instruction text
                if (!isProcessing)
                  Positioned(
                    bottom: 100,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'scan_instruction'.tr(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
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
                      icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                      label: 'flash'.tr(),
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
                      label: 'gallery'.tr(),
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
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
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
              DateFormat('dd-MM-yyyy').format(selectedDate),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: theme.primaryColor,
              size: 20,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive 
                    ? theme.primaryColor.withValues(alpha: 0.2)
                    : theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: isActive 
                    ? Border.all(color: theme.primaryColor, width: 2)
                    : null,
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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        debugPrint('Image picked from gallery: ${image.path}');
        
        // Show processing state
        setState(() {
          isProcessing = true;
        });
        
        // Simulate processing time
        await Future.delayed(const Duration(seconds: 1));
        
        setState(() {
          isProcessing = false;
        });
        
        // Show info dialog
        _showGalleryInfoDialog();
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gallery_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGalleryInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('gallery_scan'.tr()),
          content: Text('gallery_scan_info'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ok'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _handleScannedBarcode(String barcodeValue) async {
    if (isProcessing) return;

    // Check if this is the same code that was just scanned
    if (barcodeValue == lastScannedCode) {
      return; // Ignore duplicate scans
    }

    setState(() {
      isProcessing = true;
      lastScannedCode = barcodeValue;
    });

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Validate barcode format
    if (!BarcodeValidator.isValidLotteryTicket(barcodeValue)) {
      setState(() {
        isProcessing = false;
        // Don't reset lastScannedCode here so user can change date and try again
      });
      
      _showValidationErrorDialog(BarcodeValidator.getValidationError(barcodeValue));
      return;
    }

    // Format date for API
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    // Navigate to scratch card with ticket data
    final ticketData = {
      'ticketNumber': BarcodeValidator.cleanTicketNumber(barcodeValue),
      'date': formattedDate,
      'phoneNumber': '62389700', // You might want to get this from user input
    };

    setState(() {
      isProcessing = false;
    });

    if (mounted) {
      context.push('/result/scratch', extra: ticketData);
    }
  }

  void _showValidationErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('invalid_barcode'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                Text(
                  'scan_proper_ticket'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                // Barcode example image with red border
                Center(
                  child: Column(
                    children: [
                      Text(
                        'barcode_example'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/images/lottery_barcode.png',
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 80,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    Text(
                                      'Barcode Example',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'scan_this_area'.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${'valid_format'.tr()}: RP133796',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'change_date_to_rescan'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ok'.tr()),
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