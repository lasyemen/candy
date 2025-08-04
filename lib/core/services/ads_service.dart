import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../models/ads.dart';

class AdsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all ads from the database
  static Future<List<Ads>> fetchAds() async {
    try {
      print('Fetching ads from Supabase...');

      // Check if Supabase is initialized
      if (_supabase == null) {
        print('Supabase client is null');
        return [];
      }

      // Fetch all ads with detailed logging
      final response = await _supabase
          .from('ads')
          .select('*')
          .order('created_at', ascending: false);

      print('Raw ads response: $response'); // Debug log

      if (response == null) {
        print('No ads response from database');
        return [];
      }

      if (response is List && response.isEmpty) {
        print('Ads table is empty');
        return [];
      }

      final adsList = (response as List)
          .map((json) {
            try {
              print('Processing ad JSON: $json');
              // Validate required fields
              if (json['id'] == null ||
                  json['image_url'] == null ||
                  json['image_url'].toString().isEmpty ||
                  json['created_at'] == null) {
                print(
                  'Skipping ad with null or invalid required fields: $json',
                );
                return null;
              }

              // Handle both relative paths and full URLs
              String imageUrl;
              if (json['image_url'].toString().startsWith('http')) {
                // Already a full URL (like products table)
                imageUrl = json['image_url'];
                print('Using full URL from database: $imageUrl');
              } else {
                // Relative path (like ads table) - construct full URL
                final baseUrl =
                    'https://zzmqxporppazopgxfbwj.supabase.co/storage/v1/object/public/';
                imageUrl = '$baseUrl${json['image_url']}';
                print('Constructed full URL from relative path: $imageUrl');
              }

              // Validate the URL format
              if (!imageUrl.contains('ads/')) {
                print(
                  'Warning: Image URL does not contain expected bucket path: $imageUrl',
                );
              }

              // Keep all ads from database, even if images might be missing
              // The UI will handle missing images gracefully

              json['image_url'] = imageUrl;

              final ad = Ads.fromJson(json);
              print(
                'Successfully parsed ad: ${ad.id} with image: ${ad.imageUrl}',
              );
              return ad;
            } catch (e) {
              print('Error parsing ad: $e, json: $json');
              return null;
            }
          })
          .where((ad) => ad != null)
          .cast<Ads>()
          .toList();

      print('Successfully loaded ${adsList.length} ads');

      // Log each ad's details
      for (int i = 0; i < adsList.length; i++) {
        final ad = adsList[i];
        print(
          'Ad ${i + 1}: ID=${ad.id}, Image=${ad.imageUrl}, Created=${ad.createdAt}',
        );
      }

      // Map the ads data to the format expected by the BannerWidget
      final banners = adsList
          .map(
            (ad) => {
              'image_url': ad.imageUrl,
              'title': 'Ad Title', // Example title
              'subtitle': 'Ad Subtitle', // Example subtitle
              'gradient': LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              'color': Colors.blue,
              'icon': Icons.star,
            },
          )
          .toList();

      print('Mapped banners: $banners');

      // Return the original adsList
      return adsList;
    } catch (e) {
      print('Error fetching ads: $e');
      return [];
    }
  }

  /// Add a test ad to the database (for testing purposes)

  /// Add multiple sample ads to the database
  static Future<bool> addSampleAds() async {
    print(
      'addSampleAds method is deprecated. Use fetchAds to retrieve ads from the database.',
    );
    return false;
  }

  /// Check if ads table has any data
  static Future<bool> hasAds() async {
    try {
      final response = await _supabase.from('ads').select('id').limit(1);

      final hasData = response.isNotEmpty;
      print('Ads table has data: $hasData');
      return hasData;
    } catch (e) {
      print('Error checking ads table: $e');
      return false;
    }
  }

  /// Test if an image URL is accessible
  static Future<bool> testImageUrl(String imageUrl) async {
    try {
      final response = await _supabase.storage
          .from('ads')
          .getPublicUrl(imageUrl.split('/').last);

      print('Testing image URL: $imageUrl');
      print('Generated public URL: ${response}');

      // You can also make an HTTP request to test if the file exists
      // This would require adding http package to your dependencies

      return true;
    } catch (e) {
      print('Error testing image URL: $e');
      return false;
    }
  }

  /// Debug method to check if ads have valid images
  static Future<void> debugAdsImages() async {
    try {
      final ads = await fetchAds();
      print('=== DEBUGGING ADS IMAGES ===');
      for (final ad in ads) {
        print('Ad ID: ${ad.id}');
        print('Image URL: ${ad.imageUrl}');
        print('Is Valid URL: ${ad.imageUrl.startsWith('http')}');
        print('---');
      }
    } catch (e) {
      print('Error debugging ads: $e');
    }
  }

  /// Get admin instructions for correct image upload format
  static String getAdminInstructions() {
    return '''
ADMIN INSTRUCTIONS FOR UPLOADING ADS:

1. Upload image to Supabase storage bucket: 'ads'
2. Store FULL URL in database (like products table):
   Example: https://zzmqxporppazopgxfbwj.supabase.co/storage/v1/object/public/ads/filename.png
3. DO NOT store relative paths like: ads/filename.png

Current products table format (CORRECT):
- image_url: https://zzmqxporppazopgxfbwj.supabase.co/storage/v1/object/public/img/img/filename.png

Current ads table format (INCORRECT):
- image_url: ads/filename.png

Please update the admin upload process to match the products table format.
''';
  }

  /// Update existing ads to use full URLs (like products table)
  static Future<bool> updateAdsToFullUrls() async {
    try {
      print('Updating ads to use full URLs...');

      // Get all ads with relative paths
      final response = await _supabase
          .from('ads')
          .select('*')
          .not('image_url', 'like', 'https%');

      print('Found ${response.length} ads with relative paths');

      for (final ad in response) {
        final relativePath = ad['image_url'];
        final fullUrl =
            'https://zzmqxporppazopgxfbwj.supabase.co/storage/v1/object/public/$relativePath';

        print('Updating ad ${ad['id']}: $relativePath -> $fullUrl');

        // Update the ad with full URL
        await _supabase
            .from('ads')
            .update({'image_url': fullUrl})
            .eq('id', ad['id']);
      }

      print('Successfully updated all ads to use full URLs');
      return true;
    } catch (e) {
      print('Error updating ads to full URLs: $e');
      return false;
    }
  }
}
