// lib/widgets/custom_app_bar.dart
// AstraFlix branded app bar

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AstraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? leading;
  final bool transparent;

  const AstraAppBar({
    super.key,
    this.title,
    this.actions,
    this.showLogo = false,
    this.leading,
    this.transparent = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : AppColors.surface,
      elevation: 0,
      leading: leading,
      title: showLogo
          ? _buildLogo()
          : title != null
              ? Text(
                  title!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                )
              : null,
      actions: actions,
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        // A icon with red accent
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Astra',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
              TextSpan(
                text: 'Flix',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
