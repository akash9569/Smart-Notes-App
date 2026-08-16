import 'package:flutter/material.dart';
import '../app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 40, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentBlue, AppColors.accentPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                blurRadius: size * 0.4,
                offset: Offset(0, size * 0.15),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.description_rounded,
                color: context.themeTextPrimary.withValues(alpha: 0.9),
                size: size * 0.6,
              ),
              Positioned(
                right: size * 0.15,
                top: size * 0.15,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.themeTextPrimary,
                  size: size * 0.35,
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Smart Notes',
                style: TextStyle(
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: context.themeTextPrimary,
                ),
              ),
              Text(
                'Intelligent Management',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.iconGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
