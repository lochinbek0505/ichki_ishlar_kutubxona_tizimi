import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSetup = false; // Administrator hisobi hali yaratilmagan

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().hasAccount().then((exists) {
      if (mounted) {
        setState(() {
          _isSetup = !exists;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    final authProv = context.read<AuthProvider>();

    if (_isSetup) {
      final error = AuthProvider.validate(_usernameCtrl.text, _passwordCtrl.text) ??
          (_passwordCtrl.text != _confirmCtrl.text ? 'Parollar bir xil emas' : null);
      if (error != null) {
        setState(() => _errorMessage = error);
        return;
      }
    }

    setState(() => _isLoading = true);
    bool success = true;
    if (_isSetup) {
      await authProv.createAccount(_usernameCtrl.text, _passwordCtrl.text);
    } else {
      success = await authProv.login(_usernameCtrl.text, _passwordCtrl.text);
    }
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login yoki parol xato!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Litsey Logo Emblem
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundDark,
                      border: Border.all(color: AppColors.goldPrimary, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.goldGlow,
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icons/litsey.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, index, ___) => const Icon(Icons.school, size: 50, color: AppColors.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Titles
                  const Text(
                    'ICHKI ISHLAR VAZIRLIGI LITSEYI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSetup ? 'ADMINISTRATOR HISOBINI YARATISH' : 'KUTUBXONA TIZIMIGA KIRISH',
                    style: AppTextStyles.titleSubHeader,
                  ),
                  if (_isSetup) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tizimdan birinchi marta foydalanilmoqda. Kirish uchun login va parol o\'ylab toping.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username Input
                  TextField(
                    controller: _usernameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Foydalanuvchi nomi (Login)',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Parol',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.goldPrimary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  if (_isSetup) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Parolni takrorlang',
                        prefixIcon: Icon(Icons.lock_reset, color: AppColors.goldPrimary),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: AppColors.backgroundDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isSetup ? 'HISOBNI YARATISH' : 'TIZIMGA KIRISH',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
