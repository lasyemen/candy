import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  // Auth methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  // Database operations
  Future<List<Map<String, dynamic>>> fetchData(String table) async {
    final response = await client.from(table).select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> fetchById(String table, String id) async {
    final response = await client.from(table).select().eq('id', id).single();
    return response;
  }

  Future<void> insertData(String table, Map<String, dynamic> data) async {
    await client.from(table).insert(data);
  }

  Future<void> updateData(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    await client.from(table).update(data).eq('id', id);
  }

  Future<void> deleteData(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }
}
