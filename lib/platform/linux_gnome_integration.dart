import 'dart:convert';
import 'dart:io';

enum GnomeSupportStatus {
  available,
  missingDependency,
  installedButDisabled,
  unavailable,
  unknown,
}

class GnomeSupportInfo {
  const GnomeSupportInfo({
    required this.status,
    required this.message,
    this.installCommand,
    this.installCommandLabel,
    this.restartCommand,
    this.restartCommandLabel,
  });

  final GnomeSupportStatus status;
  final String message;
  final String? installCommand;
  final String? installCommandLabel;
  final String? restartCommand;
  final String? restartCommandLabel;

  bool get isAvailable => status == GnomeSupportStatus.available;
}

class LinuxGnomeIntegration {
  static const String _extensionFileName = 'vertree_user_extension.py';
  static const String _actionsCommentPrefix = '# vertree-actions: ';
  static const Set<String> _appIndicatorExtensionIds = {
    'appindicatorsupport@rgcjonas.gmail.com',
    'ubuntu-appindicators@ubuntu.com',
  };

  static const String actionBackup = 'backup';
  static const String actionExpressBackup = 'expressBackup';
  static const String actionMonitor = 'monitor';
  static const String actionViewTree = 'viewTree';

  static const Map<String, String> _cliActionMap = {
    actionBackup: 'backup',
    actionExpressBackup: 'express-backup',
    actionMonitor: 'monit',
    actionViewTree: '',
  };

  static const Map<String, String> _labelMap = {
    actionBackup: '备份该文件',
    actionExpressBackup: '快速备份该文件',
    actionMonitor: '监控该文件',
    actionViewTree: '查看版本树',
  };

  static bool get isGnomeSession {
    final desktop = (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '')
        .toLowerCase();
    final session = (Platform.environment['DESKTOP_SESSION'] ?? '')
        .toLowerCase();
    final gnomeSessionId = Platform.environment['GNOME_DESKTOP_SESSION_ID'];
    return desktop.contains('gnome') ||
        session.contains('gnome') ||
        gnomeSessionId != null;
  }

  static Directory get _extensionDir => Directory(
    '${Platform.environment['HOME']}/.local/share/nautilus-python/extensions',
  );

  static File get _extensionFile =>
      File('${_extensionDir.path}/$_extensionFileName');

  static Iterable<Directory>
  get _localShellExtensionDirs => _appIndicatorExtensionIds.map(
    (extensionId) => Directory(
      '${Platform.environment['HOME']}/.local/share/gnome-shell/extensions/$extensionId',
    ),
  );

  static Iterable<Directory> get _systemShellExtensionDirs =>
      _appIndicatorExtensionIds.map(
        (extensionId) =>
            Directory('/usr/share/gnome-shell/extensions/$extensionId'),
      );

