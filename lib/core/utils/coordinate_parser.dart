class CoordinateParser {
  /// Parses a coordinate string that might contain decimal degrees or DMS format.
  /// Example: "7.4177° N (7° 25' 4\" Nord)"
  static double? parse(String input) {
    if (input.isEmpty) return null;

    // 1. Try to match decimal degrees first (e.g., 7.4177)
    final decimalRegex = RegExp(r'(-?\d+\.\d+)');
    final decimalMatch = decimalRegex.firstMatch(input);
    if (decimalMatch != null) {
      return double.tryParse(decimalMatch.group(1)!);
    }

    // 2. Try to match DMS (Degrees, Minutes, Seconds)
    // Pattern: 7° 25' 4"
    final dmsRegex = RegExp(r"(\d+)°\s*(\d+)'\s*(\d+)\x22");
    final dmsMatch = dmsRegex.firstMatch(input);
    if (dmsMatch != null) {
      int deg = int.parse(dmsMatch.group(1)!);
      int min = int.parse(dmsMatch.group(2)!);
      int sec = int.parse(dmsMatch.group(3)!);
      
      double decimal = deg + (min / 60.0) + (sec / 3600.0);
      
      // Check for Southern or Western hemispheres
      final lowerInput = input.toLowerCase();
      if (lowerInput.contains('s') || 
          lowerInput.contains('sud') || 
          lowerInput.contains('o') || 
          lowerInput.contains('ouest') || 
          lowerInput.contains('w')) {
        decimal = -decimal;
      }
      return decimal;
    }

    return null;
  }
}
