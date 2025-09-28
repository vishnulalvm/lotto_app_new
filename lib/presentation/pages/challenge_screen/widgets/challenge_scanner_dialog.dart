import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lotto_app/core/utils/barcode_validator.dart';
import 'package:lotto_app/presentation/pages/bar_code_screen/widgets/validation_error_dialog.dart';

class ChallengeScannerDialog extends StatefulWidget {
  final Function(String lotteryNumber, double? price, DateTime date, String? lotteryName) onScanResult;

  const ChallengeScannerDialog({
    super.key,
    required this.onScanResult,
  });

  @override
  State<ChallengeScannerDialog> createState() => _ChallengeScannerDialogState();
}

class _ChallengeScannerDialogState extends State<ChallengeScannerDialog>
    with WidgetsBindingObserver {
  MobileScannerController cameraController = MobileScannerController(
    autoStart: false,
  );
  
  bool isFlashOn = false;
  DateTime selectedDate = DateTime.now();
  String? lastScannedCode;
  bool isProcessing = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  bool _isRequestingPermission = false;
  bool _isCameraStarting = false;
  bool _isNavigatingAway = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _isNavigatingAway) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (_cameraPermissionStatus == PermissionStatus.granted) {
          _startOrRestartCamera();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        cameraController.stop();
        break;
      default:
        break;
    }
  }

  Future<void> _checkCameraPermission() async {
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      _cameraPermissionStatus = await Permission.camera.status;

      if (_cameraPermissionStatus.isDenied) {
        _cameraPermissionStatus = await Permission.camera.request();
      }

      if (_cameraPermissionStatus.isGranted) {
        await _startOrRestartCamera();
      } else if (_cameraPermissionStatus.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }

  Future<void> _startOrRestartCamera() async {
    if (_isCameraStarting || !mounted) return;

    setState(() {
      _isCameraStarting = true;
    });

    try {
      await cameraController.start();
      if (mounted) {
        setState(() {
          lastScannedCode = null;
          isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('camera_start_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCameraStarting = false;
        });
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('camera_permission_required'.tr()),
        content: Text('camera_permission_message'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the scanner dialog too
            },
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('open_settings'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: screenSize.width,
        height: screenSize.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
        ),
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: _buildScannerBody(theme),
            ),
            _buildBottomControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'scan_lottery_ticket'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'scan_barcode_to_add_entry'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBody(ThemeData theme) {
    if (_cameraPermissionStatus != PermissionStatus.granted) {
      return _buildPermissionContent(theme);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: _onBarcodeDetected,
            ),
            _buildScannerOverlay(theme),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionContent(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'camera_permission_required'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'camera_permission_message'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _checkCameraPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('grant_permission'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(ThemeData theme) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corner brackets
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.primaryColor, width: 4),
                    left: BorderSide(color: theme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.primaryColor, width: 4),
                    right: BorderSide(color: theme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              left: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.primaryColor, width: 4),
                    left: BorderSide(color: theme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.primaryColor, width: 4),
                    right: BorderSide(color: theme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            // Instruction text
            Positioned(
              bottom: -50,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'align_barcode_within_frame'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            theme,
            icon: isFlashOn ? Icons.flash_off : Icons.flash_on,
            label: isFlashOn ? 'flash_off'.tr() : 'flash_on'.tr(),
            onTap: _toggleFlash,
          ),
          _buildControlButton(
            theme,
            icon: Icons.date_range,
            label: 'select_date'.tr(),
            onTap: () => _selectDate(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'select_purchase_date'.tr(),
      cancelText: 'cancel'.tr(),
      confirmText: 'select'.tr(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await cameraController.toggleTorch();
      setState(() {
        isFlashOn = !isFlashOn;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      // Flash not available
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (isProcessing || lastScannedCode != null) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Prevent multiple scans of the same code
    if (lastScannedCode == code) return;

    setState(() {
      isProcessing = true;
      lastScannedCode = code;
    });

    HapticFeedback.mediumImpact();

    // Validate barcode
    if (BarcodeValidator.isValidLotteryTicket(code)) {
      // Extract lottery number from barcode (assuming it contains the 4-digit number)
      String lotteryNumber = _extractLotteryNumber(code);
      
      // Try to extract price if available
      double? price = _extractPrice(code);
      
      // Try to extract lottery name from barcode format (like RP for specific lottery types)
      String? lotteryName = _extractLotteryName(code);

      // Call the callback with extracted data
      widget.onScanResult(lotteryNumber, price, selectedDate, lotteryName);

      // Close the dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lottery_ticket_scanned_successfully'.tr()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      // Show validation error
      _showValidationError(BarcodeValidator.getValidationError(code));
    }
  }

  String _extractLotteryNumber(String barcode) {
    // Simple extraction - you might need to adjust this based on your barcode format
    // This assumes the lottery number is the last 4 digits of the barcode
    if (barcode.length >= 4) {
      return barcode.substring(barcode.length - 4);
    }
    return barcode.padLeft(4, '0');
  }

  double? _extractPrice(String barcode) {
    // Try to extract price from barcode if it follows a specific format
    // This is a placeholder - implement based on your barcode format
    return null;
  }

  String? _extractLotteryName(String barcode) {
    // Extract lottery name based on prefix codes in Kerala lottery system
    // Common Kerala lottery prefixes and their names
    final Map<String, String> lotteryPrefixes = {
      'RP': 'Akshaya',
      'SC': 'Sthree Sakthi', 
      'AB': 'Akshaya',
      'AD': 'Adithya',
      'AK': 'Akshaya',
      'BH': 'Bhagyanidhi',
      'BR': 'Bhagyanidhi',
      'DE': 'Dhanasree',
      'DH': 'Dhanasree',
      'KA': 'Karunya',
      'KR': 'Karunya',
      'KN': 'Karunya Plus',
      'NR': 'Nirmal',
      'PU': 'Pournami',
      'SS': 'Sthree Sakthi',
      'WW': 'Win Win',
      'WN': 'Win Win',
    };

    String cleanedBarcode = BarcodeValidator.cleanTicketNumber(barcode);
    if (cleanedBarcode.length >= 2) {
      String prefix = cleanedBarcode.substring(0, 2).toUpperCase();
      return lotteryPrefixes[prefix];
    }
    
    return null; // Unknown lottery type
  }

  void _showValidationError(String message) {
    setState(() {
      isProcessing = false;
      lastScannedCode = null;
    });

    ValidationErrorDialog.show(context, message).then((_) {
      setState(() {
        lastScannedCode = null;
        isProcessing = false;
      });
    });
  }
}