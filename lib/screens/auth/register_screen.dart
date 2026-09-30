// lib/screens/auth/register_screen.dart
// User registration screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_badge.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(authServiceProvider).signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = ref.read(authServiceProvider).getErrorMessage(e);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ).animate().fadeIn().slideY(begin: 0.3),
                const SizedBox(height: 4),
                const Text(
                  'Join AstraFlix and discover your next favorite movie',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins'),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Poppins')),
                  ).animate().shake(),

                // Name
                _buildField(
                  controller: _nameController,
                  hint: 'Full name',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  delay: 150,
                ),
                const SizedBox(height: 14),

                // Email
                _buildField(
                  controller: _emailController,
                  hint: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  delay: 200,
                ),
                const SizedBox(height: 14),

                // Password
                _buildPasswordField(
                  controller: _passwordController,
                  hint: 'Password',
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                  delay: 250,
                ),
                const SizedBox(height: 14),

                // Confirm Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm password',
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  delay: 300,
                  isLast: true,
                  onSubmit: _register,
                ),

                const SizedBox(height: 32),

                GradientButton(
                  label: 'Create Account',
                  isLoading: _isLoading,
                  icon: Icons.person_add_rounded,
                  onTap: _register,
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3),

                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ",
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins')),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text('Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            )),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int delay = 0,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      ),
      validator: validator,
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.3);
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    int delay = 0,
    bool isLast = false,
    VoidCallback? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: isLast && onSubmit != null ? (_) => onSubmit() : null,
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.3);
  }
}
