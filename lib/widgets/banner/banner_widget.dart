import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/design_system.dart';

class BannerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final PageController controller;
  final int currentBanner;
  final Function(int)? onPageChanged;

  const BannerWidget({
    super.key,
    required this.banners,
    required this.controller,
    required this.currentBanner,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // reduced from 120
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: banners.length,
            itemBuilder: (_, idx) => _buildBanner(banners[idx]),
          ),
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: currentBanner == i ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: currentBanner == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(Map<String, dynamic> banner) {
    final imageUrl = banner['imageUrl'] ?? banner['image_url'];
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      print('ERROR: No imageUrl found in ads data for banner: $banner');
      return Container();
    }

    print('Loading banner image: $imageUrl');

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      );
    } else {
      print('Loading asset image: $imageUrl');
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading asset image: $error');
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      );
    }
  }
}
