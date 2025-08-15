import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/design_system.dart';

class PickedFileData {
  final String? fileName;
  final String? localPath;
  final Uint8List? bytes;
  const PickedFileData({this.fileName, this.localPath, this.bytes});
}

class DocumentPicker {
  static Future<PickedFileData?> pickViaDialog(BuildContext context) async {
    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF121212)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 80,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: DesignSystem.primaryGradient,
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'اختر طريقة الرفع',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _optionTile(
                context,
                icon: Icons.image,
                title: 'معرض الصور',
                subtitle: 'اختر صورة من المعرض',
                value: 'gallery',
              ),
              Divider(height: 1, color: Colors.grey[200]),
              _optionTile(
                context,
                icon: Icons.camera_alt,
                title: 'الكاميرا',
                subtitle: 'التقاط صورة جديدة',
                value: 'camera',
              ),
              Divider(height: 1, color: Colors.grey[200]),
              _optionTile(
                context,
                icon: Icons.folder,
                title: 'الملفات',
                subtitle: 'اختر ملف من الجهاز',
                value: 'files',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (choice == null) return null;

    String? fileName;
    String? localPath;
    Uint8List? bytes;

    if (choice == 'gallery') {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        fileName = image.name;
        localPath = image.path;
        try {
          bytes = await image.readAsBytes();
        } catch (_) {}
      }
    } else if (choice == 'camera') {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        fileName = image.name;
        localPath = image.path;
        try {
          bytes = await image.readAsBytes();
        } catch (_) {}
      }
    } else if (choice == 'files') {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'heic'],
      );
      if (result != null) {
        fileName = result.files.first.name;
        localPath = result.files.first.path;
        bytes = result.files.first.bytes;
        if (bytes == null && localPath != null) {
          try {
            bytes = await File(localPath).readAsBytes();
          } catch (_) {}
        }
      }
    }

    return PickedFileData(
      fileName: fileName,
      localPath: localPath,
      bytes: bytes,
    );
  }

  static Widget _optionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: DesignSystem.primaryGradient,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 11,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.grey[600],
        ),
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
