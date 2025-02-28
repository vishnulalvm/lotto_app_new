import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // Instead of Color(0xFFFFF1F2)
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
          onPressed: () => context.go('/'), // Using GoRouter
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: theme.appBarTheme.actionsIconTheme?.color,
            ),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
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
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      debugPrint('Barcode found! ${barcode.rawValue}');
                      // Handle the scanned barcode
                      _handleScannedBarcode(barcode.rawValue ?? '');
                    }
                  },
                ),
                // Overlay
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.primaryColor, // Instead of Colors.white
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 200,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.cardTheme.color, // Instead of Colors.white
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                SizedBox(height: 20),
                Text(
                  'Scan Barcode in Lottery for Get your Result',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
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
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor
                  .withOpacity(0.1), // Instead of Color(0xFFFFE4E6)
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? theme.primaryColor
                  : theme.iconTheme.color, // Instead of hardcoded colors
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium, // Using theme text style
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Process the image for barcode scanning
      // You might want to use a different barcode scanning library for images
      debugPrint('Image picked from gallery: ${image.path}');
    }
  }

  void _handleScannedBarcode(String barcodeValue) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Barcode Found',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'Barcode Value: $barcodeValue',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: theme.primaryColor),
              ),
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
