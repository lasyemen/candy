part of product_details_screen;

mixin ProductDetailsScreenFunctions on State<ProductDetailsScreen> {
  Future<void> _loadRatingData() async {
    if (!CustomerSession.instance.isLoggedIn) {
      if (!(this as _ProductDetailsScreenState)._isDisposed) {
        (this as _ProductDetailsScreenState).setState(() {
          (this as _ProductDetailsScreenState)._isLoadingRating = false;
        });
      }
      return;
    }

    try {
      final customerId = CustomerSession.instance.currentCustomerId!;
      final tableAccess = await RatingService.testTableAccess();
      if (!tableAccess) {
        print('RatingService - Table access failed, cannot load rating data');
        if (!(this as _ProductDetailsScreenState)._isDisposed) {
          (this as _ProductDetailsScreenState).setState(() {
            (this as _ProductDetailsScreenState)._isLoadingRating = false;
          });
        }
        return;
      }

      final results = await Future.wait([
        RatingService.getProductRatingSummary(widget.product.id),
        RatingService.getUserRating(widget.product.id, customerId),
      ]);

      if (!(this as _ProductDetailsScreenState)._isDisposed) {
        (this as _ProductDetailsScreenState).setState(() {
          (this as _ProductDetailsScreenState)._ratingSummary =
              results[0] as ProductRatingSummary?;
          (this as _ProductDetailsScreenState)._userRating =
              results[1] as ProductRating?;
          (this as _ProductDetailsScreenState)._isLoadingRating = false;

          if ((this as _ProductDetailsScreenState)._userRating != null) {
            (this as _ProductDetailsScreenState)._selectedRating =
                (this as _ProductDetailsScreenState)._userRating!.rating
                    .toDouble();
            (this as _ProductDetailsScreenState)._reviewController.text =
                (this as _ProductDetailsScreenState)._userRating!.review ?? '';
          }
        });
      }
    } catch (e) {
      print('Error loading rating data: $e');
      if (!(this as _ProductDetailsScreenState)._isDisposed) {
        (this as _ProductDetailsScreenState).setState(() {
          (this as _ProductDetailsScreenState)._isLoadingRating = false;
        });
      }
    }
  }

  Widget _buildAddToCartButton() => Material(
    color: Colors.transparent,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          HapticFeedback.lightImpact();
          if (mounted) {
            _showCartNotification();
          }
          _addToCartAsync();
        },
        child: Center(
          child: Text(
            AppTranslations.getText(
              'add_to_cart',
              Provider.of<AppSettings>(context).currentLanguage,
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textInverse,
              fontFamily: 'Rubik',
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _submitRating() async {
    if (!CustomerSession.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to rate the product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if ((this as _ProductDetailsScreenState)._selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!(this as _ProductDetailsScreenState)._isDisposed) {
      (this as _ProductDetailsScreenState).setState(() {
        (this as _ProductDetailsScreenState)._isSubmittingRating = true;
      });
    }

    try {
      final customerId = CustomerSession.instance.currentCustomerId!;
      final success = await RatingService.submitRating(
        productId: widget.product.id,
        customerId: customerId,
        rating: (this as _ProductDetailsScreenState)._selectedRating.toInt(),
        review:
            (this as _ProductDetailsScreenState)._reviewController.text
                .trim()
                .isEmpty
            ? null
            : (this as _ProductDetailsScreenState)._reviewController.text
                  .trim(),
      );

      if (success) {
        await _loadRatingData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your rating has been submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to submit rating. Check your connection or try again',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred submitting the rating'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!(this as _ProductDetailsScreenState)._isDisposed) {
        (this as _ProductDetailsScreenState).setState(() {
          (this as _ProductDetailsScreenState)._isSubmittingRating = false;
        });
      }
    }
  }

  Future<void> _deleteRating() async {
    if (!CustomerSession.instance.isLoggedIn ||
        (this as _ProductDetailsScreenState)._userRating == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final customerId = CustomerSession.instance.currentCustomerId!;
      final success = await RatingService.deleteRating(
        widget.product.id,
        customerId,
      );

      if (success) {
        if (!(this as _ProductDetailsScreenState)._isDisposed) {
          await _loadRatingData();
          (this as _ProductDetailsScreenState).setState(() {
            (this as _ProductDetailsScreenState)._selectedRating = 0;
            (this as _ProductDetailsScreenState)._reviewController.clear();
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your rating has been deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred deleting the rating'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addToCartAsync() async {
    try {
      await CartManager.instance.addProduct(
        widget.product.id,
        quantity: (this as _ProductDetailsScreenState)._selectedQuantity,
      );
      print('Product added to cart successfully');

      // Update app bloc badge count after add
      if (mounted) {
        try {
          final appBloc = context.read<AppBloc>();
          final summary = await CartManager.instance.getCartSummary();
          final count = summary['itemCount'] as int? ?? 0;
          appBloc.add(SetCartItemCountEvent(count));
        } catch (e) {
          // ignore non-fatal UI badge update errors
        }
      }
    } catch (e) {
      print('Error adding product to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(
                  Icons.error_rounded,
                  color: AppColors.textInverse,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Error adding product to cart',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showCartNotification() {
    if (!mounted) return;
    print('Showing overlay notification for: ${widget.product.name}');
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
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 20,
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
                        SizedBox(height: 2),
                        Text(
                          widget.product.name,
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
                          widget.product.price.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.attach_money,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      print('View cart button tapped from product details');
                      overlayEntry.remove();
                      Navigator.of(context).pushNamed('/cart');
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
                        'View cart',
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
}
