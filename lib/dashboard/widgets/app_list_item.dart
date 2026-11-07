import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../models/apk_model.dart';

/// Carte moderne présentant une application avec ses actions rapides.
class AppListItem extends StatelessWidget {
  final ApkModel app;
  final VoidCallback onLaunch;
  final VoidCallback onSettings;

  const AppListItem({
    super.key,
    required this.app,
    required this.onLaunch,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSettings,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _buildAppIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      app.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildVersionPill(),
                        const SizedBox(width: 8),
                        _buildTypeBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    if (app.iconBytes != null && app.iconBytes!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            app.iconBytes!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.android_rounded,
        size: 28,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildVersionPill() {
    final version = app.versionName.isEmpty
        ? AppStrings.unknownVersion
        : '${AppStrings.versionPrefix}${app.versionName}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        version,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isSystem = app.isSystemApp;
    final bgColor = isSystem ? AppColors.systemBadgeBg : AppColors.userBadgeBg;
    final textColor =
        isSystem ? AppColors.systemBadgeText : AppColors.userBadgeText;
    final label = isSystem ? AppStrings.badgeSystem : AppStrings.badgeUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.settings_outlined, size: 20),
          tooltip: AppStrings.actionDetails,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onSettings,
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          tooltip: AppStrings.actionLaunch,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onLaunch,
        ),
      ],
    );
  }
}
