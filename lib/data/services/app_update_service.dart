import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  bool _isCheckingForUpdate = false;
  StreamController<AppUpdateInfo>? _updateInfoController;

  Stream<AppUpdateInfo> get updateInfoStream {
    _updateInfoController ??= StreamController<AppUpdateInfo>.broadcast();
    return _updateInfoController!.stream;
  }

  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('🔄 In-app update is only supported on Android');
      }
      return;
    }

    await checkForUpdate();
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (_isCheckingForUpdate) {
      if (kDebugMode) {
        debugPrint('🔄 Update check already in progress');
      }
      return null;
    }

    if (!Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('🔄 In-app update is only supported on Android');
      }
      return null;
    }

    _isCheckingForUpdate = true;

    try {
      if (kDebugMode) {
        debugPrint('🔄 Checking for app update...');
      }

      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (kDebugMode) {
        debugPrint('🔄 Update available: ${info.updateAvailability}');
        debugPrint('🔄 Immediate update allowed: ${info.immediateUpdateAllowed}');
        debugPrint('🔄 Flexible update allowed: ${info.flexibleUpdateAllowed}');
      }

      _updateInfoController?.add(info);

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await performImmediateUpdate();
        }
      }

      return info;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking for update: ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error checking for update: $e');
      }
      return null;
    } finally {
      _isCheckingForUpdate = false;
    }
  }

  Future<bool> performImmediateUpdate() async {
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('🔄 In-app update is only supported on Android');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting immediate update...');
      }

      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();

      if (kDebugMode) {
        debugPrint('🔄 Update result: $result');
      }

      switch (result) {
        case AppUpdateResult.success:
          if (kDebugMode) {
            debugPrint('✅ App updated successfully');
          }
          return true;
        case AppUpdateResult.userDeniedUpdate:
          if (kDebugMode) {
            debugPrint('❌ User denied the update');
          }
          return false;
        case AppUpdateResult.inAppUpdateFailed:
          if (kDebugMode) {
            debugPrint('❌ In-app update failed');
          }
          return false;
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error performing immediate update: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error performing immediate update: $e');
      }
      return false;
    }
  }

  Future<bool> startFlexibleUpdate() async {
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('🔄 In-app update is only supported on Android');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting flexible update...');
      }

      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();

      if (kDebugMode) {
        debugPrint('🔄 Flexible update result: $result');
      }

      return result == AppUpdateResult.success;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error starting flexible update: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error starting flexible update: $e');
      }
      return false;
    }
  }

  Future<bool> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('🔄 In-app update is only supported on Android');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔄 Completing flexible update...');
      }

      await InAppUpdate.completeFlexibleUpdate();

      if (kDebugMode) {
        debugPrint('🔄 Flexible update completed');
      }

      return true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error completing flexible update: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error completing flexible update: $e');
      }
      return false;
    }
  }

  void dispose() {
    _updateInfoController?.close();
    _updateInfoController = null;
  }
}