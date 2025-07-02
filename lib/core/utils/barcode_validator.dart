class BarcodeValidator {
  // Validate lottery ticket format: 2 letters + 6 digits (e.g., RP133796, RP 133796, SC355607, SC 355607)
  static bool isValidLotteryTicket(String barcode) {
    if (barcode.isEmpty) return false;
    
    // Clean the barcode: remove all whitespace and convert to uppercase
    String cleanedBarcode = _cleanBarcode(barcode);
    
    // Check if it matches the pattern: 2 letters + 6 digits
    final RegExp regex = RegExp(r'^[A-Z]{2}\d{6}$');
    return regex.hasMatch(cleanedBarcode);
  }
  
  // Extract clean ticket number from barcode (removes spaces, converts to uppercase)
  static String cleanTicketNumber(String barcode) {
    return _cleanBarcode(barcode);
  }
  
  // Private helper method to clean barcode
  static String _cleanBarcode(String barcode) {
    // Remove all whitespace characters (spaces, tabs, newlines, etc.) and convert to uppercase
    return barcode.replaceAll(RegExp(r'\s+'), '').trim().toUpperCase();
  }
  
  // Get validation error message with detailed feedback
  static String getValidationError(String barcode) {
    if (barcode.isEmpty) {
      return 'Please scan a barcode first';
    }
    
    String cleanedBarcode = _cleanBarcode(barcode);
    
    if (cleanedBarcode.length != 8) {
      return 'Lottery ticket should be 8 characters long (e.g., RP133796 or RP 133796)';
    }
    
    if (!RegExp(r'^[A-Z]{2}').hasMatch(cleanedBarcode.substring(0, 2))) {
      return 'Lottery ticket should start with 2 letters (e.g., RP, SC)';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(cleanedBarcode.substring(2))) {
      return 'Lottery ticket should end with 6 digits';
    }
    
    return 'Invalid lottery ticket format. Expected format: RP133796 or RP 133796';
  }
  
  // Additional helper method to check if barcode has valid structure before cleaning
  static bool hasValidStructure(String barcode) {
    if (barcode.isEmpty) return false;
    
    // Check if after removing spaces, we have the right basic structure
    String withoutSpaces = barcode.replaceAll(' ', '').trim();
    
    // Should have at least 8 characters after removing spaces
    if (withoutSpaces.length < 8) return false;
    
    // Should start with letters and contain digits
    return RegExp(r'^[A-Za-z]').hasMatch(withoutSpaces) && 
           RegExp(r'\d').hasMatch(withoutSpaces);
  }
  
  // Method to format barcode consistently (adds space between letters and numbers)
  static String formatBarcode(String barcode) {
    String cleanedBarcode = _cleanBarcode(barcode);
    
    if (cleanedBarcode.length == 8 && isValidLotteryTicket(barcode)) {
      // Insert space between 2nd and 3rd character (between letters and numbers)
      return '${cleanedBarcode.substring(0, 2)} ${cleanedBarcode.substring(2)}';
    }
    
    return cleanedBarcode;
  }
}