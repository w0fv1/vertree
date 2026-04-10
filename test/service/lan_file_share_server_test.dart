import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vertree/service/LanFileShareServer.dart';
import 'package:vertree/service/LanSharePayloadCodec.dart';

void main() {
  group('LanFileShareServer', () {
    late Directory tempDir;
    late File file;
    late LanFileShareServer server;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vertree_share_test_');
      file = File('${tempDir.path}\\story.0.1.txt');
      await file.writeAsString('hello vertree');
      server = LanFileShareServer(
        sharePageBaseUrl: 'https://vertree.w0fv1.dev/file_share',
        addressResolver: () async => ['192.168.10.8', '10.0.0.6'],
        wifiNameResolver: () async => 'Office WiFi',
      );
    });

    tearDown(() async {
      await server.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'createShare returns compact route link and shorter direct downloads',
      () async {
        final result = await server.createShare(
          file.path,
          expiresInMinutes: 15,
        );

        expect(result.isOk, isTrue);
        final share = result.unwrap();
        final sharePageUrl = share['sharePageUrl'] as String?;
        final shareCode = share['shareCode'] as String?;
        final shareKey = share['shareKey'] as String?;
        final directDownloads = share['directDownloads'] as List<dynamic>;
        final token = share['token'] as String;
        final expiresAt = DateTime.parse(share['expiresAt'] as String);

        expect(share['fileName'], 'story.0.1.txt');
        expect(share['fileSize'], greaterThan(0));
        expect(share['networkName'], 'Office WiFi');
        expect(sharePageUrl, isNotNull);
        expect(shareCode, isNotNull);
        expect(shareKey, '1');
        expect(
          sharePageUrl,
          'https://vertree.w0fv1.dev/file_share#${LanSharePayloadCodec.compactFragmentPrefix}$shareCode',
        );

        final decodedCompactRoute = LanSharePayloadCodec.decodeCompactRoute(
          shareCode!,
        );
        expect(decodedCompactRoute['shareKey'], shareKey);
        expect(decodedCompactRoute['port'], server.port);
        expect(decodedCompactRoute['lanIps'], ['192.168.10.8', '10.0.0.6']);

        final legacyPayload = LanSharePayloadCodec.encode(
          token: token,
          port: server.port!,
          lanIps: ['192.168.10.8', '10.0.0.6'],
          fileName: 'story.0.1.txt',
          fileSize: share['fileSize'] as int,
          expiresAt: expiresAt,
          wifiName: 'Office WiFi',
        );
        final decodedLegacyPayload = LanSharePayloadCodec.decode(legacyPayload);
        expect(decodedLegacyPayload['token'], token);
        expect(decodedLegacyPayload['port'], server.port);
        expect(decodedLegacyPayload['lanIps'], ['192.168.10.8', '10.0.0.6']);
        expect(decodedLegacyPayload['fileName'], 'story.0.1.txt');
        expect(decodedLegacyPayload['fileSize'], share['fileSize']);
        expect(decodedLegacyPayload['networkName'], 'Office WiFi');
        expect(
          decodedLegacyPayload['expiresAt'],
          DateTime.fromMillisecondsSinceEpoch(
            expiresAt.millisecondsSinceEpoch,
          ).toIso8601String(),
        );

        final legacyFragment = Uri(
          queryParameters: {
            't': token,
            'p': '${server.port}',
            'ips': '192.168.10.8,10.0.0.6',
            'name': base64Url.encode(utf8.encode('story.0.1.txt')),
            'size': '${share['fileSize']}',
            'exp': '${expiresAt.millisecondsSinceEpoch}',
            'net': base64Url.encode(utf8.encode('Office WiFi')),
          },
        ).query;
        final legacySharePageUrl =
            'https://vertree.w0fv1.dev/file_share#$legacyFragment';
        expect(sharePageUrl!.length, lessThan(legacySharePageUrl.length));
        expect(sharePageUrl.length, lessThan((shareCode?.length ?? 0) + 80));

        expect(directDownloads, hasLength(2));
        expect(
          (directDownloads.first as Map<String, dynamic>)['pageUrl'],
          'http://192.168.10.8:${server.port}/file-share/page/$shareKey',
        );
        expect(
          (directDownloads.first as Map<String, dynamic>)['infoUrl'],
          'http://192.168.10.8:${server.port}/file-share/info/$shareKey',
        );
        expect(
          (directDownloads.first as Map<String, dynamic>)['downloadUrl'],
          'http://192.168.10.8:${server.port}/file-share/download/$shareKey',
        );
        expect(
          ((directDownloads.first as Map<String, dynamic>)['downloadUrl']
                  as String)
              .length,
          lessThan(
            'http://192.168.10.8:${server.port}/file-share/download/$token'
                .length,
          ),
        );
      },
    );

    test('revokeShare removes the share from subsequent reads', () async {
      final created = await server.createShare(file.path);
      final token = created.unwrap()['token'] as String;
      final shareKey = created.unwrap()['shareKey'] as String;

      final revoke = server.revokeShare(shareKey);
      final afterRevoke = await server.getShare(token);

      expect(revoke.isOk, isTrue);
      expect(afterRevoke.isErr, isTrue);
    });
  });
}
