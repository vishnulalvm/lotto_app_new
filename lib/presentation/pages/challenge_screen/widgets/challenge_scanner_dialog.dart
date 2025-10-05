import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lotto_app/core/utils/barcode_validator.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/presentation/pages/bar_code_screen/widgets/validation_error_dialog.dart';
import 'package:lotto_app/presentation/pages/challenge_screen/widgets/manual_entry_dialog.dart';
import 'package:image_picker/image_picker.dart';

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
  final bool _isNavigatingAway = false;
  bool isAutoAddEnabled = false;

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
    // Handle app going to background/foreground
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App is going to background - stop camera to save battery
        _stopCameraSafely();
        break;
      case AppLifecycleState.resumed:
        // Only restart camera if we haven't navigated away and permission is granted
        if (!_isNavigatingAway && _cameraPermissionStatus == PermissionStatus.granted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isNavigatingAway && mounted) {
              _startOrRestartCamera();
            }
          });
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _stopCameraSafely() async {
    try {
      await cameraController.stop();
    } catch (e) {
      // Camera stop failed, but continue
    }
  }

  Future<void> _checkCameraPermission() async {
    if (_isRequestingPermission) return;
    
    final permission = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _cameraPermissionStatus = permission;
      });
      
      // Start camera automatically if permission is granted
      if (permission == PermissionStatus.granted) {
        _startOrRestartCamera();
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      final permission = await Permission.camera.request();
      
      if (mounted) {
        setState(() {
          _cameraPermissionStatus = permission;
          _isRequestingPermission = false;
        });
        
        // Start camera automatically if permission is granted
        if (permission == PermissionStatus.granted) {
          _startOrRestartCamera();
        }
      }
    } catch (e) {
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'scan_lottery_ticket'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: AppResponsive.fontSize(context, 20),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cameraPermissionStatus == PermissionStatus.granted 
                   ? _buildScannerView() 
                   : _buildPermissionRequestUI(),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildDateChooserButton() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: AppResponsive.padding(context, horizontal: 20, vertical: 12),
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
              size: AppResponsive.spacing(context, 24),
            ),
            SizedBox(width: AppResponsive.spacing(context, 12)),
            Text(
              DateFormat('dd-MM-yyyy').format(selectedDate),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
                fontSize: AppResponsive.fontSize(context, 16),
              ),
            ),
            SizedBox(width: AppResponsive.spacing(context, 8)),
            Icon(
              Icons.arrow_drop_down,
              color: theme.primaryColor,
              size: AppResponsive.spacing(context, 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: cameraController,
          onDetect: _onBarcodeDetected,
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
          width: AppResponsive.width(context, 80),
          height: AppResponsive.height(context, 25),
        ),
        // Loading indicator
        if (isProcessing)
          Container(
            color: theme.brightness == Brightness.dark 
                ? Colors.black87 
                : Colors.black54,
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
            bottom: AppResponsive.spacing(context, 45),
            child: Container(
              width: AppResponsive.width(context, 80),
              padding: AppResponsive.padding(context, 
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? Colors.black87 
                    : Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'align_barcode_within_frame'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: AppResponsive.fontSize(context, 14),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionRequestUI() {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.brightness == Brightness.dark 
          ? Colors.grey.shade900 
          : Colors.black,
      child: Center(
        child: Padding(
          padding: AppResponsive.padding(context, horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: AppResponsive.spacing(context, 80),
                color: theme.primaryColor,
              ),
              SizedBox(height: AppResponsive.spacing(context, 24)),
              Text(
                'camera_permission_required'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: AppResponsive.fontSize(context, 20),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppResponsive.spacing(context, 16)),
              Text(
                _cameraPermissionStatus == PermissionStatus.permanentlyDenied
                    ? 'camera_permission_denied_message'.tr()
                    : 'camera_permission_message'.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  fontSize: AppResponsive.fontSize(context, 16),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppResponsive.spacing(context, 32)),
              if (_cameraPermissionStatus == PermissionStatus.permanentlyDenied)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: AppResponsive.padding(context, horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('open_settings'.tr()),
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 16)),
                    TextButton(
                      onPressed: _isRequestingPermission ? null : () async {
                        await _checkCameraPermission();
                      },
                      child: Text(
                        'check_permission_again'.tr(),
                        style: TextStyle(
                          color: _isRequestingPermission 
                              ? theme.primaryColor.withValues(alpha: 0.5)
                              : theme.primaryColor
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _isRequestingPermission ? null : () async {
                    await _requestCameraPermission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: AppResponsive.padding(context, horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRequestingPermission
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('grant_camera_permission'.tr()),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBottomControls() {
    final theme = Theme.of(context);
    return Container(
      padding: AppResponsive.padding(context, horizontal: 20, vertical: 20),
      color: theme.cardTheme.color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date chooser button
          Container(
            margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 20)),
            child: _buildDateChooserButton(),
          ),
          AppResponsive.isMobile(context) 
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildActionButton(
                          icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                          label: 'flash'.tr(),
                          isActive: isFlashOn,
                          onTap: _toggleFlash,
                        )),
                        SizedBox(width: AppResponsive.spacing(context, 8)),
                        Expanded(child: _buildActionButton(
                          icon: Icons.photo_library,
                          label: 'gallery'.tr(),
                          onTap: _pickImageFromGallery,
                        )),
                      ],
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildActionButton(
                          icon: Icons.edit,
                          label: 'manual_entry'.tr(),
                          onTap: _showManualEntryDialog,
                        )),
                        SizedBox(width: AppResponsive.spacing(context, 8)),
                        Expanded(child: _buildActionButton(
                          icon: isAutoAddEnabled ? Icons.check_circle : Icons.check_circle_outline,
                          label: 'auto_add'.tr(),
                          isActive: isAutoAddEnabled,
                          onTap: _toggleAutoAdd,
                        )),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                          label: 'flash'.tr(),
                          isActive: isFlashOn,
                          onTap: _toggleFlash,
                        ),
                        _buildActionButton(
                          icon: Icons.photo_library,
                          label: 'gallery'.tr(),
                          onTap: _pickImageFromGallery,
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'manual_entry'.tr(),
                          onTap: _showManualEntryDialog,
                        ),
                        _buildActionButton(
                          icon: isAutoAddEnabled ? Icons.check_circle : Icons.check_circle_outline,
                          label: 'auto_add'.tr(),
                          isActive: isAutoAddEnabled,
                          onTap: _toggleAutoAdd,
                        ),
                      ],
                    ),
                  ],
                ),
          SizedBox(height: AppResponsive.spacing(context, 20)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: AppResponsive.padding(context, horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppResponsive.spacing(context, 12)),
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
                size: AppResponsive.spacing(context, 24),
              ),
            ),
            SizedBox(height: AppResponsive.spacing(context, 8)),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: AppResponsive.fontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Store context values before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
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

  Future<void> _toggleFlash() async {
    try {
      setState(() {
        isFlashOn = !isFlashOn;
        cameraController.toggleTorch();
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      // Flash not available
    }
  }

  void _toggleAutoAdd() {
    setState(() {
      isAutoAddEnabled = !isAutoAddEnabled;
    });
    HapticFeedback.lightImpact();
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAutoAddEnabled 
            ? 'auto_add_enabled'.tr() 
            : 'auto_add_disabled'.tr()
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => ManualEntryDialog(
        onEntryAdded: (String lotteryNumber, double price, DateTime date, String lotteryName) {
          // Call the same callback as scan result
          widget.onScanResult(lotteryNumber, price, date, lotteryName);
        },
      ),
    ).then((_) {
      // Dialog was dismissed (either by cancel or by completing entry)
      // Reset scanner state and restart scanner if still mounted
      if (mounted) {
        setState(() {
          isProcessing = false;
          lastScannedCode = null;
        });
        
        // Restart the scanner for next scan
        if (_cameraPermissionStatus == PermissionStatus.granted) {
          _startOrRestartCamera();
        }
      }
    });
  }

  void _showScannedManualEntryDialog(String scannedLotteryNumber, String? scannedLotteryName) {
    showDialog(
      context: context,
      builder: (context) => ManualEntryDialog(
        initialLotteryNumber: scannedLotteryNumber,
        initialLotteryName: scannedLotteryName,
        onEntryAdded: (String lotteryNumber, double price, DateTime date, String lotteryName) {
          // Call the same callback as scan result
          widget.onScanResult(lotteryNumber, price, date, lotteryName);
        },
      ),
    ).then((_) {
      // Dialog was dismissed (either by cancel or by completing entry)
      // Reset scanner state and restart scanner if still mounted
      if (mounted) {
        setState(() {
          isProcessing = false;
          lastScannedCode = null;
        });
        
        // Restart the scanner for next scan
        if (_cameraPermissionStatus == PermissionStatus.granted) {
          _startOrRestartCamera();
        }
      }
    });
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
          _onBarcodeDetected(barcodeCapture);
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
      useRootNavigator: false,
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
    ).then((_) {
      // Dialog was dismissed - restart scanner
      if (mounted) {
        setState(() {
          isProcessing = false;
          lastScannedCode = null;
        });
        
        // Restart the scanner for next scan
        if (_cameraPermissionStatus == PermissionStatus.granted) {
          _startOrRestartCamera();
        }
      }
    });
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
      
      // Try to extract lottery name from barcode format (like RP for specific lottery types)
      String? lotteryName = _extractLotteryName(code);

      // Show success message first
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

      if (isAutoAddEnabled) {
        // Auto-add mode: add directly with default price and close scanner
        widget.onScanResult(lotteryNumber, 50.0, selectedDate, lotteryName);
      } else {
        // Manual mode: show manual entry dialog with lottery number pre-filled
        _showScannedManualEntryDialog(lotteryNumber, lotteryName);
      }
    } else {
      // Show validation error
      _showValidationError(BarcodeValidator.getValidationError(code));
    }
  }

  String _extractLotteryNumber(String barcode) {
    // Use the full scanned barcode as the lottery number
    // Clean it using the BarcodeValidator utility to ensure proper format
    return BarcodeValidator.cleanTicketNumber(barcode);
  }


  String? _extractLotteryName(String barcode) {
    // Extract lottery name based on first letter of lottery number
    // Kerala lottery first letter mapping
    final Map<String, String> lotteryFirstLetterMap = {
      'M': 'SAMRUDHI',           // M - SAMRUDHI
      'B': 'BHAGYATHARA',        // B - BHAGYATHARA
      'S': 'STHREE SAKTHI',      // S - STHREE SAKTHI
      'D': 'DHANALEKSHMI',       // D - DHANALEKSHMI
      'P': 'KARUNYA PLUS',       // P - KARUNYA PLUS
      'R': 'SUVARNA KERALAM',    // R - SUVARNA KERALAM
      'K': 'KARUNYA',            // K - KARUNYA
      'T': 'THIRUVONAM BUMPER',  // T - THIRUVONAM BUMPER
      'V': 'VISHU BUMPER',       // V - VISHU BUMPER
      'X': 'CHRISTMAS NEW YEAR BUMPER', // X - CHRISTMAS NEW YEAR BUMPER
      'C': 'CHRISTMAS NEW YEAR BUMPER', // C - CHRISTMAS NEW YEAR BUMPER (alternative)      // O - ONAM BUMPER
    };

    String cleanedBarcode = BarcodeValidator.cleanTicketNumber(barcode);
    if (cleanedBarcode.isNotEmpty) {
      String firstLetter = cleanedBarcode.substring(0, 1).toUpperCase();
      return lotteryFirstLetterMap[firstLetter];
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