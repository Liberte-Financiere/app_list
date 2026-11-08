import 'package:postgres/postgres.dart';

/// Gestionnaire responsable de la configuration et de l'ouverture de connexion sécurisée Neon.
class NeonConnectionManager {
  final String host;
  final String database;
  final String user;
  final String password;
  final int port;

  NeonConnectionManager({
    String? connectionUrl,
    String? host,
    String? database,
    String? user,
    String? password,
    int? port,
  })  : host = _resolveHost(connectionUrl, host),
        database = _resolveDatabase(connectionUrl, database),
        user = _resolveUser(connectionUrl, user),
        password = _resolvePassword(connectionUrl, password),
        port = _resolvePort(connectionUrl, port);

  static const String _envUrl = String.fromEnvironment('NEON_DATABASE_URL');
  static const String _envHost = String.fromEnvironment('NEON_HOST');
  static const String _envDatabase = String.fromEnvironment('NEON_DATABASE', defaultValue: 'neondb');
  static const String _envUser = String.fromEnvironment('NEON_USER');
  static const String _envPassword = String.fromEnvironment('NEON_PASSWORD');
  static const int _envPort = int.fromEnvironment('NEON_PORT', defaultValue: 5432);

  static String _resolveHost(String? url, String? explicitHost) {
    if (explicitHost != null && explicitHost.trim().isNotEmpty) return explicitHost.trim();
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$1.isNotEmpty) return parsed.$1;
    }
    return _envHost.trim();
  }

  static String _resolveDatabase(String? url, String? explicitDb) {
    if (explicitDb != null && explicitDb.trim().isNotEmpty) return explicitDb.trim();
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$2.isNotEmpty) return parsed.$2;
    }
    return _envDatabase.trim();
  }

  static String _resolveUser(String? url, String? explicitUser) {
    if (explicitUser != null && explicitUser.trim().isNotEmpty) return explicitUser.trim();
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$3.isNotEmpty) return parsed.$3;
    }
    return _envUser.trim();
  }

  static String _resolvePassword(String? url, String? explicitPass) {
    if (explicitPass != null && explicitPass.isNotEmpty) return explicitPass;
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$4.isNotEmpty) return parsed.$4;
    }
    return _envPassword;
  }

  static int _resolvePort(String? url, int? explicitPort) {
    if (explicitPort != null && explicitPort > 0) return explicitPort;
    final effectiveUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : _envUrl;
    if (effectiveUrl.isNotEmpty) {
      final parsed = _parseUrl(effectiveUrl);
      if (parsed != null && parsed.$5 > 0) return parsed.$5;
    }
    return _envPort;
  }

  static (String, String, String, String, int)? _parseUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      final userInfo = uri.userInfo;
      final user = userInfo.contains(':')
          ? userInfo.substring(0, userInfo.indexOf(':'))
          : userInfo;
      final pass = userInfo.contains(':')
          ? userInfo.substring(userInfo.indexOf(':') + 1)
          : '';
      final db = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb';
      final port = uri.hasPort && uri.port != 0 ? uri.port : 5432;
      return (uri.host, db, user, pass, port);
    } on FormatException {
      return null;
    }
  }

  /// Indique si la configuration requise est présente.
  bool get isConfigured =>
      host.trim().isNotEmpty && user.trim().isNotEmpty && password.trim().isNotEmpty;

  /// Établit une connexion chiffrée SSL avec Neon.
  Future<Connection> openConnection() async {
    final endpoint = Endpoint(
      host: host.trim(),
      database: database.trim(),
      username: user.trim(),
      password: password.trim(),
      port: port,
    );

    return Connection.open(
      endpoint,
      settings: ConnectionSettings(
        sslMode: SslMode.require,
        connectTimeout: const Duration(seconds: 15),
        queryTimeout: const Duration(seconds: 45),
      ),
    );
  }
}
