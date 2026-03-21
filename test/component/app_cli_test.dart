import 'package:test/test.dart';
import 'package:vertree/component/app_cli.dart';

void main() {
  group('parseAppCliArgs', () {
    test('opens version tree when only a file path is provided', () {
      final request = parseAppCliArgs(['/tmp/demo.txt']);

      expect(request, isNotNull);
      expect(request!.action, AppCliAction.viewtree);
      expect(request.path, '/tmp/demo.txt');
    });

    test('parses backup and monitor subcommands', () {
      final backup = parseAppCliArgs(['backup', '/tmp/demo.txt']);
      final monit = parseAppCliArgs(['monit', '/tmp/demo.txt']);

      expect(backup!.action, AppCliAction.backup);
      expect(monit!.action, AppCliAction.monit);
    });

    test('accepts monitor alias and express backup subcommand', () {
      final monitor = parseAppCliArgs(['monitor', '/tmp/demo.txt']);
      final express = parseAppCliArgs(['express-backup', '/tmp/demo.txt']);

      expect(monitor!.action, AppCliAction.monit);
      expect(express!.action, AppCliAction.expressBackup);
    });

    test('keeps legacy flag invocations working', () {
      final backup = parseAppCliArgs(['--backup', '/tmp/demo.txt']);
      final service = parseAppCliArgs([
        '--service',
        '--viewtree',
        '/tmp/demo.txt',
      ]);

      expect(backup!.action, AppCliAction.backup);
      expect(service!.action, AppCliAction.viewtree);
    });

    test('rejects incomplete or unsupported forms', () {
      expect(parseAppCliArgs([]), isNull);
      expect(parseAppCliArgs(['backup']), isNull);
      expect(parseAppCliArgs(['--unknown', '/tmp/demo.txt']), isNull);
    });
  });
}
