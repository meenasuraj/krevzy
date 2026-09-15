import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Performance & Ad Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header Overview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeNotifier.primaryColor, themeNotifier.primaryColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Estimated Earnings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('₹24,850.00', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _EarningsMetric(label: 'Reel Ads', value: '₹14,200'),
                        _EarningsMetric(label: 'Live Tips', value: '₹7,650'),
                        _EarningsMetric(label: 'Subscriptions', value: '₹3,000'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section Title
              const Text('In-Reel Ad Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Metric Cards Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _MetricCard(
                    title: 'Ad Impressions',
                    value: '45.2K',
                    change: '+12.4%',
                    isPositive: true,
                    icon: Icons.visibility,
                    color: Colors.blue,
                  ),
                  _MetricCard(
                    title: 'Click-Through Rate',
                    value: '4.8%',
                    change: '+0.6%',
                    isPositive: true,
                    icon: Icons.ads_click,
                    color: Colors.orange,
                  ),
                  _MetricCard(
                    title: 'Live Peak Viewers',
                    value: '1,280',
                    change: '+240',
                    isPositive: true,
                    icon: Icons.live_tv,
                    color: Colors.red,
                  ),
                  _MetricCard(
                    title: 'Conversion Rate',
                    value: '2.1%',
                    change: '-0.2%',
                    isPositive: false,
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Ad Campaigns Performance List
              const Text('Active Ad Campaigns', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(2, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.monetization_on, color: Colors.amber),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(index == 0 ? 'HD Smart CCTV System Offer' : 'Security Camera Setup Kit', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('CTA: Shop Now • 1.8k Clicks', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Text('₹8,400', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _EarningsMetric extends StatelessWidget {
  final String label;
  final String value;
  const _EarningsMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeNotifier.instance.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: TextStyle(color: isPositive ? Colors.green.shade800 : Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}