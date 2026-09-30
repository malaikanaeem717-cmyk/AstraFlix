// lib/screens/auth/login_screen.dart
// Centered glass card over an ambient animated background — floating movie
// icons drifting slowly, glow orbs — instead of a full-bleed form.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/floating_icons_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(authServiceProvider).signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = ref.read(authServiceProvider).getErrorMessage(e);
      });
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isGoogleLoading = true; _errorMessage = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingIconsBackground(
        child: SafeArea(
          child: Center(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: _buildLogo()).animate().fadeIn().slideY(begin: -0.3),
                    const SizedBox(height: 32),
                    const Text('Welcome back',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 26,
                            fontWeight: FontWeight.w800, fontFamily: 'Poppins'))
                        .animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                    const SizedBox(height: 4),
                    const Text('Sign in to continue watching',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins'))
                        .animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 28),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake(),

                    _buildEmailField().animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                    const SizedBox(height: 14),
                    _buildPasswordField().animate().fadeIn(delay: 250.ms).slideY(begin: 0.3),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: AppColors.primary, fontSize: 13,
                                fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 6),
                    GradientButton(label: 'Sign In', isLoading: _isLoading, onTap: _signIn)
                        .animate().fadeIn(delay: 350.ms).slideY(begin: 0.3),
                    const SizedBox(height: 22),

                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFF2A2A2A))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or continue with',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Poppins')),
                        ),
                        const Expanded(child: Divider(color: Color(0xFF2A2A2A))),
                      ],
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 18),
                    _buildGoogleButton().animate().fadeIn(delay: 450.ms).slideY(begin: 0.3),
                    const SizedBox(height: 26),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins')),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text('Sign Up',
                                style: TextStyle(color: AppColors.primary, fontSize: 14,
                                    fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('A', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'Astra', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
            TextSpan(text: 'Flix', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          ]),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
      decoration: const InputDecoration(
        hintText: 'Email address',
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Email is required';
        if (!v.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signIn(),
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildGoogleButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isGoogleLoading ? null : _signInWithGoogle,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Center(
            child: _isGoogleLoading
                ? const AstraLoadingIndicator()
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: const Center(
                    child: Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Continue with Google',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}