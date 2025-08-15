class ProductDictionary {
  static const Map<String, String> _exactArabicToEnglish = {
    // Add exact known product name translations here for highest accuracy
    'مياه معدنية 500مل': 'Mineral Water 500ml',
    'مياه معدنية 1لتر': 'Mineral Water 1L',
    'مياه غازية 330مل': 'Sparkling Water 330ml',
    'مياه فوارة 500مل': 'Carbonated Water 500ml',
    'مياه نقية 5لتر': 'Pure Water 5L',
    'مياه قلوية 1لتر': 'Alkaline Water 1L',
  };

  static const Map<String, String> _fragmentArabicToEnglish = {
    'مياه': 'Water',
    'غازية': 'Sparkling',
    'فوارة': 'Carbonated',
    'معدنية': 'Mineral',
    'نقية': 'Pure',
    'قلوية': 'Alkaline',
    'مل': 'ml',
    'لتر': 'L',
  };

  static const Map<String, String> _arabicDigitsToLatin = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  static String translateName(String rawName, String language) {
    if (language != 'en') return rawName;

    final trimmed = rawName.trim();
    final normalized = _normalizeArabic(trimmed);

    final exact =
        _exactArabicToEnglish[normalized] ?? _exactArabicToEnglish[trimmed];
    if (exact != null) return exact;

    String converted = _convertArabicDigits(normalized);
    _fragmentArabicToEnglish.forEach((ar, en) {
      converted = converted.replaceAll(ar, en);
    });

    converted = _normalizeWhitespace(converted);
    converted = _reorderDescriptorBeforeWater(converted);
    return converted;
  }

  static String _normalizeArabic(String input) {
    // Remove diacritics and tatweel
    final withoutDiacritics = input.replaceAll(
      RegExp('[\u064B-\u0652\u0670\u0640]'),
      '',
    );
    // Normalize alef/hamza variants and alef maqsura
    final normalizedAlef = withoutDiacritics
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي');
    return normalizedAlef;
  }

  static String _convertArabicDigits(String input) {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      buffer.write(_arabicDigitsToLatin[char] ?? char);
    }
    return buffer.toString();
  }

  static String _normalizeWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _reorderDescriptorBeforeWater(String input) {
    // Ensures patterns like "Water Mineral" become "Mineral Water"
    final descriptors = [
      'Sparkling',
      'Carbonated',
      'Mineral',
      'Pure',
      'Alkaline',
    ];
    for (final descriptor in descriptors) {
      final pattern = RegExp(
        '(?:Water\s+$descriptor|$descriptor\s+Water)',
        caseSensitive: false,
      );
      if (pattern.hasMatch(input)) {
        return '$descriptor Water' + input.replaceAll(pattern, '');
      }
    }
    return input;
  }
}
