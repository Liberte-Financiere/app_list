import 'dart:async';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/apk_model.dart';
import '../services/apk_service.dart';
import '../services/neon_sync_service.dart';
import 'widgets/app_list_item.dart';
import 'widgets/neon_status_banner.dart';
import 'widgets/onboarding_view.dart';
import 'widgets/search_filter_bar.dart';
import 'widgets/status_view.dart';

/// Tableau de bord principal orchestrant la recherche, le filtrage et la gestion des APKs.
class DashboardScreen extends StatefulWidget {
  final ApkService apkService;
  final NeonSyncService neonSyncService;

  DashboardScreen({
    super.key,
    required this.apkService,
    NeonSyncService? neonSyncService,
  }) : neonSyncService = neonSyncService ?? NeonSyncService();

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingConsent = true;
  bool _hasConsent = false;
  String? _userName;
  bool _isLoadingApps = false;
  bool _includeSystemApps = false;
  String _searchQuery = '';
  String? _errorMessage;
  List<ApkModel> _allApps = const [];
  StreamSubscription<String>? _packageSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConsent();
    _listenToPackageChanges();
  }

  void _listenToPackageChanges() {
    _packageSubscription = widget.apkService.onPackageChanged.listen((packageName) {
      if (!mounted) return;
      if (_hasConsent && _userName != null && _userName!.isNotEmpty && !_isLoadingApps) {
        debugPrint('Événement système reçu pour $packageName: actualisation de l\'inventaire');
        _loadInstalledApps();
      }
    });
  }

  @override
  void dispose() {
    _packageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConsent() async {
    setState(() => _isLoadingConsent = true);
    final consent = await widget.apkService.hasUserConsent();
    final name = await widget.apkService.getUserName();
    if (!mounted) return;

    setState(() {
      _hasConsent = consent;
      _userName = name;
      _isLoadingConsent = false;
    });

    if (consent && name != null && name.isNotEmpty) {
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
    } on ApkServiceException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    }
  }

  Future<void> _completeProfile(String userName) async {
    try {
      await widget.apkService.setUserName(userName);
      if (!mounted) return;
      setState(() {
        _userName = userName;
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
      await widget.apkService.setUserName('');
      if (!mounted) return;
      setState(() {
        _hasConsent = false;
        _userName = null;
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

      // Synchronisation transparente en arrière-plan sans bloquer l'UI
      widget.neonSyncService.autoSyncApps(apps);
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
    final hasActiveSession = _hasConsent && (_userName != null && _userName!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppStrings.appName),
        actions: [
          if (hasActiveSession) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _userName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

    final isProfileComplete = _hasConsent && (_userName != null && _userName!.isNotEmpty);
    if (!isProfileComplete) {
      return OnboardingView(
        initialHasConsent: _hasConsent,
        onAcceptConsent: _grantConsent,
        onCompleteProfile: _completeProfile,
      );
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
        NeonStatusBanner(neonSyncService: widget.neonSyncService),
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
