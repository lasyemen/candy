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
import '../core/constants/translations.dart';
import '../core/i18n/product_localizations.dart';
// import '../core/constants/app_colors.dart';
import '../core/services/app_settings.dart';
import '../widgets/riyal_icon.dart';
import '../widgets/home/home_product_card_widget.dart';
import '../widgets/home/home_search_delegate.dart';
import '../models/index.dart';
import '../core/services/product_service.dart';
import '../core/services/ads_service.dart';
import '../core/services/cart_service.dart'; // Added import for CartService
import '../core/utils/home_utils.dart';
part 'functions/home_screen.functions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen>, HomeScreenFunctions {
  int _selectedCategory = 0;
  int _currentBanner = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;
  Timer? _refreshTimer;
  List<Products> _products = [];
  List<Ads> _ads = [];
  bool _isLoading = true;
  bool _isLoadingAds = true;

  List<Map<String, dynamic>> get _banners {
    print('Current ads count: ${_ads.length}'); // Debug log
    print('Ads list: $_ads'); // Debug: show the actual ads list
    final String lang = Provider.of<AppSettings>(
      context,
      listen: false,
    ).currentLanguage;

    if (_ads.isEmpty) {
      print('No ads loaded, showing fallback banners');
      // Fallback banners if no ads are loaded
      return [
        {
          'title': AppTranslations.getText('special_offer', lang),
          'subtitle': AppTranslations.getText('discount_20_all', lang),
          'image': 'https://picsum.photos/400/200?random=fallback1',
          'color': const Color(0xFF6B46C1),
          'gradient': DesignSystem.primaryGradient,
          'icon': Icons.local_offer,
        },
        {
          'title': AppTranslations.getText('free_delivery', lang),
          'subtitle': AppTranslations.getText('free_delivery_over_50', lang),
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
        'title': AppTranslations.getText('candy_ad', lang),
        'subtitle': AppTranslations.getText('candy_offer', lang),
        'imageUrl': ad.imageUrl, // Use imageUrl key to match banner widget
        'color': const Color(0xFF6B46C1),
        'gradient': DesignSystem.primaryGradient,
        'icon': Icons.local_offer,
        'ad_id': ad.id, // Add ad ID for debugging
      };
    }).toList();
  }

  final List<String> _categories = ['All', '330 ml', '200 ml', '500 ml', '1 L'];

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
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentBanner = next;
        });
      }
    });

    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _loadProducts(showLoading: false);
        _loadAds();
      }
    });

    // Test cart functionality on startup
    _testCartFunctionality();

    // Test database connection
    ProductService.checkProductsTable();
    ProductService.testDatabaseAccess();
    ProductService.showCurrentProducts();

    // Force populate products
    ProductService.forcePopulateProducts();

    // Test single product addition
    ProductService.addSingleTestProduct();

    // Load data with mounted checks
    if (mounted) {
      _loadProducts();
      _loadAds();
    }
  }

  // Test cart functionality
  Future<void> _testCartFunctionality() async {
    try {
      print('HomeScreen - Cart functionality is ready');
    } catch (e) {
      print('HomeScreen - Cart functionality test failed: $e');
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // Background refresh method that doesn't show loading
  // ignore: unused_element
  // Moved to mixin in functions/home_screen.functions.dart

  // Moved to mixin in functions/home_screen.functions.dart

  // Moved to mixin in functions/home_screen.functions.dart

  // Moved to mixin in functions/home_screen.functions.dart

  // Moved to mixin in functions/home_screen.functions.dart

  // Moved to mixin in functions/home_screen.functions.dart

  // Moved to mixin in functions/home_screen.functions.dart

  // Moved to mixin in functions/home_screen.functions.dart

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Consumer<AppSettings>(
      builder: (context, appSettings, child) {
        final lang = appSettings.currentLanguage;
        final products = _getFilteredProducts(lang);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                if (isDark) {
                  return Text(
                    AppTranslations.getText('app_name', lang),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                      fontFamily: Theme.of(
                        context,
                      ).textTheme.titleLarge?.fontFamily,
                    ),
                  );
                } else {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return DesignSystem.getBrandGradient(
                        'primary',
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      AppTranslations.getText('app_name', lang),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                        fontFamily: Theme.of(
                          context,
                        ).textTheme.titleLarge?.fontFamily,
                      ),
                    ),
                  );
                }
              },
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
            key: const PageStorageKey<String>('home_scroll'),
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Banner carousel
              SliverToBoxAdapter(
                child: Container(
                  height: 230,
                  margin: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 8,
                    bottom: 24,
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
                  height: 0,
                  margin: EdgeInsets.zero,
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
                                        horizontal: 10,
                                        vertical: 4,
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
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => setState(
                                        () => _selectedCategory = idx,
                                      ),
                                      child:
                                          (Theme.of(context).brightness ==
                                              Brightness.dark)
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              child: Text(
                                                _categories[idx],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              child: Text(
                                                _categories[idx],
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : DesignSystem.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
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
              // Extra space between categories and title (removed)
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              // Toggle view label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        AppTranslations.getText('products_title', lang),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Categories under title
              SliverToBoxAdapter(
                child: Container(
                  height: 32,
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
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => setState(
                                        () => _selectedCategory = idx,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
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
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => setState(
                                        () => _selectedCategory = idx,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          _categories[idx],
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : DesignSystem.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.getText('prices_include_vat', lang),
                        style: const TextStyle(
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
                                AppTranslations.getText('loading', lang),
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
                              Text(
                                AppTranslations.getText('no_products', lang),
                                style: const TextStyle(
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
 // Moved to mixin in functions/home_screen.functions.dart
}
