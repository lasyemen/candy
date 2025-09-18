class ProductDictionary {
  // Exact Arabic-to-English names for known items (seen in your catalog)
  static const Map<String, String> _exactArabicToEnglish = {
    'مياه معدنية 500مل': 'Mineral Water 500ml',
    'مياه معدنية 1ل': 'Mineral Water 1L',
    'مياه فوارة 330مل': 'Sparkling Water 330ml',
    'مياه غازية 500مل': 'Carbonated Water 500ml',
    'مياه نقية 5ل': 'Pure Water 5L',
    'مياه قلوية 1ل': 'Alkaline Water 1L',

    'مياه كاندي صغير': 'Candy Water Small',
    'مياه كاندي كبير': 'Candy Water Large',
    'مياه كاندي وسط': 'Candy Water Medium',
    'مياه كاندي قليل الصوديوم': 'Candy Water Low Sodium',
    'مياه كاندي بطعم بالكولاجين': 'Candy Water with Collagen',
  };

  // Fragment replacements for heuristic conversion
  static final Map<String, String> _fragmentArabicToEnglish = {
    // Brand/common words
    'كاندي': 'Candy',
    'مياه': 'Water',

    // Sizes/qualifiers
    'صغير': 'Small',
    'وسط': 'Medium',
    'كبير': 'Large',
    'قليل الصوديوم': 'Low Sodium',
    'بطعم': '',
    'بالكولاجين': 'with Collagen',
    'بالتكولوجين': 'with Collagen', // common misspelling

    // Types
    'فوارة': 'Sparkling',
    'غازية': 'Carbonated',
    'معدنية': 'Mineral',
    'نقية': 'Pure',
    'قلوية': 'Alkaline',

    // Units
    'مل': 'ml',
    'ل': 'L',
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

    var name = _normalizeArabic(rawName.trim());

    // 1) exact matches first
    final exact = _exactArabicToEnglish[name];
    if (exact != null) return exact;

    // 2) replace digits and fragments
    name = _convertArabicDigits(name);
    _fragmentArabicToEnglish.forEach((ar, en) {
      name = name.replaceAll(ar, en);
    });

    // 3) tidy whitespace and reorder terms
    name = _normalizeWhitespace(name);
    name = _reorderDescriptorBeforeWater(name);
    name = _fixBrandOrder(name);
    return name;
  }

  static String translateDescription(String rawDesc, String language) {
    if (language != 'en') return rawDesc;

    var text = _normalizeArabic(rawDesc.trim());

    // Digits first
    text = _convertArabicDigits(text);

    // Term replacements
    final replacements = <String, String>{
      'كرتون': 'Carton',
      'علبة': 'Carton',
      'حزمة': 'Pack',
      'واحد': '1',
      'واحدة': '1',
      'عبوة': 'Bottles',
      'زجاجية': 'Glass',
      'بلاستيكية': 'Plastic',
      'عدد': 'Qty',
      '–': '-',
      '−': '-',
    };
    replacements.forEach((k, v) => text = text.replaceAll(k, v));

    // Reorder: "Carton 1" -> "1 Carton"
    text = text.replaceAllMapped(
      RegExp(r'\bCarton\s+(\d+)\b'),
      (m) => '${m.group(1)} Carton',
    );

    // Reorder: "Bottles Plastic" -> "Plastic Bottles"
    text = text.replaceAllMapped(
      RegExp(r'\b(Bottles)\s+(Plastic|Glass)\b', caseSensitive: false),
      (m) => '${m.group(2)} ${m.group(1)}',
    );

    // Clean multi-spaces
    text = _normalizeWhitespace(text);
    return text;
  }

  // Remove diacritics/tatweel and normalize common variants
  static String _normalizeArabic(String input) {
    // Remove harakat and tatweel
    final withoutMarks = input.replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '');
    // Normalize Alef variants and Alef Maqsura
    return withoutMarks
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي');
  }

  static String _convertArabicDigits(String input) {
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(_arabicDigitsToLatin[ch] ?? ch);
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
      'Small',
      'Medium',
      'Large',
      'Low Sodium',
      'with Collagen',
    ];
    for (final descriptor in descriptors) {
      final pattern = RegExp('(?:Water\\s+$descriptor|$descriptor\\s+Water)',
          caseSensitive: false);
      if (pattern.hasMatch(input)) {
        return '$descriptor Water' + input.replaceAll(pattern, '');
      }
    }
    return input;
  }

  static String _fixBrandOrder(String input) {
    // Ensure brand appears before base type for readability: "Candy Water ..."
    final hasCandy = RegExp(r'(?i)\bcandy\b').hasMatch(input);
    final hasWater = RegExp(r'(?i)\bwater\b').hasMatch(input);
    if (hasCandy && hasWater) {
      var rest = input
          .replaceFirst(RegExp(r'(?i)\bcandy\b'), '')
          .replaceFirst(RegExp(r'(?i)\bwater\b'), '');
      rest = _normalizeWhitespace(rest);
      return ('Candy Water ' + rest).trim();
    }
    return input;
  }
}
