import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
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

  final Map<String, String> _documentNames = {
    'commercial_register': '',
    'national_address': '',
    'tax_number': '',
    'national_id': '',
  };

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
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
      final typeGroup = XTypeGroup(
        label: 'documents',
        extensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        setState(() {
          _uploadedDocuments[documentType] = true;
          _documentNames[documentType] = file.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفع ${file.name} بنجاح'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف الملف'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _submitDocuments() async {
    if (_uploadedDocuments.values.contains(false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى رفع جميع المستندات المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  Widget _buildDocumentCard(
      String title, String subtitle, String documentType) {
    final isUploaded = _uploadedDocuments[documentType]!;
    final fileName = _documentNames[documentType]!;

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
                Text(title,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    )),
                const SizedBox(height: 4),
                Text(isUploaded ? 'تم الرفع بنجاح' : subtitle,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 12,
                      color: isUploaded ? Colors.green[600] : Colors.grey[600],
                    )),
                if (isUploaded && fileName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(fileName,
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      )),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                isUploaded ? _deleteDocument(documentType) : _pickDocument(documentType),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isUploaded ? Colors.red[50] : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isUploaded ? Colors.red[200]! : Colors.transparent),
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
            'تسجيل تاجر جديد',
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
                            gradient: DesignSystem.primaryGradient,
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
                    const Text(
                      'الملفات المطلوبة',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
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
                    const Text(
                      'الملفات المطلوبة\nيرجى رفع جميع المستندات المطلوبة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 20,
                        color: Colors.black87,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDocumentCard(
                      'السجل التجاري',
                      'اضغط لرفع السجل التجاري',
                      'commercial_register',
                    ),
                    _buildDocumentCard(
                      'العنوان الوطني',
                      'اضغط لرفع العنوان الوطني',
                      'national_address',
                    ),
                    _buildDocumentCard(
                      'الرقم الضريبي',
                      'اضغط لرفع الرقم الضريبي',
                      'tax_number',
                    ),
                    _buildDocumentCard(
                      'الهوية الوطنية',
                      'اضغط لرفع الهوية الوطنية',
                      'national_id',
                    ),
                    const SizedBox(height: 32),
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'التالي',
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
