import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  double _budget = 500.0;
  int _durationDays = 5;
  String _selectedGoal = 'Product Inquiries';

  final List<String> _goals = [
    'Product Inquiries',
    'Profile Visits',
    'Live Stream Viewers',
    'Website Clicks',
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Boost & Promotion Studio', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Campaign Objective Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeNotifier.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                      child: Icon(Icons.trending_up, color: themeNotifier.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Boost CCTV & Creator Reach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Get higher visibility among security tech buyers and local followers.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Goal Selector Section
              const Text('Select Campaign Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final isSelected = _selectedGoal == goal;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(goal),
                        selected: isSelected,
                        selectedColor: themeNotifier.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (themeNotifier.isDarkMode ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                        onSelected: (_) => setState(() => _selectedGoal = goal),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Budget Slider Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('₹${_budget.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeNotifier.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _budget,
                      min: 100,
                      max: 10000,
                      divisions: 99,
                      activeColor: themeNotifier.primaryColor,
                      label: '₹${_budget.toStringAsFixed(0)}',
                      onChanged: (value) => setState(() => _budget = value),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated Reach: ~${(_budget * 12).toInt()} impressions', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('~${(_budget * 0.4).toInt()} clicks', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Duration Selector Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration (Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('$_durationDays Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeNotifier.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _durationDays.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: themeNotifier.primaryColor,
                      label: '$_durationDays Days',
                      onChanged: (value) => setState(() => _durationDays = value.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Launch Promotion Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeNotifier.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Campaign successfully submitted for review! Budget: ₹${_budget.toStringAsFixed(0)}'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Launch Promotion Campaign 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}