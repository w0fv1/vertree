import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:vertree/core/Result.dart';

class LanFileShareServer {
  LanFileShareServer({
    this.sharePageBaseUrl = defaultSharePageBaseUrl,
    Future<List<String>> Function()? addressResolver,
    void Function(String message)? onLogInfo,
    void Function(String message)? onLogError,
  }) : _addressResolver = addressResolver ?? _discoverLanIpv4Addresses,
       _onLogInfo = onLogInfo,
       _onLogError = onLogError {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _purgeExpiredShares(),
    );
  }

  static const int defaultPort = 31424;
  static const int maxPortSearchSpan = 100;
  static const int defaultExpiryMinutes = 30;
  static const String defaultSharePageBaseUrl =
      'https://vertree.w0fv1.dev/file_share';

  final String sharePageBaseUrl;
  final Future<List<String>> Function() _addressResolver;
  final void Function(String message)? _onLogInfo;
  final void Function(String message)? _onLogError;

  late final Timer _cleanupTimer;
  final Map<String, _LanFileShareEntry> _shares =
      <String, _LanFileShareEntry>{};
  final Random _random = Random.secure();

  HttpServer? _server;
  int? _port;
  List<String> _lastKnownLanIps = const <String>[];

  bool get isRunning => _server != null;
  int? get port => _port;

  Map<String, dynamic> status() {
    _purgeExpiredShares();
    return {
      'running': isRunning,
      'port': _port,
      'sharePageBaseUrl': sharePageBaseUrl,
      'activeShareCount': _shares.length,
      'lastKnownLanIps': _lastKnownLanIps,
    };
  }

  Future<void> start() async {
    if (_server != null) {
      return;
    }

    for (
      var candidate = defaultPort;
      candidate < defaultPort + maxPortSearchSpan;
      candidate++
    ) {
      try {
        final server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          candidate,
        );
        _server = server;
        _port = candidate;
        unawaited(_listen(server));
        _logInfo('LAN file share server started at 0.0.0.0:$candidate');
        return;
      } on SocketException catch (error) {
        _logInfo(
          'Port $candidate unavailable for LAN file share server: $error',
        );
      }
    }

    throw Exception(
      'Unable to bind LAN file share server after trying ports '
      '$defaultPort-${defaultPort + maxPortSearchSpan - 1}',
    );
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _port = null;
    if (server != null) {
      await server.close(force: true);
      _logInfo('LAN file share server stopped');
    }
  }

  Future<void> dispose() async {
    _cleanupTimer.cancel();
    await stop();
  }

  Future<Result<Map<String, dynamic>, String>> createShare(
    String filePath, {
    int expiresInMinutes = defaultExpiryMinutes,
  }) async {
    _purgeExpiredShares();
    if (expiresInMinutes < 1) {
      return Result.eMsg('expiresInMinutes must be greater than 0');
    }

    final normalizedPath = p.normalize(filePath);
    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return Result.eMsg('File does not exist: $normalizedPath');
    }

    await start();
    final lanIps = await _resolveLanIps();
    if (lanIps.isEmpty || _port == null) {
      return Result.eMsg(
        'No reachable LAN IPv4 address was detected for this machine.',
      );
    }

    final stat = file.statSync();
    final now = DateTime.now();
    final entry = _LanFileShareEntry(
      token: _generateToken(),
      filePath: normalizedPath,
      fileName: p.basename(normalizedPath),
      fileSize: stat.size,
      createdAt: now,
      expiresAt: now.add(Duration(minutes: expiresInMinutes)),
    );
    _shares[entry.token] = entry;

    return Result.ok(_shareToMap(entry, lanIps));
  }

  Future<Map<String, dynamic>> listShares() async {
    _purgeExpiredShares();
    final lanIps = await _resolveLanIps();
    final items = _shares.values
        .map((entry) => _shareToMap(entry, lanIps))
        .toList(growable: false);
    items.sort(
      (left, right) => ((right['createdAt'] as String?) ?? '').compareTo(
        ((left['createdAt'] as String?) ?? ''),
      ),
    );
    return {'count': items.length, 'items': items};
  }

  Future<Result<Map<String, dynamic>, String>> getShare(String token) async {
    _purgeExpiredShares();
    final entry = _shares[token];
    if (entry == null) {
      return Result.eMsg('LAN file share not found: $token');
    }
    final lanIps = await _resolveLanIps();
    return Result.ok(_shareToMap(entry, lanIps));
  }

  Result<Map<String, dynamic>, String> revokeShare(String token) {
    _purgeExpiredShares();
    final entry = _shares.remove(token);
    if (entry == null) {
      return Result.eMsg('LAN file share not found: $token');
    }
    return Result.ok({
      'token': token,
      'revoked': true,
      'fileName': entry.fileName,
    });
  }

  Future<void> _listen(HttpServer server) async {
    try {
      await for (final request in server) {
        unawaited(_handleRequest(request));
      }
    } catch (error) {
      _logError('LAN file share listen loop failed: $error');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      _purgeExpiredShares();
      final segments = request.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);

      if (request.method == 'OPTIONS') {
        await _writeOptionsResponse(request);
        return;
      }

      if (segments.isEmpty || segments.first != 'file-share') {
        await _writeText(
          request,
          statusCode: HttpStatus.notFound,
          body: 'Not found',
        );
        return;
      }

      if (request.method == 'GET' &&
          segments.length == 3 &&
          segments[1] == 'probe') {
        await _handleProbe(request, segments[2]);
        return;
      }

      if (request.method == 'GET' &&
          segments.length == 3 &&
          segments[1] == 'pixel') {
        await _handlePixelProbe(request, segments[2]);
        return;
      }

      if (request.method == 'GET' &&
          segments.length == 3 &&
          segments[1] == 'download') {
        await _handleDownload(request, segments[2]);
        return;
      }

      if (request.method == 'GET' &&
          segments.length == 3 &&
          segments[1] == 'info') {
        await _handleInfo(request, segments[2]);
        return;
      }

      await _writeText(
        request,
        statusCode: HttpStatus.notFound,
        body: 'Not found',
      );
    } catch (error) {
      _logError('LAN file share request failed: $error');
      try {
        await _writeText(
          request,
          statusCode: HttpStatus.internalServerError,
          body: 'Internal server error',
        );
      } catch (_) {
        await request.response.close();
      }
    }
  }

  Future<void> _handleProbe(HttpRequest request, String token) async {
    final entry = _findActiveShare(token);
    if (entry == null) {
      await _writeText(
        request,
        statusCode: HttpStatus.notFound,
        body: 'Share not found',
      );
      return;
    }

    await _writeText(request, statusCode: HttpStatus.ok, body: 'ok');
  }

  Future<void> _handlePixelProbe(HttpRequest request, String token) async {
    final entry = _findActiveShare(token);
    if (entry == null) {
      await _writeText(
        request,
        statusCode: HttpStatus.notFound,
        body: 'Share not found',
      );
      return;
    }

    request.response.statusCode = HttpStatus.ok;
    _setCommonHeaders(request.response);
    request.response.headers.contentType = ContentType('image', 'gif');
    request.response.add(
      base64Decode(
        'R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
      ),
    );
    await request.response.close();
  }

  Future<void> _handleInfo(HttpRequest request, String token) async {
    final entry = _findActiveShare(token);
    if (entry == null) {
      await _writeJson(
        request,
        statusCode: HttpStatus.notFound,
        body: const {'success': false, 'message': 'Share not found'},
      );
      return;
    }

    await _writeJson(
      request,
      statusCode: HttpStatus.ok,
      body: {
        'success': true,
        'data': {
          'token': entry.token,
          'fileName': entry.fileName,
          'fileSize': entry.fileSize,
          'createdAt': entry.createdAt.toIso8601String(),
          'expiresAt': entry.expiresAt.toIso8601String(),
          'downloadCount': entry.downloadCount,
          'lastDownloadedAt': entry.lastDownloadedAt?.toIso8601String(),
        },
      },
    );
  }

  Future<void> _handleDownload(HttpRequest request, String token) async {
    final entry = _findActiveShare(token);
    if (entry == null) {
      await _writeText(
        request,
        statusCode: HttpStatus.notFound,
        body: 'Share not found',
      );
      return;
    }

    final file = File(entry.filePath);
    if (!file.existsSync()) {
      _shares.remove(token);
      await _writeText(
        request,
        statusCode: HttpStatus.notFound,
        body: 'Source file no longer exists',
      );
      return;
    }

    final stat = file.statSync();
    request.response.statusCode = HttpStatus.ok;
    _setCommonHeaders(request.response);
    request.response.headers.contentType = ContentType.binary;
    request.response.headers.set(HttpHeaders.contentLengthHeader, stat.size);
    request.response.headers.set(
      'content-disposition',
      _contentDisposition(entry.fileName),
    );
    await file.openRead().pipe(request.response);

    entry.downloadCount += 1;
    entry.lastDownloadedAt = DateTime.now();
  }

  _LanFileShareEntry? _findActiveShare(String token) {
    final entry = _shares[token];
    if (entry == null) {
      return null;
    }
    if (entry.isExpired) {
      _shares.remove(token);
      return null;
    }
    return entry;
  }

  void _purgeExpiredShares() {
    final expiredTokens = _shares.values
        .where((entry) => entry.isExpired)
        .map((entry) => entry.token)
        .toList(growable: false);
    for (final token in expiredTokens) {
      _shares.remove(token);
    }
  }

  Future<List<String>> _resolveLanIps() async {
    final addresses = await _addressResolver();
    _lastKnownLanIps = addresses;
    return addresses;
  }

  Map<String, dynamic> _shareToMap(
    _LanFileShareEntry entry,
    List<String> lanIps,
  ) {
    final currentPort = _port;
    final directDownloads = currentPort == null
        ? const <Map<String, dynamic>>[]
        : lanIps
              .map(
                (ip) => {
                  'ip': ip,
                  'downloadUrl':
                      'http://$ip:$currentPort/file-share/download/${entry.token}',
                  'probeUrl':
                      'http://$ip:$currentPort/file-share/probe/${entry.token}',
                  'pixelProbeUrl':
                      'http://$ip:$currentPort/file-share/pixel/${entry.token}',
                },
              )
              .toList(growable: false);

    return {
      'token': entry.token,
      'fileName': entry.fileName,
      'fileSize': entry.fileSize,
      'createdAt': entry.createdAt.toIso8601String(),
      'expiresAt': entry.expiresAt.toIso8601String(),
      'downloadCount': entry.downloadCount,
      'lastDownloadedAt': entry.lastDownloadedAt?.toIso8601String(),
      'sharePageUrl': currentPort == null
          ? null
          : _buildSharePageUrl(
              token: entry.token,
              fileName: entry.fileName,
              fileSize: entry.fileSize,
              expiresAt: entry.expiresAt,
              port: currentPort,
              lanIps: lanIps,
            ),
      'server': {
        'port': currentPort,
        'running': isRunning,
        'sharePageBaseUrl': sharePageBaseUrl,
      },
      'lanIps': lanIps,
      'directDownloads': directDownloads,
    };
  }

  String _buildSharePageUrl({
    required String token,
    required String fileName,
    required int fileSize,
    required DateTime expiresAt,
    required int port,
    required List<String> lanIps,
  }) {
    final fragment = Uri(
      queryParameters: {
        't': token,
        'p': port.toString(),
        'ips': lanIps.join(','),
        'name': base64Url.encode(utf8.encode(fileName)),
        'size': fileSize.toString(),
        'exp': expiresAt.millisecondsSinceEpoch.toString(),
      },
    ).query;
    return '$sharePageBaseUrl#$fragment';
  }

  String _generateToken() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _contentDisposition(String fileName) {
    final ascii = fileName
        .replaceAll(RegExp(r'[^ -~]'), '_')
        .replaceAll('"', '');
    final encoded = Uri.encodeComponent(fileName);
    return 'attachment; filename="$ascii"; filename*=UTF-8\'\'$encoded';
  }

  Future<void> _writeOptionsResponse(HttpRequest request) async {
    request.response.statusCode = HttpStatus.noContent;
    _setCommonHeaders(request.response);
    request.response.headers.set(
      HttpHeaders.accessControlAllowMethodsHeader,
      'GET, HEAD, OPTIONS',
    );
    request.response.headers.set(
      HttpHeaders.accessControlAllowHeadersHeader,
      'Content-Type',
    );
    request.response.headers.set(
      'Access-Control-Allow-Private-Network',
      'true',
    );
    await request.response.close();
  }

  Future<void> _writeText(
    HttpRequest request, {
    required int statusCode,
    required String body,
  }) async {
    request.response.statusCode = statusCode;
    _setCommonHeaders(request.response);
    request.response.headers.contentType = ContentType.text;
    request.response.write(body);
    await request.response.close();
  }

  Future<void> _writeJson(
    HttpRequest request, {
    required int statusCode,
    required Map<String, dynamic> body,
  }) async {
    request.response.statusCode = statusCode;
    _setCommonHeaders(request.response);
    request.response.headers.contentType = ContentType.json;
    request.response.write(const JsonEncoder.withIndent('  ').convert(body));
    await request.response.close();
  }

  void _setCommonHeaders(HttpResponse response) {
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.headers.set(HttpHeaders.accessControlAllowOriginHeader, '*');
    response.headers.set('Access-Control-Allow-Private-Network', 'true');
  }

  void _logInfo(String message) {
    _onLogInfo?.call(message);
  }

  void _logError(String message) {
    _onLogError?.call(message);
  }

  static Future<List<String>> _discoverLanIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );

    final results = <String>{};
    for (final networkInterface in interfaces) {
      for (final address in networkInterface.addresses) {
        if (address.type != InternetAddressType.IPv4 || address.isLoopback) {
          continue;
        }
        final raw = address.address.trim();
        if (raw.isEmpty || raw == '0.0.0.0') {
          continue;
        }
        results.add(raw);
      }
    }

    final sorted = results.toList(growable: false)..sort();
    return sorted;
  }
}

class _LanFileShareEntry {
  _LanFileShareEntry({
    required this.token,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    required this.expiresAt,
  });

  final String token;
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime createdAt;
  final DateTime expiresAt;
  int downloadCount = 0;
  DateTime? lastDownloadedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
