import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';

/// Barre de recherche et de filtres avancés du tableau de bord.
class SearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool includeSystemApps;
  final ValueChanged<bool> onToggleSystemApps;
  final int totalCount;

  const SearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.includeSystemApps,
    required this.onToggleSystemApps,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: searchQuery,
                selection: TextSelection.collapsed(offset: searchQuery.length),
              ),
            ),
            decoration: InputDecoration(
              hintText: AppStrings.searchPlaceholder,
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Effacer la recherche',
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalCount ${totalCount > 1 ? AppStrings.appsCountPlural : AppStrings.appsCountSingular}',
                style: AppTypography.labelMedium.copyWith(color: secondaryTextColor),
              ),
              FilterChip(
                selected: includeSystemApps,
                label: const Text(AppStrings.filterSystemLabel),
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: includeSystemApps
                      ? Colors.white
                      : secondaryTextColor,
                ),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: onToggleSystemApps,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
