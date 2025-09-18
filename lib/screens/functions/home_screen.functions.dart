part of home_screen;

mixin HomeScreenFunctions on State<HomeScreen> {
  Future<void> _loadProducts({bool showLoading = true}) async {
    try {
      if (showLoading && mounted) {
        (this as _HomeScreenState).setState(() {
          (this as _HomeScreenState)._isLoading = true;
        });
      }

      print('HomeScreen - Loading products from database...');
      print('HomeScreen - Testing database connection...');
      final connectionTest = await ProductService.testConnection();
      print('HomeScreen - Database connection test result: $connectionTest');

      print('HomeScreen - Testing database permissions...');
      final permissionsTest = await ProductService.testDatabasePermissions();
      print('HomeScreen - Database permissions test result: $permissionsTest');

      final hasData = await ProductService.hasProducts();
      print('HomeScreen - Products table has data: $hasData');

      if (!hasData) {
        print('HomeScreen - Products table is empty - adding sample products');
        final added = await ProductService.addSampleProducts();
        print('HomeScreen - Sample products added successfully: $added');
        if (!added) {
          print(
            'HomeScreen - Regular sample products failed, trying force populate...',
          );
          final forceAdded = await ProductService.forcePopulateProducts();
          print('HomeScreen - Force populate successful: $forceAdded');
          if (!forceAdded) {
            print('HomeScreen - Failed to add products');
            if (mounted) {
              (this as _HomeScreenState).setState(() {
                (this as _HomeScreenState)._isLoading = false;
              });
            }
            return;
          }
        }
      }

      final products = await ProductService.fetchProducts();
      print('HomeScreen - Loaded ${products.length} products from database');
      print(
        'HomeScreen - Products list: ${products.map((p) => p.name).toList()}',
      );

      if (mounted) {
        (this as _HomeScreenState).setState(() {
          (this as _HomeScreenState)._products = products;
          (this as _HomeScreenState)._isLoading = false;
        });
        print(
          'HomeScreen - Updated state with ${(this as _HomeScreenState)._products.length} products',
        );
      }
    } catch (e) {
      print('Error loading products from database: $e');
      if (mounted) {
        (this as _HomeScreenState).setState(() {
          (this as _HomeScreenState)._isLoading = false;
        });
        if (showLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل المنتجات: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted &&
        (this as _HomeScreenState)._products.isEmpty &&
        !(this as _HomeScreenState)._isLoading &&
        showLoading) {
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
      if (mounted) {
        (this as _HomeScreenState).setState(() {
          (this as _HomeScreenState)._isLoadingAds = true;
        });
      }

      final tableExists = await AdsService.tableExists();
      if (!tableExists) {
        print('Ads table does not exist or is not accessible');
        if (mounted) {
          (this as _HomeScreenState).setState(() {
            (this as _HomeScreenState)._isLoadingAds = false;
          });
        }
        return;
      }

      final hasData = await AdsService.hasAds();
      if (!hasData) {
        print('Ads table is empty - adding sample ads');
        final added = await AdsService.addSampleAds();
        if (!added) {
          print('Failed to add sample ads');
          if (mounted) {
            (this as _HomeScreenState).setState(() {
              (this as _HomeScreenState)._isLoadingAds = false;
            });
          }
          return;
        }
      }

      final ads = await AdsService.fetchAds();
      print('Loaded ${ads.length} ads from database');

      if (mounted) {
        (this as _HomeScreenState).setState(() {
          (this as _HomeScreenState)._ads = ads;
          (this as _HomeScreenState)._isLoadingAds = false;
        });
      }

      print(
        'Ads state updated, total ads: ${(this as _HomeScreenState)._ads.length}',
      );

      if ((this as _HomeScreenState)._ads.isNotEmpty) {
        print('=== DATABASE ADS INFORMATION ===');
        for (int i = 0; i < (this as _HomeScreenState)._ads.length; i++) {
          final ad = (this as _HomeScreenState)._ads[i];
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
        (this as _HomeScreenState).setState(() {
          (this as _HomeScreenState)._isLoadingAds = false;
        });
      }
    }
  }

  List<Products> _getProducts(String language) {
    if ((this as _HomeScreenState)._products.isNotEmpty) {
      print(
        'HomeScreen - Returning ${(this as _HomeScreenState)._products.length} products from database',
      );
      return (this as _HomeScreenState)._products;
    } else {
      print('HomeScreen - Using fallback static products');
      final staticProducts = HomeUtils.getProducts(language);
      print('HomeScreen - Static products count: ${staticProducts.length}');
      return staticProducts;
    }
  }

  List<Products> _getFilteredProducts(String language) {
    final products = _getProducts(language);
    if ((this as _HomeScreenState)._selectedCategory == 0) return products;
    final cat = (this as _HomeScreenState)
        ._categories[(this as _HomeScreenState)._selectedCategory];
    return products.where((p) => p.name.contains(cat)).toList();
  }

  void _addToCart(Products product) async {
    final appBloc = context.read<AppBloc>();
    HapticFeedback.lightImpact();
    if (mounted) {
      _showCartNotification(product);
    }
    // Set translationKey if not present
    String? translationKey = product.translationKey;
    if (translationKey == null || translationKey.isEmpty) {
      translationKey = _getTranslationKeyForProduct(product);
    }
    final Products productWithKey = Products(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      imageUrl: product.imageUrl,
      stockQuantity: product.stockQuantity,
      rating: product.rating,
      totalSold: product.totalSold,
      status: product.status,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      translationKey: translationKey,
    );
    appBloc.add(AddToCartEvent(productWithKey));
    _addToCartAsync(productWithKey);

  }

  String? _getTranslationKeyForProduct(Products product) {
    // Heuristic: match product name to translation keys
    final name = product.name;
    if (name.contains('330')) return 'product_name_1';
    if (name.contains('200')) return 'product_name_2';
    if (name.contains('500')) return 'product_name_3';
    if (name.contains('1')) return 'product_name_4';
    return null;
  }

  void _addToCartAsync(Products product) async {
    try {
      await CartManager.instance.addProduct(product.id);
      print('Successfully added ${product.name} to cart');
    } catch (e) {
      print('Error adding product to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المنتج إلى السلة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCartNotification(Products product) {
    if (!mounted) return;
    print('Showing cart notification for: ${product.name}');
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
                          duration: Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                        ),
                        ShakeEffect(
                          duration: Duration(milliseconds: 200),
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
                          ProductLocalizations.nameFor(
                            product,
                            context.watch<AppSettings>().currentLanguage,
                          ),
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
                      print('View cart button tapped');
                      overlayEntry.remove();
                      context.read<AppBloc>().add(SetCurrentIndexEvent(3));
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
                      child: const Text(
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
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    final imageUrl = banner['imageUrl'] as String?;
    print('Building banner with image: $imageUrl');
    if (imageUrl == null || imageUrl.isEmpty) {
      print('No image URL found, using fallback');
      return _buildBannerBackgroundImage('assets/icon/iconApp.png');
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(-1, 0),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(1, 0),
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

  Widget _buildBannerBackgroundImage(String? imageUrl) {
    print('Building background image with URL: $imageUrl');
    if (imageUrl == null || imageUrl.isEmpty) {
      print('No image URL provided, using fallback');
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
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('Loading network image: $imageUrl');
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network background image: $error');
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
