import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../models/apk_model.dart';
import '../services/apk_service.dart';
import 'widgets/app_list_item.dart';
import 'widgets/consent_view.dart';
import 'widgets/search_filter_bar.dart';
import 'widgets/status_view.dart';

/// Tableau de bord principal orchestrant la recherche, le filtrage et la gestion des APKs.
class DashboardScreen extends StatefulWidget {
  final ApkService apkService;

  const DashboardScreen({
    super.key,
    required this.apkService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingConsent = true;
  bool _hasConsent = false;
  bool _isLoadingApps = false;
  bool _includeSystemApps = false;
  String _searchQuery = '';
  String? _errorMessage;
  List<ApkModel> _allApps = const [];

  @override
  void initState() {
    super.initState();
    _checkInitialConsent();
  }

  Future<void> _checkInitialConsent() async {
    setState(() => _isLoadingConsent = true);
    final consent = await widget.apkService.hasUserConsent();
    if (!mounted) return;

    setState(() {
      _hasConsent = consent;
      _isLoadingConsent = false;
    });

    if (consent) {
      await _loadInstalledApps();
    }
  }

  Future<void> _grantConsent() async {
    try {
      await widget.apkService.setUserConsent(true);
      if (!mounted) return;
      setState(() {
        _hasConsent = true;
        _errorMessage = null;
      });
      await _loadInstalledApps();
    } on ApkServiceException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    }
  }

  Future<void> _revokeConsent() async {
    try {
      await widget.apkService.setUserConsent(false);
      if (!mounted) return;
      setState(() {
        _hasConsent = false;
        _allApps = const [];
        _searchQuery = '';
      });
    } on ApkServiceException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    }
  }

  Future<void> _loadInstalledApps() async {
    setState(() {
      _isLoadingApps = true;
      _errorMessage = null;
    });

    try {
      final apps = await widget.apkService.fetchInstalledApps(
        includeSystemApps: _includeSystemApps,
      );
      if (!mounted) return;
      setState(() {
        _allApps = apps;
        _isLoadingApps = false;
      });
    } on ApkServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoadingApps = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.errorGeneric;
        _isLoadingApps = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<ApkModel> get _filteredApps {
    if (_searchQuery.trim().isEmpty) return _allApps;
    final query = _searchQuery.toLowerCase().trim();
    return _allApps.where((app) {
      return app.name.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          if (_hasConsent) ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: AppStrings.actionRefresh,
              onPressed: _isLoadingApps ? null : _loadInstalledApps,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'revoke') _revokeConsent();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'revoke',
                  child: Text(AppStrings.actionRevokeConsent),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingConsent) {
      return StatusView.loading();
    }

    if (!_hasConsent) {
      return ConsentView(onAccept: _grantConsent);
    }

    if (_isLoadingApps) {
      return StatusView.loading();
    }

    if (_errorMessage != null) {
      return StatusView.error(
        message: _errorMessage!,
        onRetry: _loadInstalledApps,
      );
    }

    final displayedApps = _filteredApps;

    return Column(
      children: [
        SearchFilterBar(
          searchQuery: _searchQuery,
          onSearchChanged: (val) => setState(() => _searchQuery = val),
          includeSystemApps: _includeSystemApps,
          onToggleSystemApps: (val) {
            setState(() => _includeSystemApps = val);
            _loadInstalledApps();
          },
          totalCount: displayedApps.length,
        ),
        Expanded(
          child: displayedApps.isEmpty
              ? StatusView.empty()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: displayedApps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final app = displayedApps[index];
                    return AppListItem(
                      app: app,
                      onLaunch: () => _launchApp(app.packageName),
                      onSettings: () => _openSettings(app.packageName),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _launchApp(String packageName) async {
    try {
      final success = await widget.apkService.launchApp(packageName);
      if (!success && mounted) {
        _showSnackBar(AppStrings.appLaunchFailed);
      }
    } on ApkServiceException catch (e) {
      if (mounted) _showSnackBar(e.message);
    }
  }

  Future<void> _openSettings(String packageName) async {
    try {
      await widget.apkService.openAppSettings(packageName);
    } on ApkServiceException catch (e) {
      if (mounted) _showSnackBar(e.message);
    }
  }
}
