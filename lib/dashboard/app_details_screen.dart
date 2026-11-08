import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/apk_model.dart';

/// Filtre appliqué sur la liste des permissions de l'application.
enum PermissionFilter {
  all,
  granted,
  denied,
}

/// Écran complet dédié à la consultation approfondie des métadonnées et permissions d'une application.
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
  PermissionFilter _permissionFilter = PermissionFilter.all;
  String _permissionSearchQuery = '';

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

  List<String> get _filteredPermissions {
    final query = _permissionSearchQuery.trim().toLowerCase();
    return app.declaredPermissions.where((permission) {
      final isGranted = app.grantedPermissions.contains(permission);
      final matchesFilter = switch (_permissionFilter) {
        PermissionFilter.all => true,
        PermissionFilter.granted => isGranted,
        PermissionFilter.denied => !isGranted,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final simpleName = permission.replaceFirst('android.permission.', '').toLowerCase();
      return permission.toLowerCase().contains(query) || simpleName.contains(query);
    }).toList();
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
    final declaredCount = app.declaredPermissions.length;
    final grantedCount = app.grantedPermissions.length;
    final deniedCount = (declaredCount - grantedCount).clamp(0, declaredCount);
    final filteredList = _filteredPermissions;

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$grantedCount / $declaredCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              declaredCount == 0
                  ? 'Cette application ne demande aucune permission spécifique.'
                  : '$grantedCount accordée(s) et $deniedCount non accordée(s) sur un total de $declaredCount déclarée(s).',
              style: AppTypography.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            if (declaredCount > 0) ...[
              const SizedBox(height: 14),
              SegmentedButton<PermissionFilter>(
                segments: [
                  ButtonSegment(
                    value: PermissionFilter.all,
                    label: Text('Toutes ($declaredCount)', style: const TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: PermissionFilter.granted,
                    label: Text('Accordées ($grantedCount)', style: const TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: PermissionFilter.denied,
                    label: Text('Refusées ($deniedCount)', style: const TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_permissionFilter},
                onSelectionChanged: (newSelection) {
                  setState(() => _permissionFilter = newSelection.first);
                },
              ),
              if (declaredCount > 4) ...[
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) => setState(() => _permissionSearchQuery = val),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filtrer les permissions...',
                    hintStyle: AppTypography.bodySmall.copyWith(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              if (filteredList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aucune permission correspondante.',
                      style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final perm = filteredList[index];
                    final isGranted = app.grantedPermissions.contains(perm);
                    final simpleName = perm.replaceFirst('android.permission.', '');

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      leading: Icon(
                        isGranted ? Icons.check_circle_rounded : Icons.cancel_outlined,
                        color: isGranted ? Colors.green : Colors.red[400],
                        size: 20,
                      ),
                      title: SelectableText(
                        simpleName,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isGranted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: SelectableText(
                        perm,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isGranted ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isGranted ? 'Accordée' : 'Refusée',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isGranted ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
            const SizedBox(height: 14),
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
