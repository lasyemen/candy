import '../../models/products.dart';
import '../constants/translations.dart';
import 'product_dictionary.dart';

// Hard-coded product localizations for known, finite catalog.
// If an ID is not present here, we gracefully fall back to
// existing values or the lightweight dictionary.
class ProductLocalizations {
  // English display names by product ID
  static const Map<String, String> _nameEn = {
    '1': 'Candy 330ml',
    '2': 'Candy 200ml',
    '3': 'Candy 500ml',
    '4': 'Candy 1L',
    // Add more if needed
  };

  // English descriptions by product ID
  static const Map<String, String> _descEn = {
    '1': '1 Carton - 40 Plastic Bottles',
    '2': '1 Carton - 48 Plastic Bottles',
    '3': '1 Carton - 24 Plastic Bottles',
    '4': '1 Carton - 12 Plastic Bottles',
  };

  static String nameFor(Products product, String language) {
    // 1) translations.dart hard-coded keys by ID (any language, falls back to EN)
    final nameKey = 'product_name_${product.id}';
    final localizedName = AppTranslations.getText(nameKey, language);
    if (localizedName != nameKey) return localizedName;

    // 2) Internal EN map (legacy fallback)
    final hardCoded = _nameEn[product.id];
    if (hardCoded != null && hardCoded.isNotEmpty) return hardCoded;

    // 3) For EN, try alias key derived from raw name (hard-coded in translations)
    if (language == 'en') {
      final aliasKey = 'product_alias_${_aliasKeyFromRaw(product.name)}';
      final alias = AppTranslations.getText(aliasKey, 'en');
      if (alias != aliasKey) return alias;
    }

    // 4) For EN, try heuristic conversion from Arabic DB name
    if (language == 'en') {
      try {
        final converted = ProductDictionary.translateName(product.name, 'en');
        if (converted.isNotEmpty) return converted;
      } catch (_) {}
    }

    // 5) Final fallback to original DB name
    return product.name;
  }

  // Convenience for cases where only ID and raw name are available.
  static String nameForId(
    String productId,
    String rawName,
    String language,
  ) {
    // 1) translations.dart by ID (any language, falls back to EN)
    final nameKey = 'product_name_$productId';
    final localizedName = AppTranslations.getText(nameKey, language);
    if (localizedName != nameKey) return localizedName;

    // 2) internal EN map (legacy)
    final hardCoded = _nameEn[productId];
    if (hardCoded != null && hardCoded.isNotEmpty) return hardCoded;

    // 3) For EN, attempt alias key based on raw name
    if (language == 'en') {
      final aliasKey = 'product_alias_${_aliasKeyFromRaw(rawName)}';
      final alias = AppTranslations.getText(aliasKey, 'en');
      if (alias != aliasKey) return alias;
    }

    // 4) dictionary heuristic for EN
    if (language == 'en') {
      try {
        final converted = ProductDictionary.translateName(rawName, 'en');
        if (converted.isNotEmpty) return converted;
      } catch (_) {}
    }

    // 5) fallback to raw name
    return rawName;
  }

  static String? descriptionFor(Products product, String language) {
    // 1) translations.dart by ID (any language, falls back to EN)
    final descKey = 'product_desc_${product.id}';
    final localizedDesc = AppTranslations.getText(descKey, language);
    if (localizedDesc != descKey) return localizedDesc;

    // 2) EN hard-coded map (legacy fallback)
    final hardCoded = _descEn[product.id];
    if (hardCoded != null && hardCoded.isNotEmpty) return hardCoded;

    // 3) If EN and DB description is Arabic, attempt heuristic conversion
    if (language == 'en' && (product.description != null)) {
      try {
        final converted = ProductDictionary.translateDescription(
          product.description!,
          'en',
        );
        if (converted.trim().isNotEmpty) return converted;
      } catch (_) {}
    }

    // 4) fallback to DB description or null
    return product.description;
  }

  // Build a safe alias key from the raw product name.
  // Keep Arabic letters; replace all whitespace with underscores; trim.
  static String _aliasKeyFromRaw(String raw) {
    final normalized = _normalizeArabicForKey(raw.trim());
    // Collapse whitespace to single spaces, then replace spaces with _
    final oneSpaced = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return oneSpaced.replaceAll(' ', '_');
  }

  // Minimal Arabic normalization for alias keys
  static String _normalizeArabicForKey(String input) {
    // Remove harakat and tatweel
    final withoutMarks = input.replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '');
    // Normalize Alef variants and Alef Maqsura
    return withoutMarks
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي');
  }
}