  static Future<bool> _commandExists(String command) async {
    try {
      final result = await Process.run('sh', ['-lc', 'command -v $command']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _detectPackageManager() async {
    for (final command in ['dnf', 'apt-get', 'pacman', 'zypper']) {
      if (await _commandExists(command)) {
        return command;
      }
    }
    return null;
  }

  static Future<String?> _installCommandFor(String capability) async {
    final packageManager = await _detectPackageManager();
    switch (packageManager) {
      case 'dnf':
        if (capability == 'nautilus-python') {
          return 'sudo dnf install nautilus-python';
        }
        if (capability == 'appindicator') {
          return 'sudo dnf install gnome-shell-extension-appindicator';
        }
      case 'apt-get':
        if (capability == 'nautilus-python') {
          return 'sudo apt-get install python3-nautilus';
        }
        if (capability == 'appindicator') {
          return 'sudo apt-get install gnome-shell-extension-appindicator';
        }
      case 'pacman':
        if (capability == 'nautilus-python') {
          return 'sudo pacman -S python-nautilus';
        }
        if (capability == 'appindicator') {
          return 'sudo pacman -S gnome-shell-extension-appindicator';
        }
      case 'zypper':
        if (capability == 'nautilus-python') {
          return 'sudo zypper install python3-nautilus';
        }
        if (capability == 'appindicator') {
          return 'sudo zypper install gnome-shell-extension-appindicator';
        }
    }
    return null;
  }

  static String _enableCommandFor(String extensionId) {
    return 'gnome-extensions enable $extensionId';
  }

  static Set<String> _parseExtensionIds(String rawOutput) {
    return rawOutput
        .split('\n')
        .map((line) => line.trim())
        .where(_appIndicatorExtensionIds.contains)
        .toSet();
  }

  static Set<String> _parseGsettingsExtensionIds(String rawOutput) {
    final matches = RegExp(
      r"'([^']+)'",
    ).allMatches(rawOutput).map((match) => match.group(1)).whereType<String>();
    return matches.where(_appIndicatorExtensionIds.contains).toSet();
  }

  static Future<Set<String>> _installedShellExtensionIds() async {
    final installed = <String>{};
    for (final dir in [
      ..._localShellExtensionDirs,
      ..._systemShellExtensionDirs,
    ]) {
      if (await dir.exists()) {
        installed.add(dir.uri.pathSegments[dir.uri.pathSegments.length - 2]);
      }
    }

    if (!await _commandExists('gnome-extensions')) {
      return installed;
    }
    try {
      final result = await Process.run('gnome-extensions', ['list']);
      if (result.exitCode != 0) {
        return installed;
      }
      installed.addAll(_parseExtensionIds(result.stdout.toString()));
    } catch (_) {
      return installed;
    }
    return installed;
  }

  static Future<Set<String>> _enabledShellExtensionIds() async {
    final enabled = <String>{};

    if (await _commandExists('gnome-extensions')) {
      try {
        final result = await Process.run('gnome-extensions', [
          'list',
          '--enabled',
        ]);
        if (result.exitCode == 0) {
          enabled.addAll(_parseExtensionIds(result.stdout.toString()));
        }
      } catch (_) {}
    }

    if (await _commandExists('gsettings')) {
      try {
        final result = await Process.run('gsettings', [
          'get',
          'org.gnome.shell',
          'enabled-extensions',
        ]);
        if (result.exitCode == 0) {
          enabled.addAll(_parseGsettingsExtensionIds(result.stdout.toString()));
        }
      } catch (_) {}
    }

    return enabled;
  }

  static Future<bool> isNautilusPythonAvailable() async {
    try {
      final result = await Process.run('python3', [
        '-c',
        '''
import sys
import gi
for version in ("4.1", "4.0", "3.0"):
    try:
        gi.require_version("Nautilus", version)
        from gi.repository import Nautilus  # noqa: F401
        sys.exit(0)
    except Exception:
        pass
sys.exit(1)
''',
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isSupported() async {
    if (!Platform.isLinux || !isGnomeSession) {
      return false;
    }
    return isNautilusPythonAvailable();
  }

  static Future<GnomeSupportInfo> getFilesMenuSupportInfo() async {
    if (!Platform.isLinux || !isGnomeSession) {
      return const GnomeSupportInfo(
        status: GnomeSupportStatus.unavailable,
        message: '当前不是 GNOME 会话。',
      );
    }

    if (await isNautilusPythonAvailable()) {
      return const GnomeSupportInfo(
        status: GnomeSupportStatus.available,
        message: 'GNOME Files 右键菜单支持已就绪。',
        restartCommand: 'nautilus -q',
        restartCommandLabel: '复制重启 Files 命令',
      );
    }

    return GnomeSupportInfo(
      status: GnomeSupportStatus.missingDependency,
      message: '需要先安装 nautilus-python，Vertree 才能向 GNOME Files 添加右键菜单。',
      installCommand: await _installCommandFor('nautilus-python'),
      installCommandLabel: '复制安装命令',
      restartCommand: 'nautilus -q',
      restartCommandLabel: '复制重启 Files 命令',
    );
  }

  static Future<GnomeSupportInfo> getTraySupportInfo() async {
    if (!Platform.isLinux || !isGnomeSession) {
      return const GnomeSupportInfo(
        status: GnomeSupportStatus.unavailable,
        message: '当前不是 GNOME 会话。',
      );
    }

    final installedIds = await _installedShellExtensionIds();
    final enabledIds = await _enabledShellExtensionIds();
    final installed = installedIds.isNotEmpty;
    final enabled = enabledIds.isNotEmpty;

    if (enabled) {
      return const GnomeSupportInfo(
        status: GnomeSupportStatus.available,
        message: '托盘支持已启用，可使用托盘和启动后最小化。',
      );
    }

    if (installed) {
      final extensionId = installedIds.toList()..sort();
      final enableCommand = extensionId.isEmpty
          ? null
          : _enableCommandFor(extensionId.first);
      return GnomeSupportInfo(
        status: GnomeSupportStatus.installedButDisabled,
        message: '已检测到托盘扩展，但当前还没有启用。先执行启用命令；如果执行后仍未生效，再重新登录 GNOME 会话。',
        installCommand: enableCommand,
        installCommandLabel: '复制启用命令',
      );
    }

    return GnomeSupportInfo(
      status: GnomeSupportStatus.missingDependency,
      message: 'GNOME 默认不会显示常规托盘图标。先安装托盘扩展；如果安装后仍未生效，再重新登录 GNOME 会话。',
      installCommand: await _installCommandFor('appindicator'),
      installCommandLabel: '复制安装命令',
    );
  }

  static Future<bool> isTrayAvailable() async {
    final info = await getTraySupportInfo();
    return info.isAvailable;
  }

  static Future<Set<String>> _readEnabledActions() async {
    if (!await _extensionFile.exists()) {
      return <String>{};
    }
    final content = await _extensionFile.readAsString();
    final firstLine = content
        .split('\n')
        .firstWhere(
          (line) => line.startsWith(_actionsCommentPrefix),
          orElse: () => '',
        );
    if (firstLine.isEmpty) {
      return <String>{};
    }
    final raw = firstLine.substring(_actionsCommentPrefix.length).trim();
    if (raw.isEmpty) {
      return <String>{};
    }
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => _cliActionMap.containsKey(item))
        .toSet();
  }

  static Future<bool> hasAction(String action) async {
    final enabled = await _readEnabledActions();
    return enabled.contains(action);
  }

  static Future<bool> addAction(String action) async {
    if (!await isSupported()) {
      return false;
    }
    final enabled = await _readEnabledActions();
    enabled.add(action);
    return _writeExtension(enabled);
  }

  static Future<bool> removeAction(String action) async {
    if (!Platform.isLinux) {
      return false;
    }
    final enabled = await _readEnabledActions();
    enabled.remove(action);
    return _writeExtension(enabled);
  }

  static Future<bool> applyAll(bool enabled) async {
    if (!Platform.isLinux) {
      return false;
    }
    if (!enabled) {
      return _writeExtension(<String>{});
    }
    if (!await isSupported()) {
      return false;
    }
    return _writeExtension(_cliActionMap.keys.toSet());
  }

  static Future<bool> _writeExtension(Set<String> actions) async {
    try {
      if (actions.isEmpty) {
        if (await _extensionFile.exists()) {
          await _extensionFile.delete();
        }
        return true;
      }

      await _extensionDir.create(recursive: true);
      final normalizedActions =
          actions.where(_cliActionMap.containsKey).toList()..sort();
      final content = _buildExtensionScript(normalizedActions);
      await _extensionFile.writeAsString(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _buildExtensionScript(List<String> actions) {
    final actionEntries = actions
        .map((action) {
          final cliAction = _cliActionMap[action]!;
          final label = _labelMap[action]!;
          return '    ("$action", "$label", "$cliAction"),';
        })
        .join('\n');

    final executable = jsonEncode(Platform.resolvedExecutable);
    final enabledActions = actions.join(',');

    return '''$_actionsCommentPrefix$enabledActions
import subprocess

import gi

for _nautilus_version in ("4.1", "4.0", "3.0"):
    try:
        gi.require_version("Nautilus", _nautilus_version)
        break
    except ValueError:
        pass

from gi.repository import GObject, GLib, Nautilus

VERTREE_EXECUTABLE = $executable
ACTIONS = [
$actionEntries
]


def _resolve_local_file_path(file_info):
    try:
        uri = file_info.get_uri()
    except Exception:
        return None
    if not uri or not uri.startswith("file://"):
        return None
    try:
        path, _ = GLib.filename_from_uri(uri)
        return path
    except Exception:
        return None


class VertreeExtension(GObject.GObject, Nautilus.MenuProvider):
    def _launch(self, action, path):
        try:
            command = [VERTREE_EXECUTABLE, path] if not action else [VERTREE_EXECUTABLE, action, path]
            subprocess.Popen(
                command,
                start_new_session=True,
            )
        except Exception:
            pass

    def get_file_items(self, *args):
        files = args[-1] if args else None
        if not files or len(files) != 1:
            return

        file_info = files[0]
        if file_info.is_directory():
            return

        path = _resolve_local_file_path(file_info)
        if not path:
            return

        root = Nautilus.MenuItem(
            name="Vertree::Root",
            label="Vertree",
            tip="Vertree 文件操作",
        )
        submenu = Nautilus.Menu()
        root.set_submenu(submenu)

        for action_key, label, cli_action in ACTIONS:
            item = Nautilus.MenuItem(
                name=f"Vertree::{action_key}",
                label=label,
                tip=label,
            )
            item.connect(
                "activate",
                lambda _item, action=cli_action, file_path=path: self._launch(
                    action, file_path
                ),
            )
            submenu.append_item(item)

        return [root]
''';
  }
}
