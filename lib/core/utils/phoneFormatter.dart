class PhoneFormatter {
  /// Converts a raw mobile number string into the standard Indian format: +91 XXXXX XXXXX
  static String toIndianStandard(String? rawNumber) {
    if (rawNumber == null || rawNumber.isEmpty) {
      return '';
    }

    // 1. Remove all non-numeric characters (spaces, dashes, parentheses)
    String cleaned = rawNumber.replaceAll(RegExp(r'\D'), '');

    // 2. Handle prefixes
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      // If it already starts with 91 and has 12 digits, extract the last 10
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      // If it starts with a leading 0, extract the last 10
      cleaned = cleaned.substring(1);
    }

    // 3. Validate if we have a proper 10-digit mobile number left
    if (cleaned.length == 10) {
      // Split into XXXXX XXXXX format for better visual readability
      final firstHalf = cleaned.substring(0, 5);
      final secondHalf = cleaned.substring(5);
      return '+91 $firstHalf $secondHalf';
    }

    // Fallback: If the number doesn't fit standard lengths, return the cleaned version or original
    return rawNumber;
  }
}
