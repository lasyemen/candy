import '../core/constants/app_colors.dart';
import '../core/constants/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CANDY Brand Components - مكونات علامة كاندي التجارية
/// Specialized components that match the CANDY brand identity

/// CANDY Glassmorphism Card - بطاقة زجاجية بعلامة كاندي
class CandyGlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final String glassType; // 'purple', 'blue', 'combined'

  const CandyGlassmorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.glassType = 'purple',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: _getGlassDecoration(),
        child: child,
      ),
    );
  }

  BoxDecoration _getGlassDecoration() {
    switch (glassType.toLowerCase()) {
      case 'blue':
        return BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case 'combined':
        return BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        );
      default:
        return BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }
}

/// CANDY Gradient Button - زر متدرج بعلامة كاندي
class CandyGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final String gradientType; // 'primary', 'water', 'mountain', 'lightning'
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const CandyGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradientType = 'primary',
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56.0,
  });

  @override
  State<CandyGradientButton> createState() => _CandyGradientButtonState();
}

class _CandyGradientButtonState extends State<CandyGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  LinearGradient _getGradient(String type) {
    return DesignSystem.getBrandGradient(type);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: _getGradient(widget.gradientType),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onPressed,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textInverse,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: AppColors.textInverse,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.text,
                                style: DesignSystem.labelLarge.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// CANDY Water Drop Container - حاوية قطرة الماء
class CandyWaterDropContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isAnimated;

  const CandyWaterDropContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          gradient: AppColors.waterGradient,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isAnimated
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: child,
              )
            : child,
      ),
    );
  }
}

/// CANDY Mountain Container - حاوية الجبل
class CandyMountainContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CandyMountainContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// CANDY Lightning Container - حاوية البرق
class CandyLightningContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CandyLightningContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// CANDY Progress Indicator - مؤشر التقدم بعلامة كاندي
class CandyProgressIndicator extends StatefulWidget {
  final double progress;
  final double? width;
  final double height;
  final String gradientType; // 'water', 'mountain', 'primary'

  const CandyProgressIndicator({
    super.key,
    required this.progress,
    this.width,
    this.height = 8.0,
    this.gradientType = 'water',
  });

  @override
  State<CandyProgressIndicator> createState() => _CandyProgressIndicatorState();
}

class _CandyProgressIndicatorState extends State<CandyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CandyProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _getProgressGradient(String type) {
    return DesignSystem.getBrandGradient(type);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.backgroundVariant,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: _getProgressGradient(widget.gradientType),
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// CANDY Success Indicator - مؤشر النجاح بعلامة كاندي
class CandySuccessIndicator extends StatefulWidget {
  final bool isSuccess;
  final String? message;
  final VoidCallback? onDismiss;

  const CandySuccessIndicator({
    super.key,
    required this.isSuccess,
    this.message,
    this.onDismiss,
  });

  @override
  State<CandySuccessIndicator> createState() => _CandySuccessIndicatorState();
}

class _CandySuccessIndicatorState extends State<CandySuccessIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(CandySuccessIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSuccess) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.textInverse,
                    size: 20,
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.message!,
                      style: DesignSystem.labelMedium.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                  ],
                  if (widget.onDismiss != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(
                        Icons.close,
                        color: AppColors.textInverse,
                        size: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// CANDY Floating Action Button - زر العائمة بعلامة كاندي
class CandyFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final IconData? icon;
  final String? tooltip;
  final String gradientType; // 'primary', 'water', 'mountain'

  const CandyFloatingActionButton({
    super.key,
    this.onPressed,
    this.child,
    this.icon,
    this.tooltip,
    this.gradientType = 'primary',
  });

  LinearGradient _getFABGradient(String type) {
    return DesignSystem.getBrandGradient(type);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getFABGradient(gradientType),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        tooltip: tooltip,
        child: child ?? Icon(icon ?? Icons.add),
      ),
    );
  }
}
