import 'package:flutter/material.dart';
import '../services/news_service.dart';

class ReadingStatsScreen extends StatefulWidget {
  const ReadingStatsScreen({super.key});

  @override
  State<ReadingStatsScreen> createState() => _ReadingStatsScreenState();
}

class _ReadingStatsScreenState extends State<ReadingStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await NewsService.getReadingStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reading Stats', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Failed to load stats'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCards(textColor),
                        const SizedBox(height: 24),
                        Text('Top Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        _buildCategoryBars(textColor),
                        const SizedBox(height: 24),
                        Text('Weekly Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        _buildWeeklyChart(textColor),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewCards(Color textColor) {
    final cards = [
      _OverviewCard(
        icon: Icons.article_outlined,
        label: 'Articles Read',
        value: '${_stats?['totalArticlesRead'] ?? 0}',
        color: const Color(0xFF2E65F3),
      ),
      _OverviewCard(
        icon: Icons.trending_up,
        label: 'Avg. Progress',
        value: '${_stats?['avgReadProgress'] ?? 0}%',
        color: const Color(0xFF10B981),
      ),
      _OverviewCard(
        icon: Icons.local_fire_department,
        label: 'Streak',
        value: '${_stats?['streakDays'] ?? 0}d',
        color: const Color(0xFFF59E0B),
      ),
    ];

    return Row(
      children: cards.map((card) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(card.icon, color: card.color, size: 28),
              const SizedBox(height: 8),
              Text(card.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: card.color)),
              const SizedBox(height: 4),
              Text(card.label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCategoryBars(Color textColor) {
    final categories = List<Map<String, dynamic>>.from(_stats?['topCategories'] ?? []);
    if (categories.isEmpty) {
      return Center(child: Text('No reading data yet', style: TextStyle(color: Colors.grey.shade500)));
    }

    final maxCount = categories.isNotEmpty ? (categories.first['count'] as int) : 1;

    return Column(
      children: categories.map((cat) {
        final count = cat['count'] as int;
        final fraction = count / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  (cat['category'] as String).toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E65F3)),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text('$count', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyChart(Color textColor) {
    final weeklyData = List<Map<String, dynamic>>.from(_stats?['weeklyActivity'] ?? []);
    if (weeklyData.isEmpty) return const SizedBox();

    final maxCount = weeklyData.map((d) => d['count'] as int).fold(0, (a, b) => a > b ? a : b);
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weeklyData.asMap().entries.map((entry) {
          final count = entry.value['count'] as int;
          final height = maxCount > 0 ? (count / maxCount) * 100 : 0.0;
          return Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: height.clamp(4.0, 100.0),
                decoration: BoxDecoration(
                  color: count > 0 ? const Color(0xFF2E65F3) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dayLabels[entry.key % 7],
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _OverviewCard {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _OverviewCard({required this.icon, required this.label, required this.value, required this.color});
}
