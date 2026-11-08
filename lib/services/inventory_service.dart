import 'package:postgres/postgres.dart';

import '../models/inventory_item_model.dart';

/// Service dédié à la gestion des applications et de la table `device_inventory`.
class InventoryService {
  /// Assure la présence de la table `device_inventory` et applique les migrations nécessaires.
  Future<void> ensureTableExists(Connection conn) async {
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
          installed_at TIMESTAMPTZ,
          last_updated_at TIMESTAMPTZ,
          synced_at TIMESTAMPTZ DEFAULT NOW(),
          CONSTRAINT unique_device_package UNIQUE (device_id, package_name)
      );
    ''');

    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS user_label TEXT;');
    await conn.execute('ALTER TABLE device_inventory ADD COLUMN IF NOT EXISTS device_model TEXT;');
  }

  /// Synchronise en lot les éléments d'inventaire dans une transaction ACID.
  Future<int> syncInventoryItems(
    Connection conn,
    List<InventoryItemModel> items,
  ) async {
    if (items.isEmpty) return 0;

    await ensureTableExists(conn);

    const upsertSql = '''
      INSERT INTO device_inventory (
          device_id, user_label, device_model, package_name, app_name, version_name, version_code,
          size_in_bytes, target_sdk_version, installed_at, last_updated_at, synced_at
      ) VALUES (
          \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, NOW()
      )
      ON CONFLICT (device_id, package_name) DO UPDATE SET
          user_label = EXCLUDED.user_label,
          device_model = EXCLUDED.device_model,
          app_name = EXCLUDED.app_name,
          version_name = EXCLUDED.version_name,
          version_code = EXCLUDED.version_code,
          size_in_bytes = EXCLUDED.size_in_bytes,
          target_sdk_version = EXCLUDED.target_sdk_version,
          last_updated_at = EXCLUDED.last_updated_at,
          synced_at = NOW();
    ''';

    await conn.runTx((session) async {
      for (final item in items) {
        await session.execute(
          upsertSql,
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
            item.installedAt.toUtc(),
            item.lastUpdatedAt?.toUtc(),
          ],
        );
      }
    });

    return items.length;
  }
}
