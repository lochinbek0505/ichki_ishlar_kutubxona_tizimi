import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/book_issue_provider.dart';
import '../providers/book_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _statTabController;

  @override
  void initState() {
    super.initState();
    _statTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _statTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = context.watch<BookProvider>();
    context.watch<UserProvider>();
    final issueProv = context.watch<BookIssueProvider>();
    final statProv = context.watch<StatisticsProvider>();
    final authProv = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner / Header with Litsey Main Emblem Logo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldPrimary, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.goldGlow,
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundDark,
                    border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                  ),
                  child: Image.asset(
                    'assets/icons/litsey.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school, color: AppColors.goldPrimary, size: 40),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ICHKI ISHLAR VAZIRLIGI LITSEYI KUTUBXONA TIZIMI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Operator: ${authProv.currentUser ?? 'Administrator'} | Offline Desktop Baza',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  tooltip: 'Tizimdan Chiqish',
                  onPressed: () {
                    authProv.logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI Stat Cards
          Row(
            children: [
              _buildStatCard(
                title: 'Jami Kitob Fondi',
                value: '${bookProv.totalBooksCount} nusxa',
                subtitle: '${bookProv.allBooks.length} turdagi kitob',
                icon: Icons.menu_book,
                color: AppColors.goldPrimary,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Mavjud Kitoblar',
                value: '${bookProv.availableBooksCount} nusxa',
                subtitle: 'Kutubxonada bor',
                icon: Icons.check_circle_outline,
                color: AppColors.emeraldAccent,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Olingan Kitoblar',
                value: '${issueProv.activeIssuedCount} ta',
                subtitle: 'Kursantlarda bor',
                icon: Icons.assignment_return,
                color: AppColors.info,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Qarzdorlar (Kechikkan)',
                value: '${issueProv.overdueCount} ta',
                subtitle: 'Topshirish muddati o\'tgan',
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Action Buttons
          const Text(
            'TEZKOR HARAKATLAR',
            style: TextStyle(
              color: AppColors.goldPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                label: 'Kitob Biriktirish',
                icon: Icons.add_to_photos,
                color: AppColors.goldPrimary,
                textColor: AppColors.backgroundDark,
                onTap: () => widget.onNavigate(3), // Issue screen
              ),
              _buildActionButton(
                label: 'Katalog va Kitob Qo\'shish',
                icon: Icons.library_add,
                color: AppColors.cardDark,
                textColor: AppColors.textPrimary,
                onTap: () => widget.onNavigate(1), // Books screen
              ),
              _buildActionButton(
                label: 'O\'quvchilar & A\'zolik Kartalari',
                icon: Icons.badge,
                color: AppColors.cardDark,
                textColor: AppColors.textPrimary,
                onTap: () => widget.onNavigate(2), // Users screen
              ),
            ],
          ),
          const SizedBox(height: 28),

          // --- BOSH EKRANDAGI KITOBLAR TAHLILI VA STATISTIKA SEKSIYASI ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KITOBLAR TAHLILI VA STATISTIKASI',
                style: AppTextStyles.titleHeader,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.goldPrimary),
                onPressed: () => statProv.loadStatistics(),
                tooltip: 'Statistikalarni Yangilash',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat Tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TabBar(
              controller: _statTabController,
              indicatorColor: AppColors.goldPrimary,
              indicatorWeight: 3,
              labelColor: AppColors.goldPrimary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Guruhlar Kesimida', icon: Icon(Icons.groups, size: 18)),
                Tab(text: 'Bosqichlar Kesimida', icon: Icon(Icons.military_tech, size: 18)),
                Tab(text: 'Top Kitobxonlar & Qarzdorlar', icon: Icon(Icons.emoji_events, size: 18)),
                Tab(text: 'Kitob Turlari & Janrlar', icon: Icon(Icons.pie_chart, size: 18)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat Tab Views Container
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _statTabController,
              children: [
                _buildGroupStatsView(statProv),
                _buildStageStatsView(statProv),
                _buildUserStatsView(statProv),
                _buildBookTypeStatsView(statProv),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recent / Overdue Loans Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HOZIRDA OLINGAN VA KECHIKKAN KITOBLAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => widget.onNavigate(3),
                icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.goldPrimary),
                label: const Text('Barchasini ko\'rish', style: TextStyle(color: AppColors.goldPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: issueProv.issues.where((i) => !i.isReturned).isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: Text(
                        'Hozircha berilgan aktiv kitoblar mavjud emas.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: issueProv.issues.where((i) => !i.isReturned).take(5).length,
                    separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorder, height: 1),
                    itemBuilder: (context, index) {
                      final item = issueProv.issues.where((i) => !i.isReturned).toList()[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isOverdue ? AppColors.error.withValues(alpha: 0.2) : AppColors.goldPrimary.withValues(alpha: 0.2),
                          child: Icon(
                            item.isOverdue ? Icons.warning_amber : Icons.book,
                            color: item.isOverdue ? AppColors.error : AppColors.goldPrimary,
                          ),
                        ),
                        title: Text(
                          item.bookTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        subtitle: Text(
                          'O\'quvchi: ${item.userName} (${item.userGroup ?? ''})',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Qaytarish muddati: ${item.dueDate}',
                              style: TextStyle(
                                color: item.isOverdue ? AppColors.error : AppColors.goldPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.isOverdue ? 'KECHIKKAN' : 'FAOL',
                              style: TextStyle(
                                color: item.isOverdue ? AppColors.error : AppColors.emeraldAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // STAT TAB 1: Guruhlar Kesimida
  Widget _buildGroupStatsView(StatisticsProvider prov) {
    if (prov.groupStats.isEmpty) {
      return const Center(child: Text('Guruhlar bo\'yicha statistika mavjud emas', style: TextStyle(color: AppColors.textMuted)));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
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
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
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
                      BarChartRodData(toY: stat.totalIssued.toDouble(), color: AppColors.goldPrimary, width: 16, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: stat.overdue.toDouble(), color: AppColors.error, width: 10, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ListView.separated(
              itemCount: prov.groupStats.length,
              separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorder, height: 1),
              itemBuilder: (context, index) {
                final item = prov.groupStats[index];
                return ListTile(
                  dense: true,
                  title: Text(item.groupName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('Faol: ${item.activeIssued} ta | Qarzdor: ${item.overdue}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  trailing: Text('${item.totalIssued} ta', style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // STAT TAB 2: Bosqichlar Kesimida
  Widget _buildStageStatsView(StatisticsProvider prov) {
    if (prov.stageStats.isEmpty) {
      return const Center(child: Text('Bosqichlar bo\'yicha statistika mavjud emas', style: TextStyle(color: AppColors.textMuted)));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView.separated(
        itemCount: prov.stageStats.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = prov.stageStats[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech, color: AppColors.goldPrimary, size: 28),
                    const SizedBox(width: 12),
                    Text(item.stageName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    _buildMiniBadge('Jami', '${item.totalIssued} ta', AppColors.goldPrimary),
                    const SizedBox(width: 12),
                    _buildMiniBadge('Faol', '${item.activeIssued} ta', AppColors.emeraldAccent),
                    const SizedBox(width: 12),
                    _buildMiniBadge('Qarzdor', '${item.overdue} ta', item.overdue > 0 ? AppColors.error : AppColors.success),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // STAT TAB 3: Top Readers & Overdue Students
  Widget _buildUserStatsView(StatisticsProvider prov) {
    return Row(
      children: [
        // Top Readers
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.emoji_events, color: AppColors.goldPrimary, size: 20),
                    SizedBox(width: 8),
                    Text('TOP-10 FAOL KITOBXON KURSANTLAR', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: prov.topReaders.take(5).length,
                    separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorder, height: 1),
                    itemBuilder: (context, index) {
                      final item = prov.topReaders[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: index < 3 ? AppColors.goldPrimary.withValues(alpha: 0.3) : AppColors.inputBackground,
                          child: Text('#${index + 1}', style: TextStyle(color: index < 3 ? AppColors.goldPrimary : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(item.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                        subtitle: Text('Guruh: ${item.user.guruhName ?? '—'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        trailing: Text('${item.booksReadCount} ta kitob', style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Overdue Debtors
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.warning, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('QARZDOR O\'QUVCHILAR (KECHIKKAN)', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: prov.overdueIssues.isEmpty
                      ? const Center(child: Text('Qarzdorlar yo\'q!', style: TextStyle(color: AppColors.success)))
                      : ListView.separated(
                          itemCount: prov.overdueIssues.length,
                          separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorder, height: 1),
                          itemBuilder: (context, index) {
                            final item = prov.overdueIssues[index];
                            return ListTile(
                              dense: true,
                              title: Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                              subtitle: Text('Kitob: ${item.bookTitle}\nMuhlati: ${item.dueDate}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                                child: const Text('KECHIKKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
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

  // STAT TAB 4: Kitob Turlari & Janrlar
  Widget _buildBookTypeStatsView(StatisticsProvider prov) {
    if (prov.bookTypeStats.isEmpty) {
      return const Center(child: Text('Kitob turlari statistikasi mavjud emas', style: TextStyle(color: AppColors.textMuted)));
    }

    final colors = [AppColors.goldPrimary, AppColors.emeraldAccent, AppColors.info, Colors.purpleAccent, Colors.orangeAccent];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView.separated(
        itemCount: prov.bookTypeStats.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = prov.bookTypeStats[index];
          final color = colors[index % colors.length];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.typeName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  Text('${item.totalCount} nusxa (${item.percentage.toStringAsFixed(1)}%)', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: item.percentage / 100,
                backgroundColor: AppColors.inputBackground,
                color: color,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: textColor),
      label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
