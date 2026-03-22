import 'dart:io';

import 'package:test/test.dart';
import 'package:vertree/service/LanFileShareServer.dart';

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
      );
    });

    tearDown(() async {
      await server.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'createShare returns landing page and direct download candidates',
      () async {
        final result = await server.createShare(
          file.path,
          expiresInMinutes: 15,
        );

        expect(result.isOk, isTrue);
        final share = result.unwrap();
        final sharePageUrl = share['sharePageUrl'] as String?;
        final directDownloads = share['directDownloads'] as List<dynamic>;

        expect(share['fileName'], 'story.0.1.txt');
        expect(share['fileSize'], greaterThan(0));
        expect(sharePageUrl, isNotNull);
        expect(sharePageUrl, contains('https://vertree.w0fv1.dev/file_share#'));
        expect(sharePageUrl, contains('ips='));
        expect(directDownloads, hasLength(2));
        expect(
          (directDownloads.first as Map<String, dynamic>)['downloadUrl'],
          contains('/file-share/download/'),
        );
      },
    );

    test('revokeShare removes the share from subsequent reads', () async {
      final created = await server.createShare(file.path);
      final token = created.unwrap()['token'] as String;

      final revoke = server.revokeShare(token);
      final afterRevoke = await server.getShare(token);

      expect(revoke.isOk, isTrue);
      expect(afterRevoke.isErr, isTrue);
    });
  });
}
