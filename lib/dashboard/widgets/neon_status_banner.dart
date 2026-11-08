import 'package:flutter/material.dart';

import '../../constants/app_typography.dart';
import '../../services/neon_sync_service.dart';

/// Bannière interactive confirmant en temps réel l'enregistrement des données dans le backend Neon.
class NeonStatusBanner extends StatelessWidget {
  final NeonSyncService neonSyncService;

  const NeonStatusBanner({
    super.key,
    required this.neonSyncService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NeonSyncState>(
      valueListenable: neonSyncService.stateNotifier,
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showBackendProofDialog(context, state),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _backgroundColor(state.status),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _borderColor(state.status),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildLeadingIcon(state.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusLabel(state),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: _textColor(state.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _textColor(state.status).withAlpha(160),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadingIcon(NeonSyncStatus status) {
    switch (status) {
      case NeonSyncStatus.syncing:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
        );
      case NeonSyncStatus.success:
        return const Icon(
          Icons.cloud_done_rounded,
          size: 16,
          color: Color(0xFF2E7D32),
        );
      case NeonSyncStatus.error:
        return const Icon(
          Icons.cloud_off_rounded,
          size: 16,
          color: Color(0xFFC62828),
        );
      case NeonSyncStatus.idle:
        return const Icon(
          Icons.cloud_queue_rounded,
          size: 16,
          color: Color(0xFF616161),
        );
    }
  }

  String _statusLabel(NeonSyncState state) {
    switch (state.status) {
      case NeonSyncStatus.syncing:
        return 'Synchronisation avec la base Neon en cours...';
      case NeonSyncStatus.success:
        final userTag = state.userLabel != null ? '${state.userLabel} • ' : '';
        return 'Données dans Neon ($userTag${state.syncedCount} apps • ${state.formattedTime})';
      case NeonSyncStatus.error:
        return state.errorMessage ?? 'Échec de synchronisation avec Neon';
      case NeonSyncStatus.idle:
        if (state.lastSyncTime != null) {
          final userTag = state.userLabel != null ? '${state.userLabel} • ' : '';
          return 'Données à jour dans Neon ($userTag${state.syncedCount} apps)';
        }
        return neonSyncService.isConfigured
            ? 'Prêt pour la synchronisation automatique Neon'
            : 'Configuration Neon manquante (.env)';
    }
  }

  Color _backgroundColor(NeonSyncStatus status) {
    switch (status) {
      case NeonSyncStatus.syncing:
        return const Color(0xFFE3F2FD);
      case NeonSyncStatus.success:
        return const Color(0xFFE8F5E9);
      case NeonSyncStatus.error:
        return const Color(0xFFFFEBEE);
      case NeonSyncStatus.idle:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _borderColor(NeonSyncStatus status) {
    switch (status) {
      case NeonSyncStatus.syncing:
        return const Color(0xFF90CAF9);
      case NeonSyncStatus.success:
        return const Color(0xFFA5D6A7);
      case NeonSyncStatus.error:
        return const Color(0xFFEF9A9A);
      case NeonSyncStatus.idle:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _textColor(NeonSyncStatus status) {
    switch (status) {
      case NeonSyncStatus.syncing:
        return const Color(0xFF0D47A1);
      case NeonSyncStatus.success:
        return const Color(0xFF1B5E20);
      case NeonSyncStatus.error:
        return const Color(0xFFB71C1C);
      case NeonSyncStatus.idle:
        return const Color(0xFF424242);
    }
  }

  void _showBackendProofDialog(BuildContext context, NeonSyncState state) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.storage_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Preuve d\'envoi Backend', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProofRow('Identifiant attribué', state.userLabel ?? 'En cours'),
              _buildProofRow('Appareil détecté', state.deviceModel ?? 'Inconnu'),
              _buildProofRow('Statut', state.status == NeonSyncStatus.success ? 'Enregistré dans la base' : 'En attente'),
              _buildProofRow('Tables SQL', 'device_inventory & registered_devices'),
              _buildProofRow('Moteur SQL', 'Neon PostgreSQL (Serverless)'),
              _buildProofRow('Hôte', neonSyncService.host.isNotEmpty ? neonSyncService.host : 'Non configuré'),
              _buildProofRow('UUID Unique', state.deviceId ?? 'En cours de génération'),
              _buildProofRow('Applications envoyées', '${state.syncedCount} paquets'),
              if (state.lastSyncTime != null)
                _buildProofRow('Horodatage', state.lastSyncTime.toString().split('.')[0]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProofRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
