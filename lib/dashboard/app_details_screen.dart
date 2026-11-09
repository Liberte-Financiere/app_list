import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/apk_model.dart';

/// Écran complet dédié à la consultation approfondie des métadonnées d'une application.
class AppDetailsScreen extends StatefulWidget {
  final ApkModel app;
  final VoidCallback onLaunch;
  final VoidCallback onSettings;

  const AppDetailsScreen({
    super.key,
    required this.app,
    required this.onLaunch,
    required this.onSettings,
  });

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> {
  ApkModel get app => widget.app;

  void _copyToClipboard(String text, String feedbackMessage) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedbackMessage),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y à $h:$min';
  }

  String _formatExactBytes(int bytes) {
    if (bytes <= 0) return 'Taille non renseignée';
    final s = bytes.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '$buffer octets (${app.formattedSize})';
  }

  String _formatAndroidSdk(int apiLevel) {
    if (apiLevel <= 0) return 'Non spécifié';
    switch (apiLevel) {
      case 35:
        return 'API 35 (Android 15)';
      case 34:
        return 'API 34 (Android 14)';
      case 33:
        return 'API 33 (Android 13)';
      case 32:
        return 'API 32 (Android 12L)';
      case 31:
        return 'API 31 (Android 12)';
      case 30:
        return 'API 30 (Android 11)';
      case 29:
        return 'API 29 (Android 10)';
      case 28:
        return 'API 28 (Android 9 Pie)';
      case 27:
        return 'API 27 (Android 8.1 Oreo)';
      case 26:
        return 'API 26 (Android 8.0 Oreo)';
      case 25:
        return 'API 25 (Android 7.1 Nougat)';
      case 24:
        return 'API 24 (Android 7.0 Nougat)';
      case 23:
        return 'API 23 (Android 6.0 Marshmallow)';
      case 22:
        return 'API 22 (Android 5.1 Lollipop)';
      case 21:
        return 'API 21 (Android 5.0 Lollipop)';
      default:
        return apiLevel > 35 ? 'API $apiLevel (Android 15+)' : 'API $apiLevel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(AppStrings.detailsScreenTitle, style: AppTypography.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.actionDetails,
            onPressed: widget.onSettings,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: AppStrings.actionLaunch,
            onPressed: widget.onLaunch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppHeaderCard(isDark),
            const SizedBox(height: 16),
            _buildPrimaryActions(),
            const SizedBox(height: 20),
            _buildTechnicalInfoSection(isDark),
            const SizedBox(height: 20),
            _buildPermissionsSection(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeaderCard(bool isDark) {
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        app.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _copyToClipboard(app.packageName, AppStrings.packageCopied),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  app.packageName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: secondaryTextColor,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: secondaryTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeBadge(),
                _buildVersionBadge(),
                _buildSizeBadge(),
                _buildSourceBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    if (app.iconBytes != null && app.iconBytes!.isNotEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            app.iconBytes!,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.android_rounded,
        size: 36,
        color: AppColors.primary,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildVersionBadge() {
    final version = app.versionName.isEmpty
        ? AppStrings.unknownVersion
        : '${AppStrings.versionPrefix}${app.versionName} (${app.versionCode})';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        version,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSizeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildSourceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 5),
          Text(
            app.installerDisplayName,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: const Text(AppStrings.actionLaunch),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: widget.onLaunch,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.settings_outlined, size: 20),
            label: const Text(AppStrings.actionDetails),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.onSettings,
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfoSection(bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  AppStrings.technicalInfoTitle,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _buildDetailTile(
              label: 'Nom du package',
              value: app.packageName,
              icon: Icons.code_rounded,
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copier le package',
                onPressed: () => _copyToClipboard(app.packageName, AppStrings.packageCopied),
              ),
            ),
            _buildDetailTile(
              label: 'Version installée',
              value: 'v${app.versionName} (Build: ${app.versionCode})',
              icon: Icons.tag_rounded,
            ),
            _buildDetailTile(
              label: 'Niveau SDK Android cible',
              value: _formatAndroidSdk(app.targetSdkVersion),
              icon: Icons.android_rounded,
            ),
            _buildDetailTile(
              label: 'Source d\'installation',
              value: app.installerPackageName.isNotEmpty
                  ? '${app.installerDisplayName}\n(${app.installerPackageName})'
                  : app.installerDisplayName,
              icon: Icons.storefront_rounded,
            ),
            _buildDetailTile(
              label: 'Taille du package APK',
              value: _formatExactBytes(app.sizeInBytes),
              icon: Icons.storage_rounded,
            ),
            _buildDetailTile(
              label: 'Date de première installation',
              value: _formatDate(app.installDate),
              icon: Icons.calendar_today_rounded,
            ),
            if (app.lastUpdateDate != null)
              _buildDetailTile(
                label: 'Dernière mise à jour',
                value: _formatDate(app.lastUpdateDate!),
                icon: Icons.update_rounded,
              ),
            if (app.filePath.isNotEmpty)
              _buildDetailTile(
                label: 'Chemin binaire APK (source)',
                value: app.filePath,
                icon: Icons.folder_open_rounded,
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copier le chemin binaire',
                  onPressed: () => _copyToClipboard(app.filePath, AppStrings.pathCopied),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required String label,
    required String value,
    required IconData icon,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.permissionsTitle,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Afin d\'optimiser les performances de scan et de respecter la confidentialité, les autorisations ne sont pas lues en masse via le PackageManager. Vous pouvez inspecter et configurer les droits d\'accès accordés à cette application directement dans les paramètres système Android.',
              style: AppTypography.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text(AppStrings.managePermissionsInSettings),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: widget.onSettings,
            ),
          ],
        ),
      ),
    );
  }
}
