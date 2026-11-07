import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/apk_model.dart';
import '../services/apk_service.dart';

/// Tableau de bord principal listant les applications avec gestion du consentement.
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
        _errorMessage = AppConstants.genericErrorMessage;
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
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          if (_hasConsent) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser la liste',
              onPressed: _isLoadingApps ? null : _loadInstalledApps,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'revoke') _revokeConsent();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'revoke',
                  child: Text('Révoquer l\'autorisation'),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasConsent) {
      return _buildConsentRequestView();
    }

    if (_isLoadingApps) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyse des applications installées...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadInstalledApps,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final displayedApps = _filteredApps;

    return Column(
      children: [
        _buildFiltersHeader(),
        Expanded(
          child: displayedApps.isEmpty
              ? _buildEmptyView()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: displayedApps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final app = displayedApps[index];
                    return _AppListCard(
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

  Widget _buildConsentRequestView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.security_outlined,
                  size: 64,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.consentTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.consentDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accepter et continuer'),
                    onPressed: _grantConsent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une application...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredApps.length} application(s) trouvée(s)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Row(
                children: [
                  Text(
                    'Système',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Switch(
                    value: _includeSystemApps,
                    onChanged: (val) {
                      setState(() => _includeSystemApps = val);
                      _loadInstalledApps();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? AppConstants.emptyListMessage
                : 'Aucune application ne correspond à votre recherche.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _launchApp(String packageName) async {
    try {
      final success = await widget.apkService.launchApp(packageName);
      if (!success && mounted) {
        _showSnackBar('Impossible de lancer cette application.');
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

class _AppListCard extends StatelessWidget {
  final ApkModel app;
  final VoidCallback onLaunch;
  final VoidCallback onSettings;

  const _AppListCard({
    required this.app,
    required this.onLaunch,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget iconWidget;
    if (app.iconBytes != null && app.iconBytes!.isNotEmpty) {
      iconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          app.iconBytes!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    } else {
      iconWidget = CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.android,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      );
    }

    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: iconWidget,
        title: Text(
          app.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              app.packageName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'v${app.versionName}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (app.isSystemApp) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Système',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Détails de l\'application',
              onPressed: onSettings,
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.teal),
              tooltip: 'Lancer l\'application',
              onPressed: onLaunch,
            ),
          ],
        ),
      ),
    );
  }
}
