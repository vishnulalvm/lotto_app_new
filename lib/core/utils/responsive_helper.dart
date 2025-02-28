import 'package:flutter/material.dart';

class AppResponsive {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Check if screen is mobile
  static bool isMobile(BuildContext context) => screenWidth(context) < 600;
  
  // Check if screen is tablet

  // Responsive font size
  static double fontSize(BuildContext context, double size) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Base width is 375 (iPhone SE width)
    double scaleFactor = screenWidth / 375;
    return size * scaleFactor.clamp(0.8, 1.4); // Limit scaling between 0.8 and 1.4
  }

  // Responsive spacing
  static double spacing(BuildContext context, double size) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 375;
    return size * scaleFactor.clamp(0.8, 1.6);
  }

  // Responsive padding
  static EdgeInsets padding(BuildContext context, 
      {double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: spacing(context, horizontal),
      vertical: spacing(context, vertical),
    );
  }

  // Responsive margin
  static EdgeInsets margin(BuildContext context,
      {double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: spacing(context, horizontal),
      vertical: spacing(context, vertical),
    );
  }

  // Responsive width
  static double width(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }

  // Responsive height
  static double height(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }
}