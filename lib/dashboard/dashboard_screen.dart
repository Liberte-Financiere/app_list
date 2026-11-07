import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/apk_model.dart';
import '../services/apk_service.dart';

/// Écran principal du tableau de bord affichant les APKs disponibles.
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
  late Future<List<ApkModel>> _apksFuture;

  @override
  void initState() {
    super.initState();
    _loadApks();
  }

  void _loadApks() {
    setState(() {
      _apksFuture = widget.apkService.fetchApkList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser la liste',
            onPressed: _loadApks,
          ),
        ],
      ),
      body: FutureBuilder<List<ApkModel>>(
        future: _apksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApkServiceException
                ? error.message
                : AppConstants.genericErrorMessage;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadApks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final apks = snapshot.data ?? const <ApkModel>[];

          if (apks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.folder_open,
                    color: Colors.grey,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.emptyListMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: apks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final apk = apks[index];
              return _ApkListTile(apk: apk);
            },
          );
        },
      ),
    );
  }
}

class _ApkListTile extends StatelessWidget {
  final ApkModel apk;

  const _ApkListTile({required this.apk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.android,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          apk.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              apk.packageName,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'v${apk.versionName}',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 12),
                Text(
                  apk.formattedSize,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('APK sélectionné : ${apk.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
