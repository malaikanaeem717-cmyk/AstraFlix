// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_badge.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(_emailController.text);
      setState(() => _emailSent = true);
    } catch (e) {
      setState(() => _error = 'Failed to send reset email. Please try again.');
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessState() : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 40),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text('Reset Password',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        const Text('Enter your email and we\'ll send you a password reset link.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins', height: 1.5)),
        const SizedBox(height: 32),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Poppins')),
          ).animate().shake(),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Send Reset Link',
          isLoading: _isLoading,
          icon: Icons.send_rounded,
          onTap: _sendResetEmail,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.success, size: 56),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text('Email Sent!',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          const Text('Check your inbox for a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins', height: 1.5)),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Back to Login',
            icon: Icons.arrow_back_rounded,
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
