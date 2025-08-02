import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/product.dart';
import '../../core/constants/design_system.dart';
import '../../core/services/product_service.dart';

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
  final Product product;
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
  final List<Product> products;
  final List<Map<String, dynamic>> banners;
  final List<String> categories;
  final PageController bannerController;
  final Timer? bannerTimer;
  final bool isLoading;

  HomeLoaded({
    required this.selectedCategory,
    required this.isGridView,
    required this.currentBanner,
    required this.products,
    required this.banners,
    required this.categories,
    required this.bannerController,
    this.bannerTimer,
    this.isLoading = false,
  });

  HomeLoaded copyWith({
    int? selectedCategory,
    bool? isGridView,
    int? currentBanner,
    List<Product>? products,
    List<Map<String, dynamic>>? banners,
    List<String>? categories,
    PageController? bannerController,
    Timer? bannerTimer,
    bool? isLoading,
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
      isLoading: isLoading ?? this.isLoading,
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

  void _onHomeInitialized(
    HomeInitialized event,
    Emitter<HomeState> emit,
  ) async {
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

    try {
      // Fetch products from API
      final products = await ProductService.fetchProducts();

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
    } catch (e) {
      emit(HomeError('Failed to load products: $e'));
    }
  }

  void _onCategoryChanged(
    CategoryChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;

      // Show loading state
      emit(currentState.copyWith(isLoading: true));

      try {
        List<Product> filteredProducts;

        if (event.categoryIndex == 0) {
          // Fetch all products
          filteredProducts = await ProductService.fetchProducts();
        } else {
          // Fetch products by category
          final category = currentState.categories[event.categoryIndex];
          filteredProducts = await ProductService.fetchProductsByCategory(
            category,
          );
        }

        emit(
          currentState.copyWith(
            selectedCategory: event.categoryIndex,
            products: filteredProducts,
            isLoading: false,
          ),
        );
      } catch (e) {
        emit(HomeError('Failed to load products: $e'));
      }
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
