import 'dart:io';
import 'dart:typed_data';
// Lightweight path helpers to avoid extra deps
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

Future<String> createMerchant({
  required String storeName,
  required String ownerName,
  required String phoneE164,
  required String address,
}) async {
  final payload = {
    'store_name': storeName,   // ✅ only store_name
    'owner_name': ownerName,   // ✅ owner_name
    'phone': phoneE164,
    'address': address,
    // don't send 'status' (DB default = pending)
  };

  final rows = await _client.from('merchants').insert(payload).select();
  final row = rows.first as Map<String, dynamic>;
  return (row['merchant_id'] ?? row['id']).toString();
}



  Future<void> acceptTerms({required String merchantId}) async {
    await _client
        .from(_merchantsTable)
        .update({'terms_accepted_at': DateTime.now().toIso8601String()})
        .eq('merchant_id', merchantId);
  }

  Future<_UploadedInfo> _uploadToStorage({
    required String merchantId,
    required String docType,
    required String localFilePath,
    Uint8List? bytes,
  }) async {
    final String fileName = _basename(localFilePath);
    final String objectPath = '$merchantId/${docType}_$fileName';
    final String mime = _inferMimeType(localFilePath);

    final StorageFileApi bucket = _client.storage.from(_documentsBucket);
    if (bytes != null) {
      await bucket.uploadBinary(
        objectPath,
        bytes,
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );
    } else {
      await bucket.upload(
        objectPath,
        File(localFilePath),
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );
    }

    final String publicUrl = bucket.getPublicUrl(objectPath);
    return _UploadedInfo(
      fileName: fileName,
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
    final _UploadedInfo uploaded = await _uploadToStorage(
      merchantId: merchantId,
      docType: docType,
      localFilePath: localFilePath,
      bytes: bytes,
    );

    // Upsert document metadata
    final Map<String, dynamic> payload = {
      'merchant_id': merchantId,
      'doc_type': docType,
      'file_name': uploaded.fileName,
      'file_path': uploaded.publicUrl,
      'mime_type': uploaded.mimeType,
    };

    await _client
        .from(_merchantDocumentsTable)
        .upsert(payload, onConflict: 'merchant_id,doc_type');
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
