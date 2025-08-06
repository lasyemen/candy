import '../../models/product_rating.dart';
import 'supabase_service.dart';

class RatingService {
  // Test if product_ratings table exists and is accessible
  static Future<bool> testTableAccess() async {
    try {
      print('RatingService - Testing table access...');

      // Try to select from the table
      final response = await SupabaseService.instance.client
          .from('product_ratings')
          .select('*')
          .limit(1);

      print(
          'RatingService - Table access successful. Found ${response.length} records');
      return true;
    } catch (e) {
      print('RatingService - Table access failed: $e');
      return false;
    }
  }

  // Get average rating and total count for a product
  static Future<ProductRatingSummary?> getProductRatingSummary(
      String productId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('product_ratings')
          .select('rating')
          .eq('product_id', productId);

      if (response.isEmpty) {
        return ProductRatingSummary(averageRating: 0.0, totalRatings: 0);
      }

      final ratings = response.map((r) => r['rating'] as int).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

      return ProductRatingSummary(
        averageRating: averageRating,
        totalRatings: ratings.length,
      );
    } catch (e) {
      print('RatingService - Error getting rating summary: $e');
      return null;
    }
  }

  // Get user's existing rating for a product
  static Future<ProductRating?> getUserRating(
      String productId, String customerId) async {
    try {
      print('RatingService - Checking for existing rating...');
      print('RatingService - Product ID: $productId, Customer ID: $customerId');

      final response = await SupabaseService.instance.client
          .from('product_ratings')
          .select('*')
          .eq('product_id', productId)
          .eq('customer_id', customerId)
          .single();

      print('RatingService - Existing rating found: $response');
      return ProductRating.fromJson(response);
    } catch (e) {
      // No rating found or other error
      print('RatingService - No existing rating found or error: $e');
      return null;
    }
  }

  // Submit or update a rating
  static Future<bool> submitRating({
    required String productId,
    required String customerId,
    required int rating,
    String? review,
  }) async {
    try {
      print('RatingService - Starting rating submission...');
      print('RatingService - Product ID: $productId');
      print('RatingService - Customer ID: $customerId');
      print('RatingService - Rating: $rating');
      print('RatingService - Review: $review');

      // Test database connection first
      try {
        final testResponse = await SupabaseService.instance.client
            .from('product_ratings')
            .select('count')
            .limit(1);
        print('RatingService - Database connection test successful');
      } catch (e) {
        print('RatingService - Database connection test failed: $e');
        print(
            'RatingService - This suggests the table might not exist or there are permission issues');
        return false;
      }

      // Check if user already has a rating for this product
      final existingRating = await getUserRating(productId, customerId);
      print('RatingService - Existing rating found: ${existingRating != null}');

      if (existingRating != null) {
        print('RatingService - Updating existing rating...');
        try {
          // Update existing rating
          await SupabaseService.instance.client
              .from('product_ratings')
              .update({
                'rating': rating,
                'review': review,
                'created_at': DateTime.now().toIso8601String(),
              })
              .eq('product_id', productId)
              .eq('customer_id', customerId);
          print('RatingService - Rating updated successfully');
        } catch (updateError) {
          print('RatingService - Error updating rating: $updateError');
          return false;
        }
      } else {
        print('RatingService - Inserting new rating...');
        try {
          // Insert new rating
          await SupabaseService.instance.client.from('product_ratings').insert({
            'product_id': productId,
            'customer_id': customerId,
            'rating': rating,
            'review': review,
          });
          print('RatingService - Rating inserted successfully');
        } catch (insertError) {
          print('RatingService - Error inserting rating: $insertError');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('RatingService - Error submitting rating: $e');
      print('RatingService - Error type: ${e.runtimeType}');
      print('RatingService - Error details: ${e.toString()}');
      return false;
    }
  }

  // Delete user's rating
  static Future<bool> deleteRating(String productId, String customerId) async {
    try {
      await SupabaseService.instance.client
          .from('product_ratings')
          .delete()
          .eq('product_id', productId)
          .eq('customer_id', customerId);

      return true;
    } catch (e) {
      print('RatingService - Error deleting rating: $e');
      return false;
    }
  }

  // Get all reviews for a product
  static Future<List<ProductRating>> getProductReviews(String productId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('product_ratings')
          .select('*, customers(name, phone)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return response.map((json) => ProductRating.fromJson(json)).toList();
    } catch (e) {
      print('RatingService - Error getting product reviews: $e');
      return [];
    }
  }
}
