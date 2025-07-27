import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/core/utils/barcode_validator.dart';
import 'package:lotto_app/presentation/pages/bar_code_screen/widgets/validation_error_dialog.dart';
import 'package:lotto_app/presentation/pages/probility_screen/probability_result_dialog.dart';
import 'package:lotto_app/presentation/pages/probility_screen/widgets/how_it_works_dialog.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_bloc.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_event.dart';
import 'package:lotto_app/presentation/blocs/probability_screen/probability_state.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class ProbabilityBarcodeScannerScreen extends StatefulWidget {
  const ProbabilityBarcodeScannerScreen({super.key});

  @override
  State<ProbabilityBarcodeScannerScreen> createState() =>
      _ProbabilityBarcodeScannerScreenState();
}

class _ProbabilityBarcodeScannerScreenState
    extends State<ProbabilityBarcodeScannerScreen> with WidgetsBindingObserver {
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  DateTime selectedDate = DateTime.now();
  String? lastScannedCode;
  bool isProcessing = false;
  bool _isNavigatingAway = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted && !_isNavigatingAway) {
          _restartCameraIfNeeded();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (!_isNavigatingAway) {
          cameraController.stop();
        }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        cameraController.stop();
        break;
    }
  }

  Future<void> _restartCameraIfNeeded() async {
    try {
      if (!cameraController.value.isRunning) {
        await cameraController.start();
        setState(() {
          isProcessing = false;
          _isNavigatingAway = false;
        });
      }
    } catch (e) {
      try {
        cameraController.dispose();
        cameraController = MobileScannerController();
        await cameraController.start();
        setState(() {
          isProcessing = false;
          _isNavigatingAway = false;
        });
      } catch (e) {
        // Handle camera controller recreation error silently
      }
    }
  }



  Future<void> _restartScanner() async {
    try {
      await cameraController.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await cameraController.start();
    } catch (e) {
      try {
        cameraController.dispose();
        cameraController = MobileScannerController();
      } catch (e) {
        // Handle scanner controller recreation error silently
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<ProbabilityBloc, ProbabilityState>(
      listener: (context, state) {
        if (state is ProbabilityLoaded) {
          setState(() {
            isProcessing = false;
          });
          _showProbabilityResultDialog(
            lotteryName: state.response.lotteryName,
            lotteryNumber: state.response.lotteryNumber,
            probability: state.response.percentage,
            message: state.response.message,
          );
        } else if (state is ProbabilityError) {
          setState(() {
            isProcessing = false;
          });
          _showAPIErrorDialog();
        }
      },
      child: PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Check if there are any dialogs open
        if (Navigator.of(context).canPop()) {
          // There's a dialog open, just close it
          Navigator.of(context).pop();
          return;
        }
        
        // No dialogs open, navigate away from screen
        setState(() {
          _isNavigatingAway = true;
        });
        await cameraController.stop();
        if (mounted) {
          context.go('/');
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
                            const CircularProgressIndicator(
                                color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              'analyzing_probability'.tr(),
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
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'scan_to_check_winning_chance'.tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: 'smart_prediction'.tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: 'not_a_guarantee'.tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                    child: _buildHowToWork(context, theme),
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
    ),
    );
  }

  Widget _buildHowToWork(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => HowItWorksDialog.show(context),
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
        child: Text(
          'how_it_works'.tr(),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.primaryColor,
          ),
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
        setState(() {
          isProcessing = true;
        });

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
      final BarcodeCapture? barcodeCapture =
          await cameraController.analyzeImage(imagePath);

      setState(() {
        isProcessing = false;
      });

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final barcode = barcodeCapture.barcodes.first;
        final scannedValue = barcode.rawValue ?? '';

        if (scannedValue.isNotEmpty) {
          _handleScannedBarcode(scannedValue);
        } else {
          _showNoBarcodeFoundDialog();
        }
      } else {
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
                _pickImageFromGallery();
              },
              child: Text('try_again'.tr()),
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

    try {
      // Validate barcode format first
      if (!BarcodeValidator.isValidLotteryTicket(barcodeValue)) {
        setState(() {
          isProcessing = false;
        });
        _showValidationErrorDialog(
            BarcodeValidator.getValidationError(barcodeValue));
        return;
      }

      // Extract lottery number from barcode
      final lotteryNumber = BarcodeValidator.cleanTicketNumber(barcodeValue);

      // Call probability API using BLoC
      context.read<ProbabilityBloc>().add(
        GetProbabilityByLotteryNumberEvent(lotteryNumber: lotteryNumber),
      );
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      _showAPIErrorDialog();
    }
  }

  void _showProbabilityResultDialog({
    required String lotteryName,
    required String lotteryNumber,
    required double probability,
    String? message,
  }) {
    // Use the probability dialog with proper callback
    ProbabilityResultDialog.show(
      context,
      lotteryName: lotteryName,
      lotteryNumber: lotteryNumber,
      probability: probability,
      message: message,
      onScanAnother: _resetScanner, // Add callback to reset scanner
    );
  }

  Future<void> _resetScanner() async {
    setState(() {
      lastScannedCode = null;
      isProcessing = false;
      _isNavigatingAway = false;
    });

    try {
      // Restart the camera/scanner
      await _restartScanner();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('scanner_ready'.tr()),
            backgroundColor: Theme.of(context).primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('scanner_reset_error'.tr()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showAPIErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('analysis_error'.tr()),
        content: Text('failed_to_analyze_ticket'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset to allow scanning again
              setState(() {
                lastScannedCode = null;
              });
            },
            child: Text('try_again'.tr()),
          ),
        ],
      ),
    );
  }

  void _showValidationErrorDialog(String errorMessage) {
    ValidationErrorDialog.show(context, errorMessage);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }
}
