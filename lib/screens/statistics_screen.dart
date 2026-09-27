import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/statistics_provider.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statProv = context.watch<StatisticsProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'TAHLIL VA STATISTIKA',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Guruh, Bosqich, O\'quvchi va Kitob turlari kesimidagi hisobotlar',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.goldAccent),
                onPressed: () => statProv.loadStatistics(),
                tooltip: 'Statistikalarni Yangilash',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.goldAccent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Guruhlar Kesimida', icon: Icon(Icons.groups, size: 18)),
                Tab(text: 'Bosqichlar Kesimida', icon: Icon(Icons.military_tech, size: 18)),
                Tab(text: 'O\'quvchilar & Qarzdorlar', icon: Icon(Icons.emoji_events, size: 18)),
                Tab(text: 'Kitob Turlari & Janrlar', icon: Icon(Icons.pie_chart, size: 18)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupStatsView(statProv),
                _buildStageStatsView(statProv),
                _buildUserStatsView(statProv),
                _buildBookTypeStatsView(statProv),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Guruhlar Kesimida
  Widget _buildGroupStatsView(StatisticsProvider prov) {
    if (prov.groupStats.isEmpty) {
      return const Center(child: Text('Guruhlar bo\'yicha statistika mavjud emas', style: TextStyle(color: AppTheme.textMuted)));
    }

    return Column(
      children: [
        // Bar Chart
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (prov.groupStats.map((e) => e.totalIssued).fold(0, (a, b) => a > b ? a : b) + 2).toDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < prov.groupStats.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            prov.groupStats[idx].groupName,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: prov.groupStats.asMap().entries.map((entry) {
                final idx = entry.key;
                final stat = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: stat.totalIssued.toDouble(),
                      color: AppTheme.accentBlue,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: stat.overdue.toDouble(),
                      color: AppTheme.danger,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Group Stats Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: ListView.separated(
              itemCount: prov.groupStats.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
              itemBuilder: (context, index) {
                final item = prov.groupStats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentBlue.withOpacity(0.2),
                    child: Text('${index + 1}', style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item.groupName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('Faol olingan: ${item.activeIssued} ta', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Jami: ${item.totalIssued} ta',
                          style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.overdue > 0 ? AppTheme.danger.withOpacity(0.2) : AppTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Qarzdor: ${item.overdue} ta',
                          style: TextStyle(
                            color: item.overdue > 0 ? AppTheme.danger : AppTheme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // 2. Bosqichlar Kesimida
  Widget _buildStageStatsView(StatisticsProvider prov) {
    if (prov.stageStats.isEmpty) {
      return const Center(child: Text('Bosqichlar bo\'yicha statistika mavjud emas', style: TextStyle(color: AppTheme.textMuted)));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ListView.separated(
        itemCount: prov.stageStats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = prov.stageStats[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.stageName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.military_tech, color: AppTheme.goldAccent, size: 28),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubStat('Jami Olingan', '${item.totalIssued} ta', AppTheme.accentBlue),
                    _buildSubStat('Hozirda Faol', '${item.activeIssued} ta', AppTheme.goldAccent),
                    _buildSubStat('Qarzdorlik', '${item.overdue} ta', item.overdue > 0 ? AppTheme.danger : AppTheme.success),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. Userlar & Qarzdorlar Kesimida
  Widget _buildUserStatsView(StatisticsProvider prov) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Readers
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.emoji_events, color: AppTheme.goldAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'TOP-10 ENG FAOL KITOBXONLAR',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: prov.topReaders.take(10).length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                    itemBuilder: (context, index) {
                      final item = prov.topReaders[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index < 3 ? AppTheme.goldAccent.withOpacity(0.3) : AppTheme.surfaceLight,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: index < 3 ? AppTheme.goldAccent : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(item.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                        subtitle: Text('Guruh: ${item.user.guruhName ?? '—'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.goldDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.booksReadCount} ta kitob',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Overdue Debtors
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.danger.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.warning, color: AppTheme.danger, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'QARZDOR O\'QUVCHILAR (KECHIKKAN)',
                      style: TextStyle(color: AppTheme.danger, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: prov.overdueIssues.isEmpty
                      ? const Center(child: Text('Qarzdor o\'quvchilar yo\'q. Barcha kitoblar o\'z vaqtida topshirilgan!', style: TextStyle(color: AppTheme.success)))
                      : ListView.separated(
                          itemCount: prov.overdueIssues.length,
                          separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                          itemBuilder: (context, index) {
                            final item = prov.overdueIssues[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF7F1D1D),
                                child: Icon(Icons.person, color: AppTheme.danger),
                              ),
                              title: Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                              subtitle: Text('Kitob: ${item.bookTitle}\nMuhlati: ${item.dueDate}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('KECHIKKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. Kitob Turlari & Janrlar Kesimida
  Widget _buildBookTypeStatsView(StatisticsProvider prov) {
    if (prov.bookTypeStats.isEmpty) {
      return const Center(child: Text('Kitob turlari statistikasi mavjud emas', style: TextStyle(color: AppTheme.textMuted)));
    }

    final colors = [AppTheme.accentBlue, AppTheme.goldAccent, AppTheme.success, Colors.purpleAccent, Colors.orangeAccent];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KITOB TURLARI VA NUSHXALAR ULUSHI',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: prov.bookTypeStats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = prov.bookTypeStats[index];
                final color = colors[index % colors.length];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.typeName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                        Text('${item.totalCount} nusxa (${item.percentage.toStringAsFixed(1)}%)', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: item.percentage / 100,
                      backgroundColor: AppTheme.surfaceLight,
                      color: color,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
