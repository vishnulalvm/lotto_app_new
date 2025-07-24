import 'dart:async';
import 'dart:io';
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
      return;
    }

    await checkForUpdate();
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (_isCheckingForUpdate) {
      return null;
    }

    if (!Platform.isAndroid) {
      return null;
    }

    _isCheckingForUpdate = true;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      _updateInfoController?.add(info);

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await performImmediateUpdate();
        }
      }

      return info;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    } finally {
      _isCheckingForUpdate = false;
    }
  }

  Future<bool> performImmediateUpdate() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();

      switch (result) {
        case AppUpdateResult.success:
          return true;
        case AppUpdateResult.userDeniedUpdate:
          return false;
        case AppUpdateResult.inAppUpdateFailed:
          return false;
      }
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startFlexibleUpdate() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();

      return result == AppUpdateResult.success;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      await InAppUpdate.completeFlexibleUpdate();

      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _updateInfoController?.close();
    _updateInfoController = null;
  }
}