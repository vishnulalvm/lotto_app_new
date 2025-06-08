import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LocaleHelper {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ml'),
    Locale('hi'),
  ];

  static const Locale fallbackLocale = Locale('en');

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ml':
        return 'മലയാളം';
      case 'hi':
        return 'हिंदी';
      default:
        return 'English';
    }
  }

  static String getLocalizedLanguageName(BuildContext context, String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'english'.tr();
      case 'ml':
        return 'malayalam'.tr();
      case 'hi':
        return 'hindi'.tr();
      default:
        return 'english'.tr();
    }
  }

  static void changeLanguage(BuildContext context, Locale locale) {
    context.setLocale(locale);
  }

  static bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.RTL;
  }

  static String getCurrentLanguageCode(BuildContext context) {
    return context.locale.languageCode;
  }
}