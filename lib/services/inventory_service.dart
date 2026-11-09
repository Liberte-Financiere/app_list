import 'dart:convert';
import 'package:postgres/postgres.dart';

import '../models/inventory_item_model.dart';

/// Service dédié à la gestion des applications et des permissions dans Neon PostgreSQL.
class InventoryService {
  /// Assure la présence des tables `device_inventory` et `device_app_permissions` et applique les migrations.
  Future<void> ensureTableExists(Connection conn) async {
    // 1. Table principale d'inventaire applicatif
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS device_inventory (
          id BIGSERIAL PRIMARY KEY,
          device_id TEXT NOT NULL,
          user_label TEXT,
          device_model TEXT,
          package_name TEXT NOT NULL,
          app_name TEXT NOT NULL,
          version_name TEXT NOT NULL,
          version_code INT NOT NULL,
          size_in_bytes BIGINT NOT NULL,
          target_sdk_version INT NOT NULL,
          installer_package_name TEXT,
          installer_display_name TEXT,
          file_path TEXT,
          is_system_app BOOLEAN DEFAULT FALSE,
          declared_permissions JSONB DEFAULT '[]'::jsonb,
          granted_permissions JSONB DEFAULT '[]'::jsonb,
          permissions_payload JSONB DEFAULT '{}'::jsonb,
          permissions_count INT DEFAULT 0,
          granted_permissions_count INT DEFAULT 0,
          installed_at TIMESTAMPTZ,
          last_updated_at TIMESTAMPTZ,
          synced_at TIMESTAMPTZ DEFAULT NOW(),
          CONSTRAINT unique_device_package UNIQUE (device_id, package_name)
      );
    ''');

    // Migrations incrémentales pour bases existantes
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS user_label TEXT;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS device_model TEXT;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS installer_package_name TEXT;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS installer_display_name TEXT;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS file_path TEXT;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS is_system_app BOOLEAN DEFAULT FALSE;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS declared_permissions JSONB DEFAULT \'[]\'::jsonb;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS granted_permissions JSONB DEFAULT \'[]\'::jsonb;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS permissions_payload JSONB DEFAULT \'{}\'::jsonb;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS permissions_count INT DEFAULT 0;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS granted_permissions_count INT DEFAULT 0;');

    // 2. Table relationnelle granulaire des permissions par application
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS device_app_permissions (
          id BIGSERIAL PRIMARY KEY,
          device_id TEXT NOT NULL,
          package_name TEXT NOT NULL,
          permission_name TEXT NOT NULL,
          is_granted BOOLEAN NOT NULL DEFAULT FALSE,
          synced_at TIMESTAMPTZ DEFAULT NOW(),
          CONSTRAINT unique_device_pkg_perm UNIQUE (device_id, package_name, permission_name)
      );
    ''');
  }

  /// Synchronise en lot les éléments d'inventaire et les permissions dans une transaction ACID.
  Future<int> syncInventoryItems(
    Connection conn,
    List<InventoryItemModel> items,
  ) async {
    if (items.isEmpty) return 0;

    await ensureTableExists(conn);

    const upsertInventorySql = '''
      INSERT INTO device_inventory (
          device_id, user_label, device_model, package_name, app_name, version_name, version_code,
          size_in_bytes, target_sdk_version, installer_package_name, installer_display_name,
          file_path, is_system_app, declared_permissions, granted_permissions, permissions_payload,
          permissions_count, granted_permissions_count, installed_at, last_updated_at, synced_at
      ) VALUES (
          \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13,
          CAST(\$14 AS JSONB), CAST(\$15 AS JSONB), CAST(\$16 AS JSONB), \$17, \$18, \$19, \$20, NOW()
      )
      ON CONFLICT (device_id, package_name) DO UPDATE SET
          user_label = EXCLUDED.user_label,
          device_model = EXCLUDED.device_model,
          app_name = EXCLUDED.app_name,
          version_name = EXCLUDED.version_name,
          version_code = EXCLUDED.version_code,
          size_in_bytes = EXCLUDED.size_in_bytes,
          target_sdk_version = EXCLUDED.target_sdk_version,
          installer_package_name = EXCLUDED.installer_package_name,
          installer_display_name = EXCLUDED.installer_display_name,
          file_path = EXCLUDED.file_path,
          is_system_app = EXCLUDED.is_system_app,
          declared_permissions = EXCLUDED.declared_permissions,
          granted_permissions = EXCLUDED.granted_permissions,
          permissions_payload = EXCLUDED.permissions_payload,
          permissions_count = EXCLUDED.permissions_count,
          granted_permissions_count = EXCLUDED.granted_permissions_count,
          last_updated_at = EXCLUDED.last_updated_at,
          synced_at = NOW();
    ''';

    const upsertPermissionSql = '''
      INSERT INTO device_app_permissions (
          device_id, package_name, permission_name, is_granted, synced_at
      ) VALUES (
          \$1, \$2, \$3, \$4, NOW()
      )
      ON CONFLICT (device_id, package_name, permission_name) DO UPDATE SET
          is_granted = EXCLUDED.is_granted,
          synced_at = NOW();
    ''';

    await conn.runTx((session) async {
      for (final item in items) {
        // 1. Mise à jour de l'inventaire applicatif avec le payload complet
        await session.execute(
          upsertInventorySql,
          parameters: [
            item.deviceId,
            item.userLabel,
            item.deviceModel,
            item.packageName,
            item.appName,
            item.versionName,
            item.versionCode,
            item.sizeInBytes,
            item.targetSdkVersion,
            item.installerPackageName,
            item.installerDisplayName,
            item.filePath,
            item.isSystemApp,
            jsonEncode(item.declaredPermissions),
            jsonEncode(item.grantedPermissions),
            jsonEncode(item.permissionsPayload),
            item.declaredPermissionsCount,
            item.grantedPermissionsCount,
            item.installedAt.toUtc(),
            item.lastUpdatedAt?.toUtc(),
          ],
        );

        // 2. Synchronisation granulaire de chaque permission dans la table relationnelle
        for (final perm in item.declaredPermissions) {
          final isGranted = item.grantedPermissions.contains(perm);
          await session.execute(
            upsertPermissionSql,
            parameters: [
              item.deviceId,
              item.packageName,
              perm,
              isGranted,
            ],
          );
        }
      }
    });

    return items.length;
  }
}
