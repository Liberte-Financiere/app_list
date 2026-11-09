import 'package:flutter/material.dart';

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

/// Écran dédié à la visualisation détaillée, au filtrage et à l'audit des permissions d'une application.
class AppPermissionsScreen extends StatefulWidget {
  final ApkModel app;
  final VoidCallback onSettings;

  const AppPermissionsScreen({
    super.key,
    required this.app,
    required this.onSettings,
  });

  @override
  State<AppPermissionsScreen> createState() => _AppPermissionsScreenState();
}

class _AppPermissionsScreenState extends State<AppPermissionsScreen> {
  PermissionFilter _filter = PermissionFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  ApkModel get app => widget.app;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredPermissions {
    final query = _searchQuery.trim().toLowerCase();
    return app.declaredPermissions.where((permission) {
      final isGranted = app.grantedPermissions.contains(permission);
      final matchesFilter = switch (_filter) {
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
    final declaredCount = app.declaredPermissions.length;
    final grantedCount = app.grantedPermissions.length;
    final deniedCount = (declaredCount - grantedCount).clamp(0, declaredCount);
    final filteredList = _filteredPermissions;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(AppStrings.permissionsTitle, style: AppTypography.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: AppStrings.managePermissionsInSettings,
            onPressed: widget.onSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildHeaderCard(isDark, declaredCount, grantedCount, deniedCount),
          ),
          if (declaredCount > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SegmentedButton<PermissionFilter>(
                segments: [
                  ButtonSegment(
                    value: PermissionFilter.all,
                    label: Text('${AppStrings.allPermissions} ($declaredCount)', style: const TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: PermissionFilter.granted,
                    label: Text('${AppStrings.grantedPermissions} ($grantedCount)', style: const TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: PermissionFilter.denied,
                    label: Text('${AppStrings.deniedPermissions} ($deniedCount)', style: const TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (newSelection) {
                  setState(() => _filter = newSelection.first);
                },
              ),
            ),
            if (declaredCount > 4)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filtrer les permissions...',
                    hintStyle: AppTypography.bodySmall.copyWith(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 6),
          const Divider(height: 1),
          Expanded(
            child: declaredCount == 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.noPermissionsDeclared,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredList.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.noPermissionsMatching,
                          style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final perm = filteredList[index];
                          final isGranted = app.grantedPermissions.contains(perm);
                          final simpleName = perm.replaceFirst('android.permission.', '');

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isGranted
                                    ? Colors.green.withAlpha(25)
                                    : Colors.red.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGranted ? Icons.check_rounded : Icons.close_rounded,
                                color: isGranted ? Colors.green[700] : Colors.red[700],
                                size: 18,
                              ),
                            ),
                            title: SelectableText(
                              simpleName,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: isGranted ? FontWeight.bold : FontWeight.w600,
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
                                color: isGranted
                                    ? Colors.green.withAlpha(25)
                                    : Colors.red.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isGranted ? AppStrings.grantedPermissions : AppStrings.deniedPermissions,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isGranted ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text(AppStrings.managePermissionsInSettings),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: widget.onSettings,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark, int declared, int granted, int denied) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _buildAppIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Déclarées',
                    value: '$declared',
                    color: AppColors.primary,
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.withAlpha(50)),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Accordées',
                    value: '$granted',
                    color: Colors.green,
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.withAlpha(50)),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Refusées',
                    value: '$denied',
                    color: Colors.red[400]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAppIcon() {
    if (app.iconBytes != null && app.iconBytes!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            app.iconBytes!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.android_rounded,
        size: 26,
        color: AppColors.primary,
      ),
    );
  }
}
