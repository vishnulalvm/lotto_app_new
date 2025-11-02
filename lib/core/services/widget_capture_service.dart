import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for capturing widgets as images and sharing them
class WidgetCaptureService {
  /// Captures a widget as an image and shares it
  ///
  /// [key] - GlobalKey attached to the RepaintBoundary widget
  /// [fileName] - Name of the file to save (without extension)
  /// [shareText] - Optional text to include with the share
  ///
  /// Returns true if successful, false otherwise
  static Future<bool> captureAndShare({
    required GlobalKey key,
    String fileName = 'lottery_result',
    String? shareText,
  }) async {
    try {
      // Trigger haptic feedback
      await HapticFeedback.mediumImpact();

      // Capture the widget as image
      final imageBytes = await _captureWidget(key);
      if (imageBytes == null) return false;

      // Save to temporary file
      final file = await _saveToTempFile(imageBytes, fileName);
      if (file == null) return false;

      // Share the file
      await _shareFile(file, shareText);

      return true;
    } catch (e) {
      debugPrint('Error capturing and sharing widget: $e');
      return false;
    }
  }

  /// Captures a widget as PNG image bytes
  static Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      // Get the render object
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('RenderRepaintBoundary not found');
        return null;
      }

      // Convert to image with high quality
      final image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('Failed to convert image to bytes');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Saves image bytes to a temporary file
  static Future<File?> _saveToTempFile(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create file path with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/${fileName}_$timestamp.png';

      // Write bytes to file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return file;
    } catch (e) {
      debugPrint('Error saving image to file: $e');
      return null;
    }
  }

  /// Shares a file using the native share dialog
  static Future<void> _shareFile(File file, String? text) async {
    try {
      final xFile = XFile(file.path);

      final shareParams = ShareParams(
        files: [xFile],
        text: text,
      );

      await SharePlus.instance.share(shareParams);
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }
}
