import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/water_product.dart';
import '../../core/constants/design_system.dart';

// Events
abstract class HomeEvent {}

class HomeInitialized extends HomeEvent {}

class CategoryChanged extends HomeEvent {
  final int categoryIndex;
  CategoryChanged(this.categoryIndex);
}

class ViewToggleChanged extends HomeEvent {
  final bool isGridView;
  ViewToggleChanged(this.isGridView);
}

class BannerPageChanged extends HomeEvent {
  final int pageIndex;
  BannerPageChanged(this.pageIndex);
}

class ProductAddedToCart extends HomeEvent {
  final WaterProduct product;
  ProductAddedToCart(this.product);
}

// States
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final int selectedCategory;
  final bool isGridView;
  final int currentBanner;
  final List<WaterProduct> products;
  final List<Map<String, dynamic>> banners;
  final List<String> categories;
  final PageController bannerController;
  final Timer? bannerTimer;

  HomeLoaded({
    required this.selectedCategory,
    required this.isGridView,
    required this.currentBanner,
    required this.products,
    required this.banners,
    required this.categories,
    required this.bannerController,
    this.bannerTimer,
  });

  HomeLoaded copyWith({
    int? selectedCategory,
    bool? isGridView,
    int? currentBanner,
    List<WaterProduct>? products,
    List<Map<String, dynamic>>? banners,
    List<String>? categories,
    PageController? bannerController,
    Timer? bannerTimer,
  }) {
    return HomeLoaded(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isGridView: isGridView ?? this.isGridView,
      currentBanner: currentBanner ?? this.currentBanner,
      products: products ?? this.products,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      bannerController: bannerController ?? this.bannerController,
      bannerTimer: bannerTimer ?? this.bannerTimer,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<HomeInitialized>(_onHomeInitialized);
    on<CategoryChanged>(_onCategoryChanged);
    on<ViewToggleChanged>(_onViewToggleChanged);
    on<BannerPageChanged>(_onBannerPageChanged);
    on<ProductAddedToCart>(_onProductAddedToCart);
  }

  void _onHomeInitialized(HomeInitialized event, Emitter<HomeState> emit) {
    emit(HomeLoading());

    final bannerController = PageController();
    final categories = [
      'الكل',
      '330 مل',
      '200 مل',
      '500 مل',
      '1 لتر',
      'معدنية',
      'غازية',
    ];

    final banners = [
      {
        'title': 'عرض خاص!',
        'subtitle': 'احصل على خصم ٢٠٪ على جميع منتجات كاندي',
        'image': 'assets/icon/iconApp.png',
        'color': const Color(0xFF6B46C1),
        'gradient': DesignSystem.primaryGradient,
        'icon': Icons.local_offer,
      },
      {
        'title': 'توصيل مجاني',
        'subtitle': 'للطلبات التي تزيد عن ٥٠ ريال',
        'image': 'assets/icon/iconApp.png',
        'color': const Color(0xFF6B46C1),
        'gradient': DesignSystem.primaryGradient,
        'icon': Icons.delivery_dining,
      },
      {
        'title': 'مياه معدنية طبيعية',
        'subtitle': 'جودة عالية مع معادن طبيعية مفيدة',
        'image': 'assets/icon/iconApp.png',
        'color': const Color(0xFF6B46C1),
        'gradient': DesignSystem.primaryGradient,
        'icon': Icons.water_drop,
      },
    ];

    final products = _getProducts();

    // Start banner timer
    final bannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (bannerController.hasClients) {
        int next = (0 + 1) % banners.length;
        bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    emit(
      HomeLoaded(
        selectedCategory: 0,
        isGridView: true,
        currentBanner: 0,
        products: products,
        banners: banners,
        categories: categories,
        bannerController: bannerController,
        bannerTimer: bannerTimer,
      ),
    );
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final filteredProducts = _getFilteredProducts(
        currentState.products,
        event.categoryIndex,
        currentState.categories,
      );

      emit(
        currentState.copyWith(
          selectedCategory: event.categoryIndex,
          products: filteredProducts,
        ),
      );
    }
  }

  void _onViewToggleChanged(ViewToggleChanged event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(isGridView: event.isGridView));
    }
  }

  void _onBannerPageChanged(BannerPageChanged event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(currentBanner: event.pageIndex));
    }
  }

  void _onProductAddedToCart(
    ProductAddedToCart event,
    Emitter<HomeState> emit,
  ) {
    // Handle adding product to cart
    // This would typically interact with a cart bloc or service
  }

  List<WaterProduct> _getProducts() {
    return [
      WaterProduct(
        id: '1',
        name: 'كاندي ٣٣٠ مل',
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
        name: 'كاندي ٢٠٠ مل',
        price: 21.84,
        size: 200,
        image: 'assets/icon/iconApp.png',
        rating: 4.8,
        reviewCount: 95,
        description: 'مياه نقية للاستخدام اليومي',
      ),
      WaterProduct(
        id: '3',
        name: 'كاندي ٥٠٠ مل',
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
        name: 'كاندي ١ لتر',
        price: 30.00,
        size: 1000,
        image: 'assets/icon/iconApp.png',
        rating: 4.7,
        reviewCount: 45,
        description: 'مياه نقية للعائلة',
      ),
      WaterProduct(
        id: '5',
        name: 'كاندي معدنية',
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
        name: 'كاندي غازية',
        price: 28.00,
        size: 330,
        image: 'assets/icon/iconApp.png',
        rating: 4.9,
        reviewCount: 67,
        description: 'مياه غازية منعشة',
      ),
    ];
  }

  List<WaterProduct> _getFilteredProducts(
    List<WaterProduct> products,
    int selectedCategory,
    List<String> categories,
  ) {
    if (selectedCategory == 0) return products;
    final cat = categories[selectedCategory];
    return products.where((p) => p.name.contains(cat)).toList();
  }

  @override
  Future<void> close() {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      currentState.bannerTimer?.cancel();
      currentState.bannerController.dispose();
    }
    return super.close();
  }
}
