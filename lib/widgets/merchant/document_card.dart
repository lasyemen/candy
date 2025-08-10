import 'package:flutter/material.dart';

class DocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isUploaded;
  final String fileName;
  final VoidCallback onTap;
  const DocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isUploaded,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: isUploaded
                    ? LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Icon(
                isUploaded ? Icons.check : Icons.upload_file,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploaded ? 'تم الرفع بنجاح' : subtitle,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 11,
                      color: isUploaded ? Colors.green[600] : Colors.grey[600],
                    ),
                  ),
                  if (isUploaded && fileName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isUploaded ? Icons.delete_outline : Icons.add,
              color: isUploaded ? Colors.red[600] : Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
