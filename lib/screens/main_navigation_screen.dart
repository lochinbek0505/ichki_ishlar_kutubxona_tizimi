import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'book_issue_screen.dart';
import 'books_screen.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index)),
      const BooksScreen(),
      const UsersScreen(),
      const BookIssueScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar Navigation for Desktop
          Container(
            width: 270,
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              border: Border(right: BorderSide(color: AppColors.cardBorder, width: 1)),
            ),
            child: Column(
              children: [
                // Logo Header with Litsey Main Emblem Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundDark,
                          border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                        ),
                        child: Image.asset(
                          'assets/icons/litsey.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.school, color: AppColors.goldPrimary, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'IIV LITSEYI',
                              style: TextStyle(
                                color: AppColors.goldPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kutubxona Tizimi',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Navigation Items
                _buildNavItem(0, 'Bosh Sahifa & Tahlil', Icons.dashboard_outlined, Icons.dashboard),
                _buildNavItem(1, 'Kitoblar Katalogi', Icons.menu_book_outlined, Icons.menu_book),
                _buildNavItem(2, 'Kursantlar & Kartalar', Icons.badge_outlined, Icons.badge),
                _buildNavItem(3, 'Kitob Berish / Qaytarish', Icons.assignment_outlined, Icons.assignment),

                const Spacer(),

                // System Footer
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.computer, color: AppColors.emeraldAccent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline Desktop Baza\nVersiya 1.0.0',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: Container(
              color: AppColors.backgroundDark,
              child: pages[_selectedIndex.clamp(0, pages.length - 1)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, IconData activeIcon) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.goldPrimary, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.goldPrimary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
