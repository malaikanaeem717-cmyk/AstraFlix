// lib/screens/profile/change_password_screen.dart
// Real in-app password change (re-authenticates with the current password,
// then calls FirebaseAuth.updatePassword) — centered glass card.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/floating_icons_background.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _errorMessage = 'You need to be signed in to change your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;
      setState(() => _success = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your current password is incorrect.';
      case 'weak-password':
        return 'Your new password is too weak — use at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again, then retry.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Could not change your password.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingIconsBackground(
      child: SafeArea(
        child: Column(
          children: [
            _AuthAppBar(title: 'Change Password'),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: GlassCard(child: _success ? _buildSuccess() : _buildForm()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 20),
        const Text('Password changed',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        const Text('Your password has been updated successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, fontFamily: 'Poppins')),
        const SizedBox(height: 24),
        GradientButton(label: 'Done', onTap: () => context.pop()),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 18),
          const Text('Update your password',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          const Text('Enter your current password, then choose a new one.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Poppins')),
          const SizedBox(height: 24),

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
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ),

          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrent,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Current password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'New password',
              prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a new password';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureNew,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Confirm new password',
              prefixIcon: Icon(Icons.check_circle_outline_rounded, color: AppColors.textMuted, size: 20),
            ),
            validator: (v) {
              if (v != _newPasswordController.text) return 'Passwords don\'t match';
              return null;
            },
          ),
          const SizedBox(height: 26),

          GradientButton(label: 'Update Password', isLoading: _isLoading, onTap: _submit),
        ],
      ),
    );
  }
}

class _AuthAppBar extends StatelessWidget {
  final String title;
  const _AuthAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            onPressed: () => context.pop(),
          ),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}