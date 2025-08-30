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

              // Construct full URL for image_url
              final baseUrl =
                  'https://supabase.com/storage/v1/object/public/img/';
              json['image_url'] = '$baseUrl${json['image_url']}';

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
}
