// lib/screens/merchant_documents_screen.dart
library merchant_documents_screen;

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../core/services/merchant_service.dart';
import '../core/constants/design_system.dart';
import '../core/routes/index.dart';
import '../utils/document_picker.dart';
import '../widgets/merchant/document_card.dart';
part 'functions/merchant_documents_screen.functions.dart';

class MerchantDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> merchantData;

  const MerchantDocumentsScreen({super.key, required this.merchantData});

  @override
  State<MerchantDocumentsScreen> createState() =>
      _MerchantDocumentsScreenState();
}

class _MerchantDocumentsScreenState extends State<MerchantDocumentsScreen>
    with TickerProviderStateMixin, MerchantDocumentsScreenFunctions {
  bool _isLoading = false;
  final Map<String, bool> _uploadedDocuments = {
    'commercial_register': false,
    'national_address': false,
    'tax_number': false,
    'national_id': false,
  };

  final Map<String, String?> _documentNames = {
    'commercial_register': '',
    'national_address': '',
    'tax_number': '',
    'national_id': '',
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      debugPrint('[MerchantDocuments] Start pick → docType=$documentType');
      final result = await DocumentPicker.pickViaDialog(context);
      if (result == null) {
        debugPrint('[MerchantDocuments] Picker dismissed');
        return;
      }
      final String? fileName = result.fileName;
      final String? localPath = result.localPath;
      final Uint8List? bytes = result.bytes;
      debugPrint(
        '[MerchantDocuments] Pick result → fileName=${fileName ?? 'null'}, path=${localPath ?? 'null'}, bytes=${bytes?.lengthInBytes ?? 0}',
      );

      if (fileName != null) {
        // Upload to Supabase storage + upsert metadata
        final String merchantId = (widget.merchantData['merchantId'] ?? '')
            .toString();
        if (merchantId.isEmpty) {
          throw Exception('merchantId is missing');
        }

        debugPrint(
          '[MerchantDocuments] Uploading → merchantId=$merchantId, docType=$documentType',
        );
        await MerchantService.instance.upsertDocument(
          merchantId: merchantId,
          docType: documentType,
          // Use fileName for mime inference if no path; pass bytes for robust uploads
          localFilePath: (localPath ?? fileName),
          bytes: bytes,
        );

        setState(() {
          _uploadedDocuments[documentType] = true;
          _documentNames[documentType] = fileName;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تم رفع الملف بنجاح',
                  style: TextStyle(fontFamily: 'Rubik'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MerchantDocuments][ERROR] $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'حدث خطأ أثناء رفع الملف',
                style: TextStyle(fontFamily: 'Rubik'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _deleteDocument(String documentType) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'حذف الملف',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف هذا الملف؟',
            style: TextStyle(fontFamily: 'Rubik', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Rubik', color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'حذف',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  color: Colors.red[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _uploadedDocuments[documentType] = false;
        _documentNames[documentType] = '';
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('تم حذف الملف بنجاح', style: TextStyle(fontFamily: 'Rubik')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _submitDocuments() async {
    // Check if all documents are uploaded
    bool allUploaded = _uploadedDocuments.values.every((uploaded) => uploaded);
    if (!allUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى رفع جميع المستندات المطلوبة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // No-op: already uploaded while selecting each document

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to merchant approval screen
    Navigator.pushNamed(
      context,
      AppRoutes.merchantApproval,
      arguments: {...widget.merchantData, 'documents': _documentNames},
    );
  }

  Widget _buildDocumentCard(
    String title,
    String subtitle,
    String documentType,
  ) {
    final isUploaded = _uploadedDocuments[documentType]!;
    final fileName = _documentNames[documentType] ?? '';
    return DocumentCard(
      title: title,
      subtitle: subtitle,
      isUploaded: isUploaded,
      fileName: fileName,
      onTap: () => isUploaded
          ? _deleteDocument(documentType)
          : _pickDocument(documentType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (isDark) {
              return const Text(
                'رفع المستندات',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }
            return ShaderMask(
              shaderCallback: (bounds) =>
                  DesignSystem.primaryGradient.createShader(bounds),
              child: const Text(
                'رفع المستندات',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: DesignSystem.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'رفع المستندات',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Documents Icon with Gradient Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: DesignSystem.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B46C1).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subtitle
                    Text(
                      'رفع المستندات المطلوبة\nلإكمال التسجيل',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        height: 1.8,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Document Cards
                    _buildDocumentCard(
                      'السجل التجاري',
                      'رفع صورة من السجل التجاري',
                      'commercial_register',
                    ),
                    _buildDocumentCard(
                      'العنوان الوطني',
                      'رفع صورة من العنوان الوطني',
                      'national_address',
                    ),
                    _buildDocumentCard(
                      'الرقم الضريبي',
                      'رفع صورة من الرقم الضريبي',
                      'tax_number',
                    ),
                    _buildDocumentCard(
                      'الهوية الوطنية',
                      'رفع صورة من الهوية الوطنية',
                      'national_id',
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: DesignSystem.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B46C1).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitDocuments,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'التالي',
                                style: TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
