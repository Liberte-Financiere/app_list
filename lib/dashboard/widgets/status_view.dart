import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';

/// Vue d'affichage des états de l'application (chargement, erreur, liste vide).
class StatusView extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  const StatusView({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  /// État de chargement
  factory StatusView.loading() {
    return const StatusView(
      icon: Icons.hourglass_empty_rounded,
      title: AppStrings.loadingMessage,
      isLoading: true,
    );
  }

  /// État vide (aucun résultat)
  factory StatusView.empty({String? customMessage}) {
    return StatusView(
      icon: Icons.search_off_rounded,
      iconColor: AppColors.textSecondaryLight,
      title: AppStrings.emptyListTitle,
      subtitle: customMessage ?? AppStrings.emptyListSubtitle,
    );
  }

  /// État d'erreur avec bouton de réessai
  factory StatusView.error({
    required String message,
    required VoidCallback onRetry,
  }) {
    return StatusView(
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      title: AppStrings.errorTitle,
      subtitle: message,
      actionLabel: AppStrings.actionRetry,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: primaryTextColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
