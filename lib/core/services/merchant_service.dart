import 'dart:io';
import 'dart:typed_data';
// Lightweight path helpers to avoid extra deps
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class MerchantService {
  MerchantService._();

  static final MerchantService instance = MerchantService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Tables and buckets
  static const String _merchantsTable = 'merchants';
  static const String _merchantDocumentsTable = 'merchant_documents';
  static const String _documentsBucket = 'merchantsdocs';
  static const String _documentsRootPath = 'merchant-files';

  Future<String> createMerchant({
    required String storeName,
    required String ownerName,
    required String phoneE164,
    required String address,
  }) async {
    final payload = {
      'store_name': storeName, // ✅ only store_name
      'owner_name': ownerName, // ✅ owner_name
      'phone': phoneE164,
      'address': address,
      // don't send 'status' (DB default = pending)
    };

    final rows = await _client.from('merchants').insert(payload).select();
    final Map<String, dynamic> row = Map<String, dynamic>.from(rows.first);
    return (row['merchant_id'] ?? row['id']).toString();
  }

  Future<void> acceptTerms({required String merchantId}) async {
    await _client
        .from(_merchantsTable)
        .update({'terms_accepted_at': DateTime.now().toIso8601String()})
        .eq('merchant_id', merchantId);
  }

  Future<Map<String, dynamic>?> findMerchantByPhone(String phoneInput) async {
    try {
      // Try to normalize input to E.164 and match exactly (preferred)
      try {
        // Importing PhoneUtils here would create a cycle if placed at top; keep lightweight normalization
        final String digitsOnly = phoneInput.replaceAll(RegExp(r'[^0-9+]'), '');
        // If input already looks like +966... or starts with 966, try exact match on digits+plus
        if (digitsOnly.startsWith('+') || digitsOnly.length >= 9) {
          // First attempt exact equality on phone field (expects E.164 in DB)
          final exact = await _client
              .from(_merchantsTable)
              .select(
                'merchant_id, store_name, owner_name, phone, address, status',
              )
              .eq('phone', phoneInput)
              .maybeSingle();
          if (exact != null) return exact;
        }

        // Fallback: search by digits contained in phone (handles legacy non-normalized records)
        final digits = phoneInput.replaceAll(RegExp(r'[^0-9]'), '');
        final result = await _client
            .from(_merchantsTable)
            .select(
              'merchant_id, store_name, owner_name, phone, address, status',
            )
            .ilike('phone', '%$digits%')
            .maybeSingle();
        return result;
      } catch (e) {
        // If any DB error, return null
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<_UploadedInfo> _uploadToStorage({
    required String merchantId,
    required String docType,
    required String localFilePath,
    Uint8List? bytes,
  }) async {
    debugPrint(
      '[MerchantService] _uploadToStorage → merchantId=$merchantId, docType=$docType',
    );
    debugPrint(
      '[MerchantService] localFilePath="$localFilePath" bytes=${bytes?.lengthInBytes ?? 0}',
    );
    final String originalFileName = _basename(localFilePath);
    final String ext = _extension(originalFileName);
    // Generate an ASCII-only key: avoid spaces and non-ASCII by using timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String safeFileName =
        '${docType}_$timestamp${ext.isNotEmpty ? '.$ext' : ''}';
    // Store all uploads under a common root folder per merchant
    final String objectPath = '$_documentsRootPath/$merchantId/$safeFileName';
    final String mime = _inferMimeType(originalFileName);

    final StorageFileApi bucket = _client.storage.from(_documentsBucket);
    try {
      if (bytes != null) {
        debugPrint(
          '[MerchantService] Uploading via uploadBinary → path=$objectPath, mime=$mime',
        );
        await bucket.uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: true),
        );
      } else {
        if (!File(localFilePath).existsSync()) {
          throw Exception('Local file not found: "$localFilePath"');
        }
        debugPrint(
          '[MerchantService] Uploading via upload (File) → path=$objectPath, mime=$mime',
        );
        await bucket.upload(
          objectPath,
          File(localFilePath),
          fileOptions: FileOptions(contentType: mime, upsert: true),
        );
      }
    } catch (e) {
      final userId = _client.auth.currentUser?.id;
      debugPrint('[MerchantService][ERROR] Upload failed → $e');
      debugPrint('[MerchantService] auth.currentUser=${userId ?? 'null'}');
      rethrow;
    }

    final String publicUrl = bucket.getPublicUrl(objectPath);
    debugPrint('[MerchantService] Public URL generated: $publicUrl');
    return _UploadedInfo(
      fileName: originalFileName,
      path: objectPath,
      mimeType: mime,
      publicUrl: publicUrl,
    );
  }

  Future<void> upsertDocument({
    required String merchantId,
    required String docType,
    required String localFilePath,
    Uint8List? bytes,
  }) async {
    debugPrint(
      '[MerchantService] upsertDocument → merchantId=$merchantId, docType=$docType',
    );
    _UploadedInfo uploaded;
    try {
      uploaded = await _uploadToStorage(
        merchantId: merchantId,
        docType: docType,
        localFilePath: localFilePath,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint(
        '[MerchantService][ERROR] Upload step failed, skipping DB upsert. $e',
      );
      rethrow;
    }

    // Upsert document metadata
    final Map<String, dynamic> payload = {
      'merchant_id': merchantId,
      'doc_type': docType,
      'file_name': uploaded.fileName,
      'file_path': uploaded.publicUrl,
      'mime_type': uploaded.mimeType,
    };
    debugPrint(
      '[MerchantService] Upserting metadata into $_merchantDocumentsTable → $payload',
    );
    try {
      await _client
          .from(_merchantDocumentsTable)
          .upsert(payload, onConflict: 'merchant_id,doc_type');
    } catch (e) {
      debugPrint('[MerchantService][ERROR] Metadata upsert failed → $e');
      rethrow;
    }
  }
}

class _UploadedInfo {
  final String fileName;
  final String path;
  final String mimeType;
  final String publicUrl;

  _UploadedInfo({
    required this.fileName,
    required this.path,
    required this.mimeType,
    required this.publicUrl,
  });
}

String _inferMimeType(String path) {
  final String ext = _extension(path).toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'pdf':
      return 'application/pdf';
    case 'heic':
      return 'image/heic';
    default:
      return 'application/octet-stream';
  }
}

String _basename(String path) {
  if (path.isEmpty) return path;
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.isNotEmpty ? parts.last : path;
}

String _extension(String path) {
  final base = _basename(path);
  final dot = base.lastIndexOf('.');
  if (dot <= 0 || dot == base.length - 1) return '';
  return base.substring(dot + 1);
}
