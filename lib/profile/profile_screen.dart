import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../services/apk_service.dart';
import '../services/neon_sync_service.dart';

/// Écran dédié au profil de l'utilisateur, aux caractéristiques du terminal et à la confidentialité.
class ProfileScreen extends StatefulWidget {
  final ApkService apkService;
  final NeonSyncService neonSyncService;
  final VoidCallback? onConsentRevoked;
  final ValueChanged<String>? onUserNameChanged;
  final bool showAppBar;

  const ProfileScreen({
    super.key,
    required this.apkService,
    required this.neonSyncService,
    this.onConsentRevoked,
    this.onUserNameChanged,
    this.showAppBar = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _deviceId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final name = await widget.apkService.getUserName();
    final deviceId = await widget.neonSyncService.getOrCreateDeviceId();

    if (!mounted) return;
    setState(() {
      _userName = name ?? 'Utilisateur';
      _deviceId = deviceId;
      _isLoading = false;
    });
  }

  Future<void> _editUserName() async {
    final controller = TextEditingController(text: _userName);
    final formKey = GlobalKey<FormState>();

    final updatedName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Modifier le nom', style: AppTypography.titleMedium),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: AppStrings.profileInputLabel,
                hintText: AppStrings.profileInputHint,
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 2) {
                  return AppStrings.profileInputError;
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (updatedName != null && updatedName != _userName) {
      try {
        await widget.apkService.setUserName(updatedName);
        if (!mounted) return;
        setState(() => _userName = updatedName);
        widget.onUserNameChanged?.call(updatedName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nom d\'utilisateur mis à jour.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } on ApkServiceException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmRevokeConsent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Révoquer l\'autorisation ?', style: AppTypography.titleMedium),
          content: const Text(
            'L\'application supprimera votre profil et fermera l\'accès à l\'inventaire. '
            'Vous devrez renouveler l\'autorisation au prochain démarrage.',
            style: AppTypography.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Révoquer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await widget.apkService.setUserConsent(false);
        await widget.apkService.setUserName('');
        if (!mounted) return;
        if (widget.onConsentRevoked != null) {
          widget.onConsentRevoked!();
        } else {
          Navigator.pop(context, true);
        }
      } on ApkServiceException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _copyDeviceId() {
    if (_deviceId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _deviceId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identifiant unique copié dans le presse-papier.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            children: [
              _buildProfileHeader(isDark),
              const SizedBox(height: 24),
              _buildDeviceCard(isDark),
              const SizedBox(height: 16),
              _buildSyncCard(isDark),
              const SizedBox(height: 16),
              _buildPrivacyCard(isDark),
            ],
          );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Appareil'),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withAlpha(80), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(20),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _userName,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Modifier le pseudo',
                onPressed: _editUserName,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Profil actif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(bool isDark) {
    final syncState = widget.neonSyncService.stateNotifier.value;
    final deviceModel = syncState.deviceModel ?? 'Terminal Android';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smartphone_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Caractéristiques du terminal', style: AppTypography.titleMedium),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Modèle matériel', deviceModel),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInfoRow('Identifiant anonyme', _deviceId),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copier l\'identifiant',
                  onPressed: _copyDeviceId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard(bool isDark) {
    return ValueListenableBuilder<NeonSyncState>(
      valueListenable: widget.neonSyncService.stateNotifier,
      builder: (_, state, _) {
        final isConfigured = widget.neonSyncService.isConfigured;
        final syncTime = state.lastSyncTime != null ? state.formattedTime : 'Aucune';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Synchronisation Neon DB', style: AppTypography.titleMedium),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'État de connexion',
                  isConfigured ? 'Connecté (PostgreSQL TLS)' : 'Non configuré (.env absent)',
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Dernière synchronisation', syncTime),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Applications répertoriées',
                  '${state.syncedCount} application(s) synchronisée(s)',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyCard(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Confidentialité & Données', style: AppTypography.titleMedium),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'L\'autorisation d\'accès local aux paquets permet à l\'application d\'analyser les métadonnées (nom, version, taille). '
              'Vous pouvez révoquer cette autorisation à tout moment.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.no_accounts_outlined, color: Colors.red),
                label: const Text(
                  'Révoquer l\'autorisation et quitter',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _confirmRevokeConsent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
