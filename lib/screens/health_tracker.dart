// lib/screens/health_tracker.dart
library health_tracker;

import 'package:provider/provider.dart';
import '../core/constants/translations.dart';
import '../core/services/app_settings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// removed unused imports
import '../core/constants/design_system.dart';
// removed unused imports
import '../core/services/storage_service.dart';
import '../core/services/rewards_service.dart';
// removed unused imports
part 'functions/health_tracker.functions.dart';

class HealthTracker extends StatefulWidget {
  const HealthTracker({super.key});

  @override
  State<HealthTracker> createState() => _HealthTrackerState();
}

class _HealthTrackerState extends State<HealthTracker>
    with TickerProviderStateMixin, HealthTrackerFunctions {
  double _dailyGoal = 3000.0; // ml
  double _currentIntake = 1200.0; // ml
  // removed unused field
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  // Weekly data
  final List<double> _weeklyIntake = [1800, 2200, 1900, 2400, 2100, 2300, 1200];
  final List<String> _weekDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: _currentIntake / _dailyGoal).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _animationController.forward();
    _progressController.forward();
    _loadDailyGoal();
  }

  Future<void> _loadDailyGoal() async {
    final goal = await StorageService.getWaterGoal();
    setState(() {
      _dailyGoal = goal.toDouble();
    });
    _updateProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _addWater(double amount) {
    setState(() {
      _currentIntake += amount;
      if (_currentIntake > _dailyGoal) {
        _currentIntake = _dailyGoal;
      }
    });
    _updateProgress();
    HapticFeedback.lightImpact();

    // Try award daily goal points once per day when goal met
    maybeAwardDailyWaterGoalPoints(
      currentIntakeMl: _currentIntake,
      dailyGoalMl: _dailyGoal,
    );
  }

  void _updateProgress() {
    _progressAnimation =
        Tween<double>(
          begin: _progressAnimation.value,
          end: _currentIntake / _dailyGoal,
        ).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );
    _progressController.forward(from: 0.0);
  }

  void _updateDailyGoal(double newGoal) async {
    setState(() {
      _dailyGoal = newGoal;
      // Reset current intake if it exceeds new goal
      if (_currentIntake > _dailyGoal) {
        _currentIntake = _dailyGoal;
      }
    });

    // Save to storage
    await StorageService.saveWaterGoal(newGoal.toInt());

    // Update progress animation
    _updateProgress();

    // Show success feedback
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Daily goal updated to ${(newGoal / 1000).toStringAsFixed(1)} L',
        ),
        backgroundColor: DesignSystem.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCustomAmountDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppTranslations.getText(
            'add',
            context.read<AppSettings>().currentLanguage,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (ml)',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.getText(
                'cancel',
                context.read<AppSettings>().currentLanguage,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                _addWater(amount);
                Navigator.pop(context);
              }
            },
            child: Text(
              AppTranslations.getText(
                'add',
                context.read<AppSettings>().currentLanguage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyGoalDialog() {
    final TextEditingController goalController = TextEditingController();
    goalController.text = (_dailyGoal / 1000).toStringAsFixed(
      1,
    ); // Convert to liters

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.flag_outlined, color: DesignSystem.primary),
            const SizedBox(width: 8),
            Text(
              AppTranslations.getText(
                'set_daily_goal',
                context.read<AppSettings>().currentLanguage,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set your desired daily water intake',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignSystem.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignSystem.primary.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: goalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Daily goal (liters)',
                  labelStyle: TextStyle(color: DesignSystem.primary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: Icon(
                    Icons.water_drop,
                    color: DesignSystem.primary,
                  ),
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: DesignSystem.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended: 3–4 liters daily',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final goalInLiters = double.tryParse(goalController.text);
              if (goalInLiters != null &&
                  goalInLiters > 0 &&
                  goalInLiters <= 10) {
                _updateDailyGoal(goalInLiters * 1000); // Convert to ml
                Navigator.pop(context);
              }
            },
            child: Text(
              AppTranslations.getText(
                'save',
                context.read<AppSettings>().currentLanguage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Health Tracker',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_outlined, color: Colors.grey[700]),
            onPressed: _showDailyGoalDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Progress
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: DesignSystem.getBrandGradient('primary'),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: DesignSystem.getBrandShadow('heavy'),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                          ),
                          child: Text(
                            '${((_currentIntake / _dailyGoal) * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return Text(
                                    '${_currentIntake.toInt()} ml',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                'of ${(_dailyGoal / 1000).toStringAsFixed(1)} L',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressAnimation.value,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Quick Add Buttons
              Text(
                'Quick Add',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAddButton(
                      250,
                      'Small Cup',
                      Icons.local_drink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAddButton(
                      500,
                      'Large Cup',
                      Icons.local_drink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAddButton(
                      1000,
                      'Bottle',
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildQuickAddButton(
                  0,
                  'Custom Amount',
                  Icons.add,
                  isCustom: true,
                ),
              ),

              const SizedBox(height: 30),

              // Weekly Progress
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          final percentage = _weeklyIntake[index] / _dailyGoal;
                          final isToday = index == 6; // Saturday
                          return Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? const Color(0xFF6B46C1)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: percentage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? const Color(0xFF6B46C1)
                                            : Colors.grey[400],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _weekDays[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Health Tips
              Text(
                'Health Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 16),
              _buildHealthTip(
                'Drink a glass of water after waking up',
                'Helps activate the body and flush toxins',
                Icons.wb_sunny_outlined,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildHealthTip(
                'Drink water before meals',
                'Helps you feel full and improves digestion',
                Icons.restaurant_outlined,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildHealthTip(
                'Avoid soft drinks',
                'Replace them with water or natural juices',
                Icons.no_drinks_outlined,
                Colors.red,
              ),

              const SizedBox(height: 30),

              // Achievements
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAchievementCard(
                      'Perfect Week',
                      '7 consecutive days',
                      Icons.star,
                      Colors.amber,
                      isCompleted: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAchievementCard(
                      'Healthy Month',
                      '30 consecutive days',
                      Icons.calendar_today,
                      Colors.blue,
                      isCompleted: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddButton(
    double amount,
    String label,
    IconData icon, {
    bool isCustom = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isCustom) {
          _showCustomAmountDialog();
        } else {
          _addWater(amount);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.purple[600], size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              isCustom ? label : '$amount ml',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (!isCustom)
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTip(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    String title,
    String description,
    IconData icon,
    Color color, {
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? color : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isCompleted ? color : Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCompleted ? color : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isCompleted ? color : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
