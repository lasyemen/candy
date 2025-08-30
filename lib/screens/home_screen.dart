// lib/screens/home_screen.dart
library home_screen;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../blocs/app_bloc.dart';
import '../core/constants/design_system.dart';
import '../core/services/app_settings.dart';
import '../widgets/riyal_icon.dart';
import '../widgets/home/home_product_card_widget.dart';
import '../widgets/home/home_search_delegate.dart';
import '../models/index.dart';
import '../core/services/product_service.dart';
import '../core/services/ads_service.dart';
import '../core/utils/home_utils.dart';
import '../core/services/cart_service.dart';
part 'functions/home_screen.functions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  int _currentBanner = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;
  List<Products> _products = [];
  List<Ads> _ads = [];
  bool _isLoading = true;
  bool _isLoadingAds = true;

  List<Map<String, dynamic>> get _banners {
    print('Current ads count: ${_ads.length}'); // Debug log
    print('Ads list: $_ads'); // Debug: show the actual ads list

    if (_ads.isEmpty) {
      print('No ads loaded, showing fallback banners');
      // Fallback banners if no ads are loaded
      return [
        {
          'title': 'عرض خاص!',
          'subtitle': 'احصل على خصم ٢٠٪ على جميع منتجات كاندي',
          'image': 'https://picsum.photos/400/200?random=fallback1',
          'color': const Color(0xFF6B46C1),
          'gradient': DesignSystem.primaryGradient,
          'icon': Icons.local_offer,
        },
        {
          'title': 'توصيل مجاني',
          'subtitle': 'للطلبات التي تزيد عن ٥٠ ريال',
          'image': 'https://picsum.photos/400/200?random=fallback2',
          'color': const Color(0xFF6B46C1),
          'gradient': DesignSystem.primaryGradient,
          'icon': Icons.delivery_dining,
        },
      ];
    }

    print('Converting ${_ads.length} ads to banners');
    // Convert ads to banner format
    return _ads.map((ad) {
      print('Processing ad: ID=${ad.id}, ImageURL=${ad.imageUrl}');
      return {
        'title': 'إعلان كاندي',
        'subtitle': 'عرض خاص من كاندي',
        'image': ad.imageUrl,
        'color': const Color(0xFF6B46C1),
        'gradient': DesignSystem.primaryGradient,
        'icon': Icons.local_offer,
        'ad_id': ad.id, // Add ad ID for debugging
      };
    }).toList();
  }

  final List<String> _categories = [
    'الكل',
    '330 مل',
    '200 مل',
    '500 مل',
    '1 لتر',
    'معدنية',
    'غازية',
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_bannerController.hasClients && mounted) {
        int next = (_currentBanner + 1) % _banners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    _loadProducts();
    _loadAds();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final products = await ProductService.fetchProducts();

      print('Loaded ${products.length} products from database');

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المنتجات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // If no products loaded and no error, show empty state
    if (mounted && _products.isEmpty && !_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد منتجات في قاعدة البيانات'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _loadAds() async {
    try {
      print('Loading ads from database...');
      setState(() {
        _isLoadingAds = true;
      });

      final ads = await AdsService.fetchAds();
      print('Loaded ${ads.length} ads from database');

      if (mounted) {
        setState(() {
          _ads = ads;
          _isLoadingAds = false;
        });
      }

      print('Ads state updated, total ads: ${_ads.length}');

      // Display ads information
      if (_ads.isNotEmpty) {
        print('=== DATABASE ADS INFORMATION ===');
        for (int i = 0; i < _ads.length; i++) {
          final ad = _ads[i];
          print('Ad ${i + 1}:');
          print('  ID: ${ad.id}');
          print('  Image URL: ${ad.imageUrl}');
          print('  Created: ${ad.createdAt}');
          print('  Will be displayed as banner');
          print('---');
        }
      } else {
        print('No ads found in database - showing fallback banners');
      }
    } catch (e) {
      print('Error loading ads from database: $e');
      if (mounted) {
        setState(() {
          _isLoadingAds = false;
        });
      }
    }
  }

  List<Products> _getProducts(String language) {
    // Return products from Supabase only
    return _products;
  }

  List<Products> _getFilteredProducts(String language) {
    final products = _getProducts(language);
    if (_selectedCategory == 0) return products;
    final cat = _categories[_selectedCategory];
    return products.where((p) => p.name.contains(cat)).toList();
  }

  void _addToCart(Products product) {
    final appBloc = context.read<AppBloc>();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Add product to cart
    appBloc.add(AddToCartEvent(product));

    // Show success message with enhanced design at top
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: DesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Animate(
                      effects: const [
                        ScaleEffect(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                        ShakeEffect(
                          duration: Duration(milliseconds: 300),
                          hz: 3,
                        ),
                      ],
                      child: Icon(
                        FontAwesomeIcons.cartShopping,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'تم إضافة المنتج للسلة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'Rubik',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.price.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const RiyalIcon(size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      overlayEntry.remove();
                      appBloc.add(SetCurrentIndexEvent(3)); // Cart is index 3
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'عرض السلة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Rubik',
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
    );

    overlay.insert(overlayEntry);

    // Remove the overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, appSettings, child) {
        final lang = appSettings.currentLanguage;
        final products = _getFilteredProducts(lang);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: ShaderMask(
              shaderCallback: (Rect bounds) {
                return DesignSystem.getBrandGradient(
                  'primary',
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Text(
                'مياه كاندي',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF6B46C1)),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: HomeSearchDelegate(
                      allProducts: _getProducts(lang),
                      onProductTap: (prod) => _addToCart(prod),
                    ),
                  );
                },
              ),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Banner carousel
              SliverToBoxAdapter(
                child: Container(
                  height: 320,
                  margin: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 8,
                    bottom: 32,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      _isLoadingAds
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6B46C1),
                              ),
                            )
                          : PageView.builder(
                              controller: _bannerController,
                              onPageChanged: (idx) =>
                                  setState(() => _currentBanner = idx),
                              itemCount: _banners.length,
                              itemBuilder: (_, idx) =>
                                  _buildBannerItem(_banners[idx]),
                            ),
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_banners.length, (i) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: _currentBanner == i ? 20 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentBanner == i
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
                ),
              ),
              // Categories
              SliverToBoxAdapter(
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 14,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, idx) {
                      final isSelected = _selectedCategory == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: isSelected
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 179, 58, 255),
                                      Color.fromARGB(255, 23, 6, 212),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: DesignSystem.getBrandShadow(
                                    'medium',
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () =>
                                        setState(() => _selectedCategory = idx),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        _categories[idx],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 179, 58, 255),
                                      Color.fromARGB(255, 23, 6, 212),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => setState(
                                        () => _selectedCategory = idx,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        child: ShaderMask(
                                          shaderCallback: (Rect bounds) {
                                            return const LinearGradient(
                                              colors: [
                                                Color.fromARGB(
                                                  255,
                                                  179,
                                                  58,
                                                  255,
                                                ),
                                                Color.fromARGB(255, 23, 6, 212),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.srcIn,
                                          child: Text(
                                            _categories[idx],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
              // Toggle view label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: const [
                      Text(
                        'المنتجات',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Info bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 179, 58, 255),
                        Color.fromARGB(255, 23, 6, 212),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'الاسعار شاملة ضريبة القيمة المضافة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Product List/Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                sliver: _isLoading
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Color(0xFF6B46C1),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'جاري تحميل المنتجات...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : products.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inbox_rounded,
                                color: Color(0xFF6B46C1),
                                size: 40,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                "لا يوجد منتجات متاحة حالياً.",
                                style: TextStyle(
                                  color: Color(0xFF6B46C1),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65, // taller cards
                              crossAxisSpacing: 4, // reduced gap
                              mainAxisSpacing: 10,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) => HomeProductCardWidget(
                            product: products[idx],
                            onAddToCart: () => _addToCart(products[idx]),
                          ),
                          childCount: products.length,
                        ),
                      ),
              ),
              // Bottom padding to prevent navigation bar from covering last items
              SliverToBoxAdapter(
                child: Container(
                  height:
                      100, // Adjust this value based on your navigation bar height
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    final imageUrl = banner['image'] as String;
    print('Building banner with image: $imageUrl');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(35)),
        clipBehavior: Clip.antiAlias,
        child: _buildBannerBackgroundImage(imageUrl),
      ),
    );
  }

  Widget _buildBannerBackgroundImage(String imageUrl) {
    print('Building background image with URL: $imageUrl');

    // Check if it's a network image (starts with http or https)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('Loading network image: $imageUrl');
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network background image: $error');
          // Fallback to local asset if network fails
          return Image.asset(
            'assets/icon/iconApp.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, assetError, stackTrace) {
              print('Error loading fallback asset image: $assetError');
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('Network image loaded successfully');
            return child;
          }
          print(
            'Loading network image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}',
          );
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 3,
                color: Colors.grey[600],
              ),
            ),
          );
        },
      );
    } else {
      // Local asset image
      print('Loading asset image: $imageUrl');
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading asset background image: $error');
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 60,
                color: Colors.grey[600],
              ),
            ),
          );
        },
      );
    }
  }
}
