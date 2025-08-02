import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../blocs/app_bloc.dart';
import '../core/models/water_product.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/design_system.dart';
import '../core/constants/translations.dart';
import '../core/services/app_settings.dart';
import '../widgets/riyal_icon.dart';
import '../widgets/home/home_product_card_widget.dart';
import '../widgets/home/home_search_delegate.dart';
import '../widgets/home/home_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  bool _isGridView = true;
  int _currentBanner = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'عرض خاص!',
      'subtitle': 'احصل على خصم ٢٠٪ على جميع منتجات كاندي',
      'image': 'assets/icon/iconApp.png',
      'color': const Color(0xFF6B46C1),
      'gradient': DesignSystem.primaryGradient, // Purple to Blue
      'icon': Icons.local_offer,
    },
    {
      'title': 'توصيل مجاني',
      'subtitle': 'للطلبات التي تزيد عن ٥٠ ريال',
      'image': 'assets/icon/iconApp.png',
      'color': const Color(0xFF6B46C1),
      'gradient': DesignSystem.primaryGradient, // Purple to Blue
      'icon': Icons.delivery_dining,
    },
    {
      'title': 'مياه معدنية طبيعية',
      'subtitle': 'جودة عالية مع معادن طبيعية مفيدة',
      'image': 'assets/icon/iconApp.png',
      'color': const Color(0xFF6B46C1),
      'gradient': DesignSystem.primaryGradient, // Purple to Blue
      'icon': Icons.water_drop,
    },
  ];

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
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  List<WaterProduct> _getProducts(String language) {
    return [
      WaterProduct(
        id: '1',
        name: language == 'ar' ? 'كاندي ٣٣٠ مل' : 'Candy 330ml',
        price: 21.84,
        size: 330,
        image: 'assets/icon/iconApp.png',
        rating: 4.5,
        reviewCount: 120,
        description: 'مياه نقية مع معادن طبيعية',
        discount: 15.0,
      ),
      WaterProduct(
        id: '2',
        name: language == 'ar' ? 'كاندي ٢٠٠ مل' : 'Candy 200ml',
        price: 21.84,
        size: 200,
        image: 'assets/icon/iconApp.png',
        rating: 4.8,
        reviewCount: 95,
        description: 'مياه نقية للاستخدام اليومي',
      ),
      WaterProduct(
        id: '3',
        name: language == 'ar' ? 'كاندي ٥٠٠ مل' : 'Candy 500ml',
        price: 25.50,
        size: 500,
        image: 'assets/icon/iconApp.png',
        rating: 4.2,
        reviewCount: 78,
        description: 'مياه معدنية طبيعية',
        discount: 20.0,
      ),
      WaterProduct(
        id: '4',
        name: language == 'ar' ? 'كاندي ١ لتر' : 'Candy 1L',
        price: 30.00,
        size: 1000,
        image: 'assets/icon/iconApp.png',
        rating: 4.7,
        reviewCount: 45,
        description: 'مياه نقية للعائلة',
      ),
      WaterProduct(
        id: '5',
        name: language == 'ar' ? 'كاندي معدنية' : 'Candy Mineral',
        price: 35.00,
        size: 500,
        image: 'assets/icon/iconApp.png',
        rating: 4.6,
        reviewCount: 200,
        description: 'مياه معدنية غنية بالمعادن',
        discount: 10.0,
      ),
      WaterProduct(
        id: '6',
        name: language == 'ar' ? 'كاندي غازية' : 'Candy Sparkling',
        price: 28.00,
        size: 330,
        image: 'assets/icon/iconApp.png',
        rating: 4.9,
        reviewCount: 67,
        description: 'مياه غازية منعشة',
      ),
    ];
  }

  List<WaterProduct> _getFilteredProducts(String language) {
    final products = _getProducts(language);
    if (_selectedCategory == 0) return products;
    final cat = _categories[_selectedCategory];
    return products.where((p) => p.name.contains(cat)).toList();
  }

  void _addToCart(WaterProduct product) {
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
                        Text(
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
                          '${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
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

  String _getProductDescription(WaterProduct product) {
    if (product.size == 330) return '١ كرتون - ٤٠ عبوة بلاستيك';
    if (product.size == 200) return '١ كرتون - ٤٨ عبوة بلاستيك';
    if (product.size == 500) return '١ كرتون - ٢٤ عبوة بلاستيك';
    if (product.size == 1000) return '١ كرتون - ١٢ عبوة بلاستيك';
    return '١ كرتون - ٢٠ عبوة بلاستيك';
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
                  height: 220,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        controller: _bannerController,
                        onPageChanged: (idx) =>
                            setState(() => _currentBanner = idx),
                        itemCount: _banners.length,
                        itemBuilder: (_, idx) =>
                            _buildBannerItem(_banners[idx]),
                      ),
                      Positioned(
                        bottom: 12,
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
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromARGB(
                                        255,
                                        179,
                                        58,
                                        255,
                                      ), // Purple
                                      Color.fromARGB(255, 23, 6, 212), // Blue
                                    ],
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
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromARGB(
                                        255,
                                        179,
                                        58,
                                        255,
                                      ), // Purple
                                      Color.fromARGB(255, 23, 6, 212), // Blue
                                    ],
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
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color.fromARGB(
                                                  255,
                                                  179,
                                                  58,
                                                  255,
                                                ), // Purple
                                                Color.fromARGB(
                                                  255,
                                                  23,
                                                  6,
                                                  212,
                                                ), // Blue
                                              ],
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
              // Toggle view
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Text(
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 179, 58, 255), // Purple
                        Color.fromARGB(255, 23, 6, 212), // Blue
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'الاسعار شاملة ضريبة القيمة المضافة',
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
                sliver: products.isEmpty
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
                                "لا يوجد منتجات في هذا القسم حاليا.",
                                style: TextStyle(
                                  color: Color(0xFF6B46C1),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _isGridView
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 8,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) => HomeProductCardWidget(
                            product: products[idx],
                            onAddToCart: () => _addToCart(products[idx]),
                            getProductDescription: _getProductDescription,
                          ),
                          childCount: products.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: HomeProductCardWidget(
                              product: products[idx],
                              onAddToCart: () => _addToCart(products[idx]),
                              getProductDescription: _getProductDescription,
                            ),
                          ),
                          childCount: products.length,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: banner['gradient'] as LinearGradient,
        boxShadow: [
          BoxShadow(
            color: banner['color'].withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: banner['color'].withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          banner['icon'] ?? Icons.star,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          banner['title'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                      center: Alignment.center,
                      radius: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Image.asset(
                      banner['image'] as String,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
