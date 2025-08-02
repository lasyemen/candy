import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/design_system.dart';
import '../core/routes/index.dart';

class MerchantDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> merchantData;

  const MerchantDocumentsScreen({super.key, required this.merchantData});

  @override
  State<MerchantDocumentsScreen> createState() =>
      _MerchantDocumentsScreenState();
}

class _MerchantDocumentsScreenState extends State<MerchantDocumentsScreen>
    with TickerProviderStateMixin {
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
      // Show options dialog
      final String? choice = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'اختر طريقة الرفع',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.image, color: Colors.blue),
                  title: Text(
                    'معرض الصور',
                    style: TextStyle(fontFamily: 'Rubik'),
                  ),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.green),
                  title: Text(
                    'الكاميرا',
                    style: TextStyle(fontFamily: 'Rubik'),
                  ),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: Icon(Icons.folder, color: Colors.orange),
                  title: Text('الملفات', style: TextStyle(fontFamily: 'Rubik')),
                  onTap: () => Navigator.pop(context, 'files'),
                ),
              ],
            ),
          );
        },
      );

      if (choice == null) return;

      String? fileName;
      if (choice == 'gallery') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (image != null) {
          fileName = image.name;
        }
      } else if (choice == 'camera') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          fileName = image.name;
        }
      } else if (choice == 'files') {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          fileName = result.files.first.name;
        }
      }

      if (fileName != null) {
        setState(() {
          _uploadedDocuments[documentType] = true;
          _documentNames[documentType] = fileName;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء رفع الملف'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteDocument(String documentType) {
    setState(() {
      _uploadedDocuments[documentType] = false;
      _documentNames[documentType] = '';
    });
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

    await Future.delayed(const Duration(seconds: 2));

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isUploaded ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUploaded ? Icons.check : Icons.upload_file,
              color: isUploaded ? Colors.white : Colors.grey[600],
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUploaded ? 'تم الرفع بنجاح' : subtitle,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 12,
                    color: isUploaded ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
                if (isUploaded && fileName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => isUploaded
                ? _deleteDocument(documentType)
                : _pickDocument(documentType),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isUploaded ? Colors.red[50] : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUploaded ? Colors.red[200]! : Colors.transparent,
                ),
              ),
              child: Icon(
                isUploaded ? Icons.delete_outline : Icons.add,
                color: isUploaded ? Colors.red[600] : Colors.grey[600],
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
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
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 20,
                        color: Colors.black87,
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
