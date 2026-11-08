import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../models/apk_model.dart';

/// Carte moderne présentant une application avec sa taille, version et actions.
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
        onTap: () => _showAppDetailsSheet(context),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildVersionPill(),
                        _buildSizePill(),
                        _buildTypeBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActions(context),
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

  Widget _buildSizePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        app.formattedSize,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
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

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.info_outline_rounded, size: 20),
          tooltip: 'Détails complets',
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _showAppDetailsSheet(context),
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

  void _showAppDetailsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildAppIcon(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.name, style: AppTypography.titleLarge),
                        Text(app.packageName, style: AppTypography.bodySmall.copyWith(color: secondaryTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildDetailRow('Taille du package APK', app.formattedSize, Icons.storage_rounded),
              _buildDetailRow('Version installée', 'v${app.versionName} (${app.versionCode})', Icons.tag_rounded),
              if (app.targetSdkVersion > 0)
                _buildDetailRow('SDK Android cible', 'API ${app.targetSdkVersion}', Icons.android_rounded),
              _buildDetailRow(
                'Date d\'installation',
                '${app.installDate.day.toString().padLeft(2, '0')}/${app.installDate.month.toString().padLeft(2, '0')}/${app.installDate.year}',
                Icons.calendar_today_rounded,
              ),
              if (app.lastUpdateDate != null)
                _buildDetailRow(
                  'Dernière mise à jour',
                  '${app.lastUpdateDate!.day.toString().padLeft(2, '0')}/${app.lastUpdateDate!.month.toString().padLeft(2, '0')}/${app.lastUpdateDate!.year}',
                  Icons.update_rounded,
                ),
              if (app.filePath.isNotEmpty)
                _buildDetailRow('Chemin binaire APK', app.filePath, Icons.folder_open_rounded),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text(AppStrings.actionDetails),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onSettings();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(AppStrings.actionLaunch),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onLaunch();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
