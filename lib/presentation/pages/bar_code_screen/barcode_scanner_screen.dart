import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/barcode_validator.dart';
import 'package:lotto_app/presentation/pages/bar_code_screen/widgets/validation_error_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  DateTime selectedDate = DateTime.now();
  String? lastScannedCode;
  bool isProcessing = false;
  bool _isNavigatingAway = false;

  @override
  void initState() {
    super.initState();
    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // Resume camera when app comes back to foreground
        if (mounted && !_isNavigatingAway) {
          _restartCameraIfNeeded();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Stop camera when app goes to background (but not when navigating)
        if (!_isNavigatingAway) {
          cameraController.stop();
        }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        // Stop camera when app is hidden
        cameraController.stop();
        break;
    }
  }

  Future<void> _restartCameraIfNeeded() async {
    try {
      // Check if camera is already running
      if (!cameraController.value.isRunning) {
        await cameraController.start();
        // Reset states when camera restarts
        setState(() {
          isProcessing = false;
          _isNavigatingAway = false;
        });
      }
    } catch (e) {
      // Try to recreate the controller if restart fails
      try {
        cameraController.dispose();
        cameraController = MobileScannerController();
        await cameraController.start();
        setState(() {
          isProcessing = false;
          _isNavigatingAway = false;
        });
      } catch (e) {
        // Handle controller recreation error silently
      }
    }
  }

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

      // Store context values before async operation
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      
      // Restart the scanner to enable scanning again with new date
      await _restartScanner();

      // Show feedback to user
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('date_updated_scanner_ready'.tr()),
            backgroundColor: theme.primaryColor,
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
      // If restart fails, try to dispose and recreate the controller
      try {
        cameraController.dispose();
        cameraController = MobileScannerController();
      } catch (e) {
        // Handle controller recreation error silently
      }
    }
  }

  Future<void> _stopCameraAndNavigate(String route, {Object? extra}) async {
    try {
      // Set navigation flag to prevent lifecycle interference
      setState(() {
        _isNavigatingAway = true;
      });

      // Stop the camera before navigation
      await cameraController.stop();

      // Add a small delay to ensure camera is properly stopped
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        if (extra != null) {
          await context.push(route, extra: extra);
          // Reset navigation flag when returning
          _handleReturnFromNavigation();
        } else {
          await context.push(route);
          // Reset navigation flag when returning
          _handleReturnFromNavigation();
        }
      }
    } catch (e) {
      // Navigate anyway even if camera stop fails
      if (mounted) {
        if (extra != null) {
          await context.push(route, extra: extra);
          _handleReturnFromNavigation();
        } else {
          await context.push(route);
          _handleReturnFromNavigation();
        }
      }
    }
  }

  void _handleReturnFromNavigation() {
    // Reset navigation flag and restart camera when returning
    setState(() {
      _isNavigatingAway = false;
      isProcessing = false;
      lastScannedCode = null; // Reset to allow new scans
    });
    
    // Restart camera after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _restartCameraIfNeeded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Handle hardware back button
          setState(() {
            _isNavigatingAway = true;
          });
          await cameraController.stop();
        }
      },
      child: Scaffold(
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
          onPressed: () async {
            // Set navigation flag and stop camera before going back
            setState(() {
              _isNavigatingAway = true;
            });
            await cameraController.stop();
            if (mounted) {
              context.go('/');
            }
          },
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
                      if (scannedValue.isNotEmpty &&
                          scannedValue != lastScannedCode) {
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
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
        // Show processing state
        setState(() {
          isProcessing = true;
        });

        // Scan barcode from the picked image
        await _scanBarcodeFromImage(image.path);
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

  Future<void> _scanBarcodeFromImage(String imagePath) async {
    try {
      // Use MobileScanner to analyze the image
      final BarcodeCapture? barcodeCapture =
          await cameraController.analyzeImage(imagePath);

      setState(() {
        isProcessing = false;
      });

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        // Process the first detected barcode
        final barcode = barcodeCapture.barcodes.first;
        final scannedValue = barcode.rawValue ?? '';

        if (scannedValue.isNotEmpty) {
          // Handle the scanned barcode same as camera scan
          _handleScannedBarcode(scannedValue);
        } else {
          _showNoBarcodeFoundDialog();
        }
      } else {
        // No barcode found in the image
        _showNoBarcodeFoundDialog();
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('image_scan_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoBarcodeFoundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('no_barcode_found'.tr()),
          content: Text('no_barcode_found_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ok'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Allow user to pick another image
                _pickImageFromGallery();
              },
              child: Text('try_again'.tr()),
            ),
          ],
        );
      },
    );
  }

// Remove the old _showGalleryInfoDialog method as it's no longer needed

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

      _showValidationErrorDialog(
          BarcodeValidator.getValidationError(barcodeValue));
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

    // Use the new method to stop camera and navigate
    await _stopCameraAndNavigate('/result/scratch', extra: ticketData);
  }

  void _showValidationErrorDialog(String errorMessage) {
    ValidationErrorDialog.show(context, errorMessage);
  }

  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    // Stop and dispose the camera controller
    cameraController.dispose();
    super.dispose();
  }
}
