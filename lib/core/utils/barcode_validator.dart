class BarcodeValidator {
  // Validate lottery ticket format: 2 letters + 6 digits (e.g., RP133796)
  static bool isValidLotteryTicket(String barcode) {
    if (barcode.isEmpty) return false;
    
    // Remove any whitespace
    barcode = barcode.trim().toUpperCase();
    
    // Check if it matches the pattern: 2 letters + 6 digits
    final RegExp regex = RegExp(r'^[A-Z]{2}\d{6}$');
    return regex.hasMatch(barcode);
  }
  
  // Extract clean ticket number from barcode
  static String cleanTicketNumber(String barcode) {
    return barcode.trim().toUpperCase();
  }
  
  // Get validation error message
  static String getValidationError(String barcode) {
    if (barcode.isEmpty) {
      return 'Please scan a barcode first';
    }
    
    if (barcode.length != 8) {
      return 'Lottery ticket should be 8 characters long (e.g., RP133796)';
    }
    
    if (!RegExp(r'^[A-Z]{2}').hasMatch(barcode.substring(0, 2))) {
      return 'Lottery ticket should start with 2 letters (e.g., RP)';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(barcode.substring(2))) {
      return 'Lottery ticket should end with 6 digits';
    }
    
    return 'Invalid lottery ticket format. Expected format: RP133796';
  }
}
