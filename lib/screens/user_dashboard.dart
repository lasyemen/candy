import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/design_system.dart';
import '../core/constants/translations.dart';
import '../core/services/app_settings.dart';
import '../core/constants/app_colors.dart';
import '../widgets/candy_brand_components.dart';
import 'myordrs.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _statsController;
  late Animation<double> _statsAnimation;

  final Map<String, dynamic> _user = {
    'name': 'أحمد محمد',
    'email': 'ahmed@example.com',
    'phone': '+966501234567',
    'avatar': '👤',
    'joinDate': 'يناير 2024',
    'totalOrders': 15,
    'totalSpent': 450.0,
    'savedWater': 120.0, // liters
  };

  List<Map<String, dynamic>> _getMenuItems(String language) {
    return [
      {
        'icon': Icons.person_outline,
        'title': AppTranslations.getText('edit_profile', language),
        'subtitle': AppTranslations.getText('edit_profile_subtitle', language),
        'color': Colors.blue,
      },
      {
        'icon': Icons.location_on_outlined,
        'title': AppTranslations.getText('saved_addresses', language),
        'subtitle': AppTranslations.getText(
          'saved_addresses_subtitle',
          language,
        ),
        'color': Colors.green,
      },
      {
        'icon': Icons.payment_outlined,
        'title': AppTranslations.getText('payment_methods', language),
        'subtitle': AppTranslations.getText(
          'payment_methods_subtitle',
          language,
        ),
        'color': Colors.orange,
      },
      {
        'icon': Icons.notifications_outlined,
        'title': AppTranslations.getText('notifications', language),
        'subtitle': AppTranslations.getText('notifications_subtitle', language),
        'color': Colors.purple,
      },
      {
        'icon': Icons.language,
        'title': AppTranslations.getText('language', language),
        'subtitle': AppTranslations.getText('language_subtitle', language),
        'color': DesignSystem.primary,
      },
      {
        'icon': Icons.palette,
        'title': AppTranslations.getText('theme', language),
        'subtitle': AppTranslations.getText('theme_subtitle', language),
        'color': DesignSystem.secondary,
      },
      {
        'icon': Icons.help_outline,
        'title': AppTranslations.getText('help_support', language),
        'subtitle': AppTranslations.getText('help_support_subtitle', language),
        'color': Colors.teal,
      },
      {
        'icon': Icons.settings_outlined,
        'title': AppTranslations.getText('settings', language),
        'subtitle': AppTranslations.getText('settings_subtitle', language),
        'color': Colors.grey,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _statsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildCandyAppBar(String language) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'ملف كاندي الشخصي',
        style: DesignSystem.headlineSmall.copyWith(
          color: DesignSystem.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showEditProfile();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, appSettings, child) {
        final currentLanguage = appSettings.currentLanguage;

        return Scaffold(
          backgroundColor: appSettings.isDarkMode
              ? DesignSystem.darkBackground
              : DesignSystem.background,
          body: Container(
            decoration: BoxDecoration(
              gradient: appSettings.isDarkMode
                  ? DesignSystem.getBrandGradient('primary')
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.background,
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _animation.value)),
                  child: Opacity(
                    opacity: _animation.value,
                    child: CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(currentLanguage),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildProfileHeader(currentLanguage),
                                const SizedBox(height: 24),
                                _buildStatsSection(currentLanguage),
                                const SizedBox(height: 20),
                                _buildMenuSection(currentLanguage),
                                const SizedBox(height: 20),
                                _buildLogoutButton(currentLanguage),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(String language) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: DesignSystem.getBrandGradient('primary'),
          ),
          child: Center(
            child: Text(
              AppTranslations.getText('profile_title', language),
              style: DesignSystem.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
    );
  }

  Widget _buildProfileHeader(String language) {
    return CandyGlassmorphismCard(
      padding: const EdgeInsets.all(24),
      glassType: 'purple',
      child: Column(
        children: [
          // Avatar with gradient border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.getBrandGradient('primary'),
              boxShadow: DesignSystem.getBrandShadow('medium'),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: CandyWaterDropContainer(
                width: 90,
                height: 90,
                child: Center(
                  child: Text(
                    _user['avatar'],
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Name with improved styling
          Text(
            _user['name'],
            style: DesignSystem.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          // Email with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _user['email'],
                style: DesignSystem.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Phone with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _user['phone'],
                style: DesignSystem.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Member since with improved design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: DesignSystem.getBrandGlassDecoration(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              borderColor: AppColors.primary.withOpacity(0.3),
              borderRadius: 25,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.getText('member_since', language) +
                      ' ${_user['joinDate']}',
                  style: DesignSystem.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode theme, String language) {
    switch (theme) {
      case ThemeMode.light:
        return AppTranslations.getText('light_mode', language);
      case ThemeMode.dark:
        return AppTranslations.getText('dark_mode', language);
      case ThemeMode.system:
        return AppTranslations.getText('system', language);
    }
  }

  void _showLanguageDialog(
    BuildContext context,
    AppSettings appSettings,
    String currentLanguage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.getText('language', currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppTranslations.getSupportedLanguages().map((langCode) {
            final isSelected = langCode == appSettings.currentLanguage;
            return ListTile(
              title: Text(AppTranslations.getLanguageName(langCode)),
              trailing: isSelected
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appSettings.setLanguage(langCode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    AppSettings appSettings,
    String currentLanguage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.getText('theme', currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.wb_sunny),
              title: Text(
                AppTranslations.getText('light_mode', currentLanguage),
              ),
              trailing: appSettings.currentTheme == ThemeMode.light
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appSettings.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.nightlight_round),
              title: Text(
                AppTranslations.getText('dark_mode', currentLanguage),
              ),
              trailing: appSettings.currentTheme == ThemeMode.dark
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appSettings.setTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_system_daydream),
              title: Text(AppTranslations.getText('system', currentLanguage)),
              trailing: appSettings.currentTheme == ThemeMode.system
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appSettings.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(String language) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: CandyGlassmorphismCard(
            padding: const EdgeInsets.all(24),
            glassType: 'blue',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      AppTranslations.getText('my_statistics', language),
                      style: DesignSystem.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shopping_bag,
                        title: AppTranslations.getText(
                          'total_orders',
                          language,
                        ),
                        value: '${_user['totalOrders']}',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.attach_money,
                        title: AppTranslations.getText('total_spent', language),
                        value:
                            '${_user['totalSpent']} ${AppTranslations.getText('sar', language)}',
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.water_drop,
                  title: 'المياه المحفوظة',
                  value: '${_user['savedWater']} لتر',
                  color: AppColors.waterBlue,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: DesignSystem.getBrandGlassDecoration(
        backgroundColor: color.withOpacity(0.1),
        borderColor: color.withOpacity(0.2),
        borderRadius: 16,
        shadows: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: DesignSystem.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: DesignSystem.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String language) {
    final menuItems = _getMenuItems(language);
    return CandyGlassmorphismCard(
      glassType: 'purple',
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == menuItems.length - 1;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (item['color'] as Color).withOpacity(0.2),
                            (item['color'] as Color).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'],
                        color: item['color'] as Color,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item['title'],
                      style: DesignSystem.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item['subtitle'],
                      style: DesignSystem.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _handleMenuTap(item['title']);
                    },
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      color: AppColors.textSecondary.withOpacity(0.1),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(String language) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: DesignSystem.getBrandGlassDecoration(
        backgroundColor: Colors.red.withOpacity(0.1),
        borderColor: Colors.red.withOpacity(0.2),
        borderRadius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showLogoutDialog,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.logout, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  AppTranslations.getText('logout', language),
                  style: DesignSystem.bodyLarge.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuTap(String title) {
    // Settings functionality removed - now handled by navigation bar

    // Handle Language and Theme options
    if (title == AppTranslations.getText('language', 'ar') ||
        title == AppTranslations.getText('language', 'en') ||
        title == AppTranslations.getText('language', 'ur')) {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final currentLanguage = appSettings.currentLanguage;
      _showLanguageDialog(context, appSettings, currentLanguage);
      return;
    }

    if (title == AppTranslations.getText('theme', 'ar') ||
        title == AppTranslations.getText('theme', 'en') ||
        title == AppTranslations.getText('theme', 'ur')) {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final currentLanguage = appSettings.currentLanguage;
      _showThemeDialog(context, appSettings, currentLanguage);
      return;
    }

    switch (title) {
      case 'تعديل الملف الشخصي':
      case 'Edit Profile':
      case 'پروفائل میں ترمیم':
        _showEditProfile();
        break;
      case 'العناوين المحفوظة':
      case 'Saved Addresses':
      case 'محفوظ شدہ پتے':
        _showAddresses();
        break;
      case 'طرق الدفع':
      case 'Payment Methods':
      case 'ادائیگی کے طریقے':
        _showPaymentMethods();
        break;
      case 'الإشعارات':
      case 'Notifications':
      case 'اطلاعات':
        _showNotifications();
        break;
      case 'المساعدة والدعم':
      case 'Help & Support':
      case 'مدد اور سپورٹ':
        _showHelp();
        break;
    }
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'تعديل الملف الشخصي',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'أحمد محمد',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ahmed@example.com',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+966 50 123 4567',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حفظ التغييرات'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حفظ التغييرات',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تسجيل الخروج بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddresses() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('العناوين المحفوظة')));
  }

  void _showPaymentMethods() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('طرق الدفع')));
  }

  void _showNotifications() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('الإشعارات')));
  }

  void _showHelp() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('المساعدة والدعم')));
  }

  void _showSettings() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('الإعدادات')));
  }
}
