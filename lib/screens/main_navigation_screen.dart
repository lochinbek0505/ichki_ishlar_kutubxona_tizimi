import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'book_issue_screen.dart';
import 'books_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
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

                // Hisob: login/parolni o'zgartirish va chiqish
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle, color: AppColors.goldPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.watch<AuthProvider>().currentUser ?? '',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Login / Parolni o\'zgartirish',
                        icon: const Icon(Icons.manage_accounts, color: AppColors.textMuted, size: 20),
                        onPressed: () => _showChangeCredentialsDialog(context),
                      ),
                      IconButton(
                        tooltip: 'Tizimdan chiqish',
                        icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
                        onPressed: () {
                          context.read<AuthProvider>().logout();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

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

  void _showChangeCredentialsDialog(BuildContext context) {
    final authProv = context.read<AuthProvider>();
    final currentCtrl = TextEditingController();
    final usernameCtrl = TextEditingController(text: authProv.currentUser ?? '');
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (newPassCtrl.text != confirmCtrl.text) {
                setDialogState(() => error = 'Yangi parollar bir xil emas');
                return;
              }
              setDialogState(() => saving = true);
              final result = await authProv.changeCredentials(
                currentPassword: currentCtrl.text,
                newUsername: usernameCtrl.text,
                newPassword: newPassCtrl.text,
              );
              if (result != null) {
                setDialogState(() {
                  saving = false;
                  error = result;
                });
                return;
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Login va parol muvaffaqiyatli o\'zgartirildi')),
                );
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text('Login / Parolni O\'zgartirish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null) ...[
                      Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: currentCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Joriy parol *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usernameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Yangi login *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Yangi parol * (kamida 6 belgi)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Yangi parolni takrorlang *'),
                      onSubmitted: (_) => saving ? null : save(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Bekor qilish', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: const Text('Saqlash'),
                ),
              ],
            );
          },
        );
      },
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
