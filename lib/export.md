# 文件层级结构

- component
  - [AppLogger.dart](#component-AppLogger-dart)
  - [Configer.dart](#component-Configer-dart)
  - [FileUtils.dart](#component-FileUtils-dart)
  - [I18n.dart](#component-I18n-dart)
  - [Notifier.dart](#component-Notifier-dart)
  - [WindowsRegistryHelper.dart](#component-WindowsRegistryHelper-dart)
- core
  - [FileVersionTree.dart](#core-FileVersionTree-dart)
  - [Monitor.dart](#core-Monitor-dart)
  - [Result.dart](#core-Result-dart)
  - [TreeBuilder.dart](#core-TreeBuilder-dart)
- [main.dart](#main-dart)
- [MonitService.dart](#MonitService-dart)
- [tray.dart](#tray-dart)
- [VerTreeRegistryService.dart](#VerTreeRegistryService-dart)
- view
  - component
    - [AppBar.dart](#view-component-AppBar-dart)
    - [Loading.dart](#view-component-Loading-dart)
    - [MonitTaskCard.dart](#view-component-MonitTaskCard-dart)
    - [SizeListenerWidget.dart](#view-component-SizeListenerWidget-dart)
    - tree
      - [Canvas.dart](#view-component-tree-Canvas-dart)
      - [CanvasComponent.dart](#view-component-tree-CanvasComponent-dart)
      - [CanvasManager.dart](#view-component-tree-CanvasManager-dart)
      - [EdgePainter.dart](#view-component-tree-EdgePainter-dart)
      - [FileLeaf.dart](#view-component-tree-FileLeaf-dart)
      - [FileTree.dart](#view-component-tree-FileTree-dart)
      - [Point.dart](#view-component-tree-Point-dart)
  - page
    - [BrandPage.dart](#view-page-BrandPage-dart)
    - [MonitPage.dart](#view-page-MonitPage-dart)
    - [SettingPage.dart](#view-page-SettingPage-dart)
    - [VersionTreePage.dart](#view-page-VersionTreePage-dart)

# 文件内容

<a id="component-AppLogger-dart"></a>
### AppLogger.dart
```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, error }

class AppLogger {
  late File _logFile;
  LogLevel _currentLevel;

  AppLogger(this._currentLevel);

  Future<void> init() async {
    final directory = await getApplicationSupportDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    _logFile = File('${logDir.path}/log_$timestamp.txt');

    // 延迟10秒后执行日志清理任务
    Future.delayed(Duration(seconds: 10), _cleanOldLogs);
  }

  void log(String message, {LogLevel level = LogLevel.info}) {
    if (level.index < _currentLevel.index) return;
    String logMessage = "[${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}] [${level.name.toUpperCase()}] $message";
    print(logMessage);
    _logFile.writeAsStringSync('$logMessage\n', mode: FileMode.append);
  }

  void debug(String message) => log(message, level: LogLevel.debug);
  void info(String message) => log(message, level: LogLevel.info);
  void error(String message) => log(message, level: LogLevel.error);

  Future<void> _cleanOldLogs() async {
    final directory = await getApplicationSupportDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (!await logDir.exists()) return;

    final now = DateTime.now();
    final files = logDir.listSync();
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        final diff = now.difference(stat.modified);
        if (diff.inDays > 30) {
          await file.delete();
        }
      }
    }
  }
}

```

<a id="component-Configer-dart"></a>
### Configer.dart
```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Configer {
  static const String _configFileName = "config.json";
  late String configFilePath ;

  /// 用于存储整个配置内容（key-value 结构）
  Map<String, dynamic> _config = {};

  Configer();

  /// 初始化配置，读取存储的 JSON 文件
  Future<void> init() async {
    Directory dir = await getApplicationSupportDirectory();
    final configFile = File('${dir.path}/$_configFileName');

    configFilePath = configFile.path;

    if (await configFile.exists()) {
      try {
        String content = await configFile.readAsString();
        _config = jsonDecode(content);
      } catch (e) {
        print("Error reading config file: $e");
      }
    } else {
      // 如果不存在配置文件，则创建一个空配置
      await _saveConfig();
    }
  }

  /// 通用的 get 方法：根据 key 获取配置
  T get<T>(String key, T defaultValue) {
    return _config.containsKey(key) ? _config[key] as T : defaultValue;
  }

  /// 通用的 set 方法：设置配置并立即写入文件
  void set<T>(String key, T value) {
    _config[key] = value;
    _saveConfig();
  }

  /// 私有方法：保存配置到 JSON 文件
  Future<void> _saveConfig() async {
    final dir = await getApplicationSupportDirectory();
    final configFile = File('${dir.path}/$_configFileName');

    await configFile.writeAsString(jsonEncode(_config));
  }

  /// 将配置转换为 JSON（可根据需要使用）
  Map<String, dynamic> toJson() => _config;
}

```

<a id="component-FileUtils-dart"></a>
### FileUtils.dart
```dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vertree/main.dart';

class FileUtils {
  /// 处理路径，确保路径格式适合当前操作系统
  static String _normalizePath(String path) {
    return p.normalize(path); // 处理不规范的路径，适配当前系统
  }

  /// 打开文件夹
  static void openFolder(String folderPath) {
    try {
      String normalizedPath = _normalizePath(folderPath);

      if (!Directory(normalizedPath).existsSync()) {
        logger.error("文件夹不存在: $normalizedPath");
        return;
      }

      if (Platform.isWindows) {
        Process.run('explorer.exe', [normalizedPath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [normalizedPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [normalizedPath]);
      }
    } catch (e) {
      logger.error("打开文件夹失败: $e");
    }
  }

  /// 打开文件
  static void openFile(String filePath) {
    try {
      String normalizedPath = _normalizePath(filePath);

      if (!File(normalizedPath).existsSync()) {
        logger.error("文件不存在: $normalizedPath");
        return;
      }

      if (Platform.isWindows) {
        Process.run('explorer.exe', [normalizedPath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [normalizedPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [normalizedPath]);
      }
    } catch (e) {
      logger.error("打开文件失败: $e");
    }
  }
}

```

<a id="component-I18n-dart"></a>
### I18n.dart
```dart
class I18n{



}
```

<a id="component-Notifier-dart"></a>
### Notifier.dart
```dart
import 'package:local_notifier/local_notifier.dart';
import 'package:vertree/component/FileUtils.dart';
import 'dart:io';

import 'package:vertree/main.dart';

/// 初始化本地通知
Future<void> initLocalNotifier() async {
  await localNotifier.setup(
    appName: 'Vertree',
    shortcutPolicy: ShortcutPolicy.requireCreate, // 仅适用于 Windows
  );
}

/// 显示通知
Future<void> showWindowsNotification(String title, String description) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onShow = () {
    logger.info('通知已显示: ${notification.identifier}');
  };

  notification.onClose = (closeReason) {
    logger.info('通知已关闭: ${notification.identifier} - 关闭原因: $closeReason');
  };

  notification.onClick = () {
    logger.info('用户点击了通知: ${notification.identifier}');
  };

  await notification.show();
}

/// 显示通知（点击后打开文件）
Future<void> showWindowsNotificationWithFile(String title, String description, String filePath) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onClick = () {
    logger.info('用户点击了通知: ${notification.identifier}');
    FileUtils.openFile(filePath);
  };

  await notification.show();
}
/// 显示通知（点击后打开文件夹）
Future<void> showWindowsNotificationWithFolder(String title, String description, String folderPath) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onClick = () {
    logger.info('用户点击了通知: ${notification.identifier}');
    FileUtils.openFolder(folderPath);
  };

  await notification.show();
}
/// 显示通知（点击后执行自定义任务）
Future<void> showWindowsNotificationWithTask(
    String title, String description, Function task) async {
  LocalNotification notification = LocalNotification(
    title: title,
    body: description,
  );

  notification.onClick = () {
    logger.info('用户点击了通知: \${notification.identifier}');
    task(); // 执行传入的任务
  };

  await notification.show();
}


```

<a id="component-WindowsRegistryHelper-dart"></a>
### WindowsRegistryHelper.dart
```dart
  import 'dart:math';

import 'package:vertree/main.dart';
  import 'package:win32_registry/win32_registry.dart';

  class RegistryHelper {
    /// 检查注册表项是否存在
    static bool checkRegistryKeyExists(RegistryHive hive, String path) {
      try {
        final key = Registry.openPath(hive, path: path, desiredAccessRights: AccessRights.readOnly);
        key.close();
        return true;
      } catch (e) {
        logger.error('检查注册表path: "$path" 失败: $e');
        return false;
      }
    }
    /// 检查注册表项是否存在
    static bool checkRegistryMenuExists(String menuName) {

      return checkRegistryKeyExists(
          RegistryHive.classesRoot, r'*\shell\' + menuName);
    }
    /// 添加或更新注册表项
    static bool addOrUpdateRegistryKey(String path, String keyName, String value) {
      try {
        final key = Registry.openPath(RegistryHive.localMachine, path: path, desiredAccessRights: AccessRights.allAccess);
        key.createValue(RegistryValue.string(keyName, value));
        key.close();
        return true;
      } catch (e) {
        logger.error('添加或更新注册表项失败: $e');
        return false;
      }
    }

    /// 删除注册表项
    static bool deleteRegistryKey(String path, String keyName) {
      try {
        final key = Registry.openPath(RegistryHive.localMachine, path: path, desiredAccessRights: AccessRights.allAccess);
        key.deleteValue(keyName);
        key.close();
        return true;
      } catch (e) {
        logger.error('删除注册表项失败: $e');
        return false;
      }
    }

    /// 增加右键菜单项功能按钮（适用于选中文件），支持自定义图标
    static bool addContextMenuOption(String menuName, String command, {String? iconPath}) {
      try {
        String registryPath = r'*\shell\' + menuName;
        String commandPath = '$registryPath\\command';

        logger.info('尝试创建右键菜单: registryPath="$registryPath", commandPath="$commandPath"');

        // 打开或创建 registryPath
        final shellKey = Registry.openPath(RegistryHive.classesRoot,
            path: r'*\shell', desiredAccessRights: AccessRights.allAccess);

        final menuKey = shellKey.createKey(menuName);
        menuKey.createValue(RegistryValue.string('', menuName));

        // 如果提供了 iconPath，则添加图标
        if (iconPath != null && iconPath.isNotEmpty) {
          menuKey.createValue(RegistryValue.string('Icon', iconPath));
          logger.info('已为 "$menuName" 设置图标: $iconPath');
        }

        menuKey.close();
        shellKey.close();

        logger.info('成功创建 registryPath: $registryPath');

        // 打开或创建 commandPath
        final menuCommandKey = Registry.openPath(RegistryHive.classesRoot,
            path: registryPath, desiredAccessRights: AccessRights.allAccess);
        final commandKey = menuCommandKey.createKey('command');
        commandKey.createValue(RegistryValue.string('', command));
        commandKey.close();
        menuCommandKey.close();

        logger.info('成功创建 commandPath: $commandPath -> $command');

        return true;
      } catch (e) {
        logger.error('添加右键菜单失败: $e');
        return false;
      }
    }


    static bool removeContextMenuOption(String menuName) {
      try {
        String registryPath = r'*\shell\' + menuName;

        // 直接打开完整路径
        final key = Registry.openPath(RegistryHive.classesRoot, path: r'*\shell', desiredAccessRights: AccessRights.allAccess);

        // 递归删除整个键
        key.deleteKey(menuName, recursive: true);
        key.close();

        logger.info('成功删除右键菜单项: $registryPath');
        return true;
      } catch (e) {
        logger.error('删除右键菜单失败: $e');
        return false;
      }
    }





  }

```

<a id="core-FileVersionTree-dart"></a>
### FileVersionTree.dart
```dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:vertree/core/Result.dart';

class FileVersion implements Comparable<FileVersion> {
  final List<Segment> segments;

  FileVersion._(this.segments);

  factory FileVersion(String versionString) {
    return FileVersion._(_parse(versionString));
  }

  static List<Segment> _parse(String versionString) {
    final parts = versionString.split('-');
    final segs = <Segment>[];
    for (final part in parts) {
      final bv = part.split('.');
      if (bv.length != 2) {
        throw FormatException("版本段格式错误，每段必须是 X.Y 形式: $part");
      }
      final branch = int.parse(bv[0]);
      final ver = int.parse(bv[1]);
      segs.add(Segment(branch, ver));
    }
    return segs;
  }

  // 为了方便，这里提供一个从 _Segment 列表构造的方法
  factory FileVersion.fromSegments(List<Segment> segs) {
    return FileVersion._(List<Segment>.from(segs));
  }

  /// 生成下一个版本（同分支下版本号+1）
  /// 如：0.0 -> 0.1,  0.1-0.0 -> 0.1-0.1,  0.1-1.0 -> 0.1-1.1
  FileVersion nextVersion() {
    if (segments.isEmpty) {
      // 理论上不会发生
      return FileVersion('0.0');
    }
    final newSegs = List<Segment>.from(segments);
    final last = newSegs.last;
    newSegs[newSegs.length - 1] = Segment(last.branch, last.version + 1);
    return FileVersion.fromSegments(newSegs);
  }

  /// 创建一个新的分支，在末尾增加 (0,0)
  /// 如：0.1 -> 0.1-0.0,  0.1-1.0 -> 0.1-1.0-0.0
  FileVersion branchVersion(int branchIndex) {
    final newSegs = List<Segment>.from(segments);
    newSegs.add(Segment(branchIndex, 0));
    return FileVersion.fromSegments(newSegs);
  }

  /// 字符串输出：将每段用 '-' 连接，形如 "0.1-0.0"
  @override
  String toString() {
    return segments.map((seg) => '${seg.branch}.${seg.version}').join('-');
  }

  /// 逐段比较，用于排序
  @override
  int compareTo(FileVersion other) {
    final minLen = (segments.length < other.segments.length) ? segments.length : other.segments.length;
    for (int i = 0; i < minLen; i++) {
      final diffBranch = segments[i].branch - other.segments[i].branch;
      if (diffBranch != 0) return diffBranch;

      final diffVer = segments[i].version - other.segments[i].version;
      if (diffVer != 0) return diffVer;
    }
    return segments.length - other.segments.length;
  }

  /// 判断是否和 [other] 在同一个分支
  /// 规则：
  /// 1) 段数相同
  /// 2) 对应段的 branch 相同（version 不限制）
  bool isSameBranch(FileVersion other) {
    // 段数必须相同
    if (segments.length != other.segments.length) {
      return false;
    }
    // 逐段比较 branch
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].branch != other.segments[i].branch) {
        return false;
      }
    }
    return true;
  }

  /// [other] 是否是 [this] 的“第一个子版本”
  ///
  /// 规则：
  /// - 必须是直接子版本
  /// - 最后一段的 version = 父版本 version + 1
  ///
  /// 例：
  /// - 0.0 -> 0.1 是第一个子版本
  /// - 0.0 -> 0.2 虽然是直接子版本，但不是第一个
  bool isChild(FileVersion other) {
    if (!isSameBranch(other)) return false;

    return segments.last.version + 1 == other.segments.last.version;
  }

  /// [other] 是否是 [this] 的“直接分支”
  ///
  /// 规则：
  /// - 段数比 this 多 1
  /// - 前面所有段都相同
  /// - 新增的最后一段 version == 0
  ///   (branch 不限, 但 version 必须为 0)
  ///
  /// 例：
  /// - 0.0 -> 0.0-0.0 / 0.0-1.0 / 0.0-10.0 都是直接分支
  /// - 0.0 -> 0.0-10.1 不是 (version != 0)
  /// - 0.0 -> 0.0-0.0-0.0 不是 (多了 2 段)
  bool isDirectBranch(FileVersion other) {
    // 1) other 的段数 = this 段数 + 1
    if (other.segments.length != segments.length + 1) {
      return false;
    }

    // 2) 前面所有段都相同
    final n = segments.length;
    for (int i = 0; i < n; i++) {
      if (segments[i] != other.segments[i]) {
        return false;
      }
    }

    // 3) 新增段 version == 0
    final lastOther = other.segments[other.segments.length - 1];
    if (lastOther.version != 0) {
      return false;
    }

    return true;
  }

  /// [other] 是否是 [this] 的“间接分支”
  ///
  /// 规则：
  /// - [other] 的段数 > [this] 的段数
  /// - [this] 的所有段都是 [other] 的前缀
  /// - 不要求最后一段 version 是否为 0，也不要求只多 1 段
  ///   只要层级数更多且能完美匹配前缀，即可视为间接分支
  ///
  /// 例：
  /// - 0.0 -> 0.0-0.0-1.0 是间接分支
  /// - 0.0 -> 0.0-1.1-1.0 是间接分支
  /// - 0.1 -> 0.0-1.0 不是（前缀不匹配）
  /// - 0.0-0.0 -> 0.0-0.1-1.0 不是 (第二段不相同)
  bool isIndirectBranch(FileVersion other) {
    if (other.segments.length <= segments.length) {
      return false;
    }
    // 检查前缀是否完全相同
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] != other.segments[i]) {
        return false;
      }
    }
    return true;
  }

  // ============== 核心新增方法 END ==============
}

/// 私有段结构：branch, version
class Segment {
  final int branch;
  final int version;

  const Segment(this.branch, this.version);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Segment) return false;
    return branch == other.branch && version == other.version;
  }

  @override
  int get hashCode => Object.hash(branch, version);
}

/// 文件元数据信息
class FileMeta {
  /// 文件全名（含扩展名），如 "myFile.0.1-0.0.txt"
  String fullName = "";

  /// 不含版本号的文件主名称，例如对 "myFile.0.1-0.0.txt" 来说，这里是 "myFile"
  String name = "";

  /// 文件版本，对 "myFile.0.1-0.0.txt" 来说，这里是 FileVersion("0.1-0.0")
  FileVersion version = FileVersion("0.0");

  /// 文件扩展名，不含点号，例如 "txt"
  String extension = "";

  /// 文件完整路径
  final String fullPath;

  /// 对应的 File 对象
  final File originalFile;

  /// 文件大小，单位字节
  int fileSize = 0;

  /// 文件创建时间
  DateTime creationTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// 文件上次修改时间
  DateTime lastModifiedTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// 构造函数
  FileMeta(this.fullPath) : originalFile = File(fullPath) {
    // 1) 先获得不带路径的完整文件名
    fullName = path.basename(fullPath);

    // 2) 分离扩展名
    extension = path.extension(fullPath).replaceFirst('.', '');

    // 3) 去掉扩展名后的文件名（不含 .ext）
    final fileName = path.basenameWithoutExtension(fullPath);
    //    对于 "myFile.0.1-0.0.txt" => fileName = "myFile.0.1-0.0"
    //    对于 "myFile.txt"         => fileName = "myFile"
    //    对于 "myFile"            => fileName = "myFile"

    // 4) 在 fileName 中，查找第一个 '.' 作为分界点
    final dotIndex = fileName.indexOf('.');
    if (dotIndex == -1) {
      // 没有版本号，默认 0.0
      name = fileName;
      version = FileVersion("0.0");
    } else {
      // 截取 [0 .. dotIndex) 作为 name
      name = fileName.substring(0, dotIndex);
      // 截取 [dotIndex+1 .. end) 作为版本串
      final versionStr = fileName.substring(dotIndex + 1);
      // 如果为空，则默认 "0.0"
      version = versionStr.isEmpty ? FileVersion("0.0") : FileVersion(versionStr);
    }

    // 5) 若文件实际存在，获取文件大小和时间信息
    if (originalFile.existsSync()) {
      final fileStat = originalFile.statSync();
      fileSize = fileStat.size;
      creationTime = fileStat.changed;
      lastModifiedTime = fileStat.modified;
    }
  }

  @override
  String toString() {
    return 'FileMeta('
        'fullName: $fullName, '
        'name: $name, '
        'version: $version, '
        'extension: $extension, '
        'fullPath: $fullPath, '
        'fileSize: $fileSize bytes, '
        'creationTime: $creationTime, '
        'lastModifiedTime: $lastModifiedTime'
        ')';
  }
}

/// 文件节点，表示文件的一个版本，并可能有子版本（children）与分支（branches）
class FileNode {
  late FileMeta mate;
  late File originalFile;
  FileNode? child;
  late FileNode parent;
  final List<FileNode> branches = [];
  int branchIndex = -1;
  FileNode? firstBranch;

  int totalChildren = 0;

  get version => mate.version;

  // Newly added lists for even and odd versions
  final List<FileNode> topBranches = [];
  final List<FileNode> bottomBranches = [];

  FileNode(String fullPath) {
    mate = FileMeta(fullPath);
    originalFile = File(fullPath);
  }

  FileNode.fromMeta(FileMeta fileMeta) {
    mate = fileMeta;
    originalFile = fileMeta.originalFile;
  }

  bool noChildren() {
    return child == null && topBranches.isEmpty && bottomBranches.isEmpty;
  }

  int getHeight([int side = 0]) {
    if (noChildren()) {
      return 1;
    }
    int tmp = 0;

    if (child != null) {
      tmp += child!.getHeight();
    } else {
      tmp += 1;
    }


    if (side == 1 || side == 0) {
      for (var branch in topBranches) {
        tmp += branch.getHeight();
      }
    }

    if (side == -1 || side == 0) {
      for (var branch in bottomBranches) {
        tmp += branch.getHeight();
      }
    }

    return tmp;
  }

  // New method to get all closer branches
  List<FileNode> _getCloserParentBranches() {
    // First, determine whether the branch is a part of topBranches or bottomBranches
    List<FileNode> branches = parent.topBranches.contains(this) ? parent.topBranches : parent.bottomBranches;

    // If the branch is not part of either, return an empty list
    if (!parent.topBranches.contains(this) && !parent.bottomBranches.contains(this)) {
      return [];
    }

    // Find the index of the branch in the relevant list (topBranches or bottomBranches)
    int index = branches.indexOf(this);

    if (branches.isEmpty) {
      return [];
    }

    // Return all branches with smaller index (i.e., closer to the current node)
    return branches.sublist(0, index);
  }

  int getParentRelativeHeight() {
    int tmp = 0;

    bool isTopBranch = parent.topBranches.contains(this);
    int top = isTopBranch ? 1 : -1;
    int branchHeight = 0;

    if (isTopBranch) {
      for (var value in bottomBranches) {
        branchHeight += value.getHeight();
      }
    } else {
      for (var value in topBranches) {
        branchHeight += value.getHeight();
      }
    }

    tmp += branchHeight;

    if (child != null) {
      tmp += child!.getHeight(-top) - 1;
    }

    List<FileNode> closerBranches = _getCloserParentBranches();

    for (var closerBranch in closerBranches) {
      tmp += closerBranch.getHeight();
    }

    int parentChildHeight = 0;
    if (parent.child != null) {
      parentChildHeight += parent.child!.getHeight(top);
    }
    tmp += parentChildHeight;

    return tmp;
  }

  void addChild(FileNode node) {
    child ??= node;
    child?.parent = this;

    totalChildren += 1;
  }

  void addBranch(FileNode branch) {
    if (!branches.any((b) => b.mate.version == branch.mate.version)) {
      branches.add(branch);
      branch.parent = this;
      totalChildren += 1;

      branches.sort((a, b) => a.mate.version.compareTo(b.mate.version));
      if (branch.mate.version.segments.last.branch > branchIndex) {
        branchIndex = branch.mate.version.segments.last.branch;
      }
      // Classify the branch based on version
      if (branch.mate.version.segments.last.branch % 2 == 0) {
        topBranches.add(branch); // Even version, add to topBranches
      } else {
        bottomBranches.add(branch); // Odd version, add to bottomBranches
      }
    }
  }

  Future<Result<FileNode, String>> safeBackup() async {
    try {
      // 1. 获取下一个版本号
      final newVersion = mate.version.nextVersion();
      // 2. 拼接新文件名、路径
      final newFileName = '${mate.name}.${newVersion.toString()}.${mate.extension}';
      final dirPath = path.dirname(mate.fullPath);
      final newFilePath = path.join(dirPath, newFileName);

      // 3. 若文件不存在，则直接备份；否则创建分支
      final newFile = File(newFilePath);
      if (!newFile.existsSync()) {
        return await backup();
      } else {
        return await branch();
      }
    } catch (e) {
      return Result.eMsg("safeBackup 失败: ${e.toString()}");
    }
  }


  /// 备份当前文件（创建下一个版本），并将新版本加入 children
  Future<Result<FileNode, String>> backup() async {
    if (child != null) {
      return Result.eMsg("当前版本已有长子，不允许备份");
    }

    try {
      final newVersion = mate.version.nextVersion();
      final newFileName = '${mate.name}.${newVersion.toString()}.${mate.extension}';
      final dirPath = path.dirname(mate.fullPath);
      final newFilePath = path.join(dirPath, newFileName);
      await originalFile.copy(newFilePath);

      final newNode = FileNode(newFilePath);
      addChild(newNode);
      return Result.ok(newNode);
    } catch (e) {
      return Result.err("备份文件失败: ${e.toString()}");
    }
  }

  Future<Result<FileNode, String>> branch() async {
    try {
      final branchedVersion = mate.version.branchVersion(branchIndex + 1);
      final newFileName = '${mate.name}.${branchedVersion.toString()}.${mate.extension}';
      final dirPath = path.dirname(mate.fullPath);
      final newFilePath = path.join(dirPath, newFileName);
      await originalFile.copy(newFilePath);

      final newNode = FileNode(newFilePath);
      addBranch(newNode);
      return Result.ok(newNode);
    } catch (e) {
      return Result.err("创建分支失败: ${e.toString()}");
    }
  }

  /// 返回 true 表示已成功插入（或跳过），false 表示无法插入
  bool push(FileNode node) {

    // 1. 如果版本号相同，直接跳过（也可以视情况选择报错或更新）
    if (mate.version.compareTo(node.mate.version) == 0) {
      return false;
    }

    // 2. 如果是“直接子版本”，直接设置为 child
    if (mate.version.isChild(node.mate.version)) {
      addChild(node);
      return true;
    }

    // 3. 如果是“直接分支”
    if (mate.version.isDirectBranch(node.mate.version)) {
      addBranch(node);
      return true;
    }

    // 4. 若都不符合，则尝试递归推送给已有 child
    if (child != null) {
      if (child!.push(node)) {
        return true;
      }
    }

    // 5. 再尝试递归推送给各分支
    for (var branch in branches) {
      if (branch.push(node)) {
        return true;
      }
    }

    // 6. 如果以上都无法插入，则在这里提示无法推送
    return false;
  }

  String toTreeString({int level = 0, String label = 'Root'}) {
    final indent = ' ' * (level * 4); // 4 个空格作为缩进单位
    final buffer = StringBuffer();

    buffer.writeln('$indent$label[${mate.fullName} (version: ${mate.version})]');

    // 处理 child, 它应该和父节点对齐
    if (child != null) {
      buffer.write(child!.toTreeString(level: level, label: 'Child'));
    }

    // 处理 branches，它们应该增加一个额外的缩进
    for (var branch in branches) {
      buffer.write(branch.toTreeString(level: level + 1, label: 'Branch'));
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'FileNode('
        'file: $mate, '
        'child: [$child], '
        'branches: [$branches])';
  }
}

```

<a id="core-Monitor-dart"></a>
### Monitor.dart
```dart
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vertree/MonitService.dart';
import 'package:vertree/main.dart';

class Monitor {
  late String filePath;
  late String backupDirPath;
  late File file;
  late Directory backupDir;

  DateTime? _lastBackupTime;
  StreamSubscription<FileSystemEvent>? _subscription;

  Monitor(this.filePath) {
    file = File(filePath);
    if (!file.existsSync()) {
      print("File does not exist: $filePath");
      return;
    }

    final directory = file.parent;
    final fileName = p.basenameWithoutExtension(file.path);

    backupDir = Directory(p.join(directory.path, '${fileName}_bak'));
    backupDirPath = backupDir.path;

    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
  }

  Monitor.fromTask(FileMonitTask fileMonitTask) {
    filePath = fileMonitTask.filePath;
    file = File(filePath);
    if (!file.existsSync()) {
      print("File does not exist: $filePath");
      return;
    }

    backupDirPath = fileMonitTask.backupDirPath;

    backupDir = Directory(backupDirPath);

    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
  }

  void start() {
    _subscription = file.parent.watch(events: FileSystemEvent.all).listen((event) {
      print("事件触发: ${event.type} -> ${event.path}");
      if (event.path == file.absolute.path) {
        _handleFileChange(file, backupDir);
      }
    });

    logger.info("Started monitoring: $filePath");
  }

  void _handleFileChange(File file, Directory backupDir) {
    final now = DateTime.now();
    logger.info("handleFileChange ${file.path}");
    if (_lastBackupTime == null || now.difference(_lastBackupTime!).inMinutes >= 1) {
      logger.info("backupFile ${file.path}");

      _backupFile(file, backupDir);
      _lastBackupTime = now;
    }else{
      logger.info("_lastBackupTime ${_lastBackupTime?.toIso8601String()}");
    }
  }

  void _backupFile(File file, Directory backupDir) {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = p.join(backupDir.path, '${p.basename(file.path)}_$timestamp.bak${p.extension(file.path)}');
      logger.info("Backup to: $backupPath");
      file.copySync(backupPath);
      logger.info("Backup created: $backupPath");
    } catch (e) {
      logger.error("Error creating backup: $e");
    }
  }

  void stop() {
    _subscription?.cancel();
    logger.info("Stopped monitoring: $filePath");
  }
}

```

<a id="core-Result-dart"></a>
### Result.dart
```dart
class Result<T, E> {
  final String msg;
  final T? value;
  final E? error;

  Result.ok(this.value, [this.msg = "ok"]) : error = null;

  Result.err([this.error, this.msg = "err"]) : value = null;

  /// 只有错误消息，而不关心具体错误类型
  Result.eMsg([this.msg = "err"]) : error = null, value = null;

  bool get isOk => msg == 'ok';
  bool get isErr => msg == 'err';

  T unwrap() {
    if (isOk) return value as T;
    throw Exception('Attempted to unwrap an Err value');
  }

  T unwrapOr(T defaultValue) => isOk ? value as T : defaultValue;

  E unwrapErr() {
    if (isErr) return error as E;
    throw Exception('Attempted to unwrapErr an Ok value');
  }

  Result<U, E> map<U>(U Function(T) fn) {
    if (isOk) {
      return Result.ok(fn(value as T));
    } else {
      return Result.err(error as E, msg);
    }
  }

  Result<T, F> mapErr<F>(F Function(E) fn) {
    if (isErr) {
      return Result.err(fn(error as E), msg);
    } else {
      return Result.ok(value as T, msg);
    }
  }

  /// 类似模式匹配，但返回void，更适合做副作用操作
  void when({
    required void Function(T value) ok,
    required void Function(E? error, String msg) err,
  }) {
    if (isOk) {
      // 如果是ok分支，value不为null
      ok(value as T);
    } else {
      // 如果是err分支，可能是 err(...) 或 eMsg(...)
      // 有的情况下 error 为 null（eMsg 情况）
      err(error, msg);
    }
  }

  /// 类似 match，但将 T 映射为 U 并返回
  U match<U>(U Function(T) ok, U Function(E) err) {
    return isOk ? ok(value as T) : err(error as E);
  }

  @override
  String toString() {
    if (isOk) {
      return 'Result.ok(value: $value, msg: "$msg")';
    } else if (isErr) {
      return 'Result.err(error: $error, msg: "$msg")';
    }
    return 'Result(msg: "$msg")';
  }
}

```

<a id="core-TreeBuilder-dart"></a>
### TreeBuilder.dart
```dart
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';

Future<Result<FileNode, void>> buildTree(String selectedFileNodePath) async {
  // print("selectedFileNodePath $selectedFileNodePath");

  final Map<String, FileNode> fileVersionMap = {};
  FileNode selectedFileNode = FileNode(selectedFileNodePath);
  // print("selectedFileNode $selectedFileNode");
  String dirname = path.dirname(selectedFileNodePath);

  final files = await Directory(dirname).list().toList();

  // 过滤掉所有 name 与 selectedFileNode 不相同的文件
  final filteredFiles =
      files.where((file) {
        if (file is! File) return false;

        final fileMeta = FileMeta(file.path);
        return fileMeta.name == selectedFileNode.mate.name;
      }).toList();

  List<FileNode> fileNodes = [];

  // 找到 version 最低的文件作为 rootNode
  FileNode? rootNode;

  for (var file in filteredFiles) {
    final fileMeta = FileMeta(file.path);
    final fileNode = FileNode(file.path);
    fileNodes.add(fileNode);

    if (rootNode == null ||
        fileMeta.version.compareTo(rootNode.mate.version) < 0) {
      rootNode = fileNode;
    }
  }

  if (rootNode == null) {
    return Result.eMsg("未找到根节点");
  }

  // 自定义排序方法：
  fileNodes.sort((a, b) => a.mate.version.compareTo(b.mate.version));

  List<FileNode> sortedFileNodes = fileNodes;

  for (var node in sortedFileNodes) {
    // print(node.mate.version.toString());
    rootNode.push(node);
  }

  return Result.ok(rootNode);
}


```

<a id="main-dart"></a>
### main.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/AppLogger.dart';
import 'package:vertree/component/Configer.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/tray.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/MonitPage.dart';
import 'package:vertree/view/page/VersionTreePage.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

final logger = AppLogger(LogLevel.debug);
late void Function(Widget page) go;
late MonitService monitService;
late Configer configer  = Configer();
void main(List<String> args) async {
  await logger.init();
  await configer.init();


  monitService = MonitService();
  logger.info("启动参数: $args");

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "w0fv1.dev.vertree",
      onSecondWindow: (args) {
        logger.info("onSecondWindow $args");
        processArgs(args);
      },
      bringWindowToFront: false,
    );
    await initLocalNotifier(); // 确保通知系统已初始化
    await showWindowsNotification("Vertree运行中", "树状文件版本管理🌲");

    // 隐藏窗口
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(600, 600),
        center: true,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
      ),
      () async {
        Future.delayed(Duration(milliseconds: 1500), () async {
          await windowManager.hide(); // 启动时隐藏窗口

          monitService.startAll().then((_) async {
            if (monitService.runningTaskCount == 0) {
              logger.info("Vertree没有需要监控的文件");
              return;
            }
            await showWindowsNotificationWithTask(
              "Vertree开始监控 ${monitService.runningTaskCount} 个文件",
              "点击查看监控任务",
              (_) {
                go(MonitPage());
              },
            );

            return;
          });
        });
      },
    );
    String appPath = Platform.resolvedExecutable;
    logger.info("Current app path: $appPath");

    Tray().init();
    runApp(const MainPage()); // 运行设置页面
  } catch (e) {
    logger.error('Vertree启动失败: $e');
    exit(0);
  }
}

void processArgs(List<String> args) {
  if (args.length < 3) {
    windowManager.hide();
    return;
  }
  String action = args[1];
  String path = args.last;

  if (action == "--backup") {
    logger.info(path);
    FileNode fileNode = FileNode(path);
    fileNode.safeBackup().then((Result<FileNode, String> result) {
      if (result.isErr) {
        showWindowsNotification("Vertree备份文件失败，", result.msg);
        return;
      }
      FileNode backup = result.unwrap();

      showWindowsNotificationWithFile("Vertree已备份文件，", "点击我打开新文件", backup.mate.fullPath);
    });
  } else if (action == "--monitor") {
    logger.info(path);
    monitService.addFileMonitTask(path).then((Result<FileMonitTask, String> fileMonitTaskResult) {
      if (fileMonitTaskResult.isErr) {
        showWindowsNotification("Vertree监控失败，", fileMonitTaskResult.msg);
        return;
      }
      FileMonitTask fileMonitTask = fileMonitTaskResult.unwrap();

      showWindowsNotificationWithFolder("Vertree以开始监控文件，", "点击我打开备份目录", fileMonitTask.backupDirPath);
    });
  } else if (action == "--viewtree") {
    logger.info(path);
    go(FileTreePage(path: path));
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Widget page = BrandPage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertree维树',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)),
      home: page,
    );
  }

  @override
  void initState() {
    super.initState();
    go = goPage;
  }

  void goPage(Widget page) async {
    await windowManager.show(); // 显示窗口

    setState(() {
      this.page = page;
    });
  }
}

```

<a id="MonitService-dart"></a>
### MonitService.dart
```dart
import 'dart:async';
import 'dart:io';
import 'package:vertree/component/Configer.dart';
import 'package:vertree/core/Monitor.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';
import 'package:path/path.dart' as p;

class MonitService {

  /// 由 MonitService 持有的任务列表
  List<FileMonitTask> monitFileTasks = [];

  /// 返回正在运行的监控任务数量
  int get runningTaskCount {
    return monitFileTasks.where((task) => task.isRunning).length;
  }

  MonitService() {
    // 从 configer 中获取存储的任务信息（JSON），再转换为对象列表
    final filesJson = configer.get<List<dynamic>>("monitFiles", <dynamic>[]);
    monitFileTasks = filesJson.map((e) => FileMonitTask.fromJson(e)).toList();

    // 如果 task.isRunning == true，则创建对应的 monitor 实例并启动监控
    for (var task in monitFileTasks) {
      if (task.isRunning) {
        _startMonitor(task);
      }
    }

  }

  /// 将当前任务列表保存到 configer
  Future<void> _saveMonitFiles() async {
    configer.set("monitFiles", monitFileTasks.map((t) => t.toJson()).toList());
  }

  /// 返回当前正在运行的监控数量
  int get runningMonitorCount {
    return monitFileTasks.where((t) => t.monitor != null).length;
  }

  /// 启动所有已标记为运行的监视任务
  Future<void> startAll() async {

    for (var task in monitFileTasks) {
      if (task.isRunning && task.monitor == null) {
        _startMonitor(task);
      }
    }
  }

  /// 添加文件监视任务
  Future<Result<FileMonitTask, String>> addFileMonitTask(String path) async {

    // 检查任务是否已存在
    if (monitFileTasks.any((task) => task.filePath == path)) {
      logger.info("Task already exists for: $path");
      return Result.eMsg("Task already exists for: $path");
    }
    // 创建新任务
    final newTask = FileMonitTask(filePath: path, isRunning: true);

    // 启动监视
    _startMonitor(newTask);

    // 加入列表并保存配置
    monitFileTasks.add(newTask);
    await _saveMonitFiles();

    return Result.ok(newTask);
  }

  /// 移除文件监视任务
  Future<void> removeFileMonitTask(String path) async {

    final index = monitFileTasks.indexWhere((t) => t.filePath == path);
    if (index == -1) {
      print("Task not found for: $path");
      return;
    }

    // 停止监视
    final task = monitFileTasks[index];
    _pauseMonitor(task);

    // 从列表中移除并保存
    monitFileTasks.removeAt(index);
    await _saveMonitFiles();
  }

  /// 切换文件监视任务的运行状态
  Future<FileMonitTask> toggleFileMonitTaskStatus(FileMonitTask task) async {

    final index = monitFileTasks.indexWhere((t) => t.filePath == task.filePath);
    if (index == -1) {
      print("Task not found for: ${task.filePath}");
      return task;
    }

    // 切换状态
    task.isRunning = !task.isRunning;
    if (task.isRunning) {
      _startMonitor(task);
    } else {
      _pauseMonitor(task);
    }

    monitFileTasks[index] = task;
    await _saveMonitFiles();

    return task;
  }

  /// 启动监视
  void _startMonitor(FileMonitTask task) {
    task.monitor ??= Monitor.fromTask(task);
    task.monitor?.start();
    task.isRunning = true;
  }

  /// 停止监视
  void _pauseMonitor(FileMonitTask task) {
    task.monitor?.stop();
    task.monitor = null;
    task.isRunning = false;
  }
}


class FileMonitTask {
  String filePath;
  late String backupDirPath;
  bool isRunning; // 是否正在运行
  late File file;
  Monitor? monitor;

  FileMonitTask({required this.filePath, this.isRunning = false}) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print("File does not exist: $filePath");
      return;
    }

    final directory = file.parent;
    final fileName = p.basenameWithoutExtension(file.path);

    final backupDir = Directory(p.join(directory.path, '${fileName}_bak'));
    backupDirPath = backupDir.path;
  }

  // 将对象转换为 Map（用于 JSON 序列化）
  Map<String, dynamic> toJson() => {"filePath": filePath, "backupDirPath": backupDirPath, "isRunning": isRunning};

  // 从 Map（JSON 反序列化）创建对象
  factory FileMonitTask.fromJson(Map<String, dynamic> json) {
    return FileMonitTask(filePath: json["filePath"], isRunning: json["isRunning"] ?? false);
  }

  @override
  String toString() => 'FileMonitTask(filePath: $filePath, backupDirPath: $backupDirPath, isRunning: $isRunning)';
}

```

<a id="tray-dart"></a>
### tray.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:window_manager/window_manager.dart';

class Tray with TrayListener {
  ValueNotifier<bool> shouldForegroundOnContextMenu = ValueNotifier(false);

  void init() {
    trayManager.addListener(this);
    initTray();
  }

  void initTray() async {
    // 设置托盘图标
    String iconPath = Platform.isWindows ? 'assets/img/logo/logo.ico' : 'assets/img/logo/logo.png';

    await trayManager.setIcon(iconPath);

    // 设置托盘菜单
    List<MenuItem> menuItems = [
      MenuItem(
        key: 'setting',
        label: '设置',
        toolTip: 'App设置',
        icon: Platform.isWindows ? "assets/img/icon/setting.ico" : "assets/img/icon/setting.png",
        onClick: (MenuItem menuItem) async {
          go(SettingPage());
        },
      ),
      MenuItem(
        key: 'exit',
        label: '退出',
        toolTip: '退出APP',
        icon: Platform.isWindows ? "assets/img/icon/exit.ico" : "assets/img/icon/exit.png",
        onClick: (MenuItem menuItem) {
          exit(0); // 退出程序
        },
      ),
    ];
    Menu menu = Menu(items: menuItems);

    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    go(BrandPage());
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == "setting") {}
  }
}

```

<a id="VerTreeRegistryService-dart"></a>
### VerTreeRegistryService.dart
```dart
import 'dart:io';
import 'component/WindowsRegistryHelper.dart';

class VerTreeRegistryService {
  static const String backupMenuName = "VerTree Backup";
  static const String monitorMenuName = "VerTree Monitor";
  static const String viewTreeMenuName = "View VerTree"; // 新增菜单项名称

  static String exePath = Platform.resolvedExecutable;

  static bool checkBackupKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(backupMenuName);
  }

  static bool checkMonitorKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(monitorMenuName);
  }

  static bool checkViewTreeKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(viewTreeMenuName); // 新增检查方法
  }

  static bool addVerTreeBackupContextMenu() {
    return RegistryHelper.addContextMenuOption(
      backupMenuName,
      '$exePath --backup %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool addVerTreeMonitorContextMenu() {
    return RegistryHelper.addContextMenuOption(
      monitorMenuName,
      '$exePath --monitor %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool addVerTreeViewContextMenu() { // 新增方法
    return RegistryHelper.addContextMenuOption(
      viewTreeMenuName,
      '$exePath --viewtree %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool removeVerTreeBackupContextMenu() {
    return RegistryHelper.removeContextMenuOption(backupMenuName);
  }

  static bool removeVerTreeMonitorContextMenu() {
    return RegistryHelper.removeContextMenuOption(monitorMenuName);
  }

  static bool removeVerTreeViewContextMenu() { // 新增方法
    return RegistryHelper.removeContextMenuOption(viewTreeMenuName);
  }
}

```

<a id="view-component-AppBar-dart"></a>
### AppBar.dart
```dart
import 'package:flutter/material.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:window_manager/window_manager.dart';

class VAppBar extends StatefulWidget implements PreferredSizeWidget {
  final double height;
  final Widget title;
  final bool showMinimize;
  final bool showMaximize;
  final bool showClose;

  final bool goHome;

  const VAppBar({
    super.key,
    this.height = 40,
    required this.title,
    this.showMinimize = true,
    this.showMaximize = true,
    this.showClose = true,
    this.goHome = true,
  });

  @override
  State<VAppBar> createState() => _VAppBarState();

  @override
  Size get preferredSize => Size(double.infinity, height);
}

class _VAppBarState extends State<VAppBar> {
  bool isMaximized = false;

  @override
  void initState() {
    super.initState();

    windowManager.isMaximized().then((onValue) {
      setState(() {
        isMaximized = onValue;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (_) async => await windowManager.startDragging(),
      onDoubleTap: () async {
        if (isMaximized) {
          await windowManager.restore();
          isMaximized = false;
        } else {
          await windowManager.maximize();
          isMaximized = true;
        }
        setState(() {});
      },
      child: Container(
        height: 40,
        padding: EdgeInsets.all(4),
        color: Colors.transparent,
        child: Row(
          children: [
            if (widget.goHome)
              _buildAppBarButton(Icons.arrow_back_rounded, () async {
                go(BrandPage());
              }),

            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.title,
              ),
            ),
            if (widget.goHome)
              _buildAppBarButton(Icons.home_rounded, () async {
                go(BrandPage());
              }),

            /// **窗口操作按钮**
            Row(
              children: [
                if (widget.showMinimize)
                  _buildAppBarButton(Icons.remove, () async {
                    await windowManager.minimize();
                  }),
                if (widget.showMinimize) const SizedBox(width: 6),

                if (widget.showMaximize)
                  _buildAppBarButton(isMaximized ? Icons.filter_none : Icons.crop_square, () async {
                    if (isMaximized) {
                      await windowManager.restore();
                      isMaximized = false;
                    } else {
                      await windowManager.maximize();
                      isMaximized = true;
                    }
                    setState(() {});
                  }),
                if (widget.showMaximize) const SizedBox(width: 6),

                if (widget.showClose)
                  _buildAppBarButton(Icons.close, () async {
                    await windowManager.hide(); // 仅隐藏窗口
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **窗口按钮组件**
  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed, {Color color = Colors.black87, double padding = 6}) {
    double size = widget.height - 4;

    return IconButton(
      padding: EdgeInsets.all(padding),
      onPressed: onPressed,
      icon: Icon(icon, size: size / 3 * 2 - padding, color: color),
    );
  }
}

```

<a id="view-component-Loading-dart"></a>
### Loading.dart
```dart
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class LoadingWidget extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingWidget({
    Key? key,
    required this.child,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child, // 底层内容
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3), // 调整半透明背景的透明度
              child: Center(
                child: SizedBox(
                  width: 40, // 控制加载指示器大小
                  height: 40,
                  child: LoadingIndicator(
                    indicatorType: Indicator.circleStrokeSpin,
                    colors: const [Colors.white],
                    strokeWidth: 2,
                    backgroundColor: Colors.transparent,
                    pathBackgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

```

<a id="view-component-MonitTaskCard-dart"></a>
### MonitTaskCard.dart
```dart

// 封装的卡片组件
import 'package:flutter/material.dart';
import 'package:vertree/MonitService.dart';

class MonitTaskCard extends StatelessWidget {
  final FileMonitTask task;
  final ValueChanged<bool> onSwitchChanged; // switch状态变更
  final VoidCallback onOpenFolder;         // 打开文件夹动作

  const MonitTaskCard({
    Key? key,
    required this.task,
    required this.onSwitchChanged,
    required this.onOpenFolder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 左侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.filePath,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "备份文件夹："+task.backupDirPath,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            // 右侧Action
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.6, // 调整大小
                  child: Switch(
                    value: task.isRunning,
                    onChanged: onSwitchChanged,
                  ),
                ),

                IconButton(
                  onPressed: onOpenFolder,
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

<a id="view-component-SizeListenerWidget-dart"></a>
### SizeListenerWidget.dart
```dart
import 'package:flutter/material.dart';

class SizeListenerWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChange;

  const SizeListenerWidget({
    Key? key,
    required this.child,
    required this.onSizeChange,
  }) : super(key: key);

  @override
  _SizeListenerWidgetState createState() => _SizeListenerWidgetState();
}

class _SizeListenerWidgetState extends State<SizeListenerWidget> {
  final GlobalKey _key = GlobalKey();
  Size? oldSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  @override
  void didUpdateWidget(covariant SizeListenerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    if (_key.currentContext == null) return;
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final newSize = renderBox.size;

    if (oldSize != newSize) {
      oldSize = newSize;
      widget.onSizeChange(newSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

```

<a id="view-component-tree-Canvas-dart"></a>
### Canvas.dart
```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';
import 'package:vertree/view/component/tree/EdgePainter.dart';
import 'CanvasManager.dart';

class TreeCanvas extends StatefulWidget {
  final TreeCanvasManager manager;
  final double height;
  final double width;
  final List<CanvasComponentContainer>? children;
  final List<Edge>? edges;

  const TreeCanvas({super.key, required this.manager, this.height = 300, this.width = 500, this.children, this.edges});

  @override
  _TreeCanvasState createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<TreeCanvas> with TickerProviderStateMixin {
  final Map<String, CanvasComponentContainer> components = {};
  int indexCounter = 0; // 控制 index 递增
  late final List<Edge> edges = [...widget.edges ?? []]; // 存储所有的连线

  bool isDragging = false;

  Offset canvasPosition = Offset(-2000, -2000);

  Offset componentBaseOffset = Offset(2000, 2000);

  double _scale = 1.0;
  double minScale = 0.5;
  double maxScale = 3.0;
   SystemMouseCursor _cursor = SystemMouseCursors.allScroll;

  @override
  void initState() {

    widget.manager.put = put;

    widget.manager.move = move;
    widget.manager.jump = jump;

    // 新增的两个方法
    widget.manager.raiseOneLayer = raiseOneLayer;
    widget.manager.lowerOneLayer = lowerOneLayer;

    widget.manager.connectPoints = connectPoints;

    if (widget.children != null) {
      for (var child in widget.children!) {
        add(child);
      }
    }

    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          setState(() {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localFocalPoint = box.globalToLocal(pointerSignal.position);
            final zoomFactor = 0.1;
            double newScale = _scale;

            if (pointerSignal.scrollDelta.dy < 0) {
              newScale = _scale * (1 + zoomFactor);
            } else {
              newScale = _scale * (1 - zoomFactor);
            }

            newScale = newScale.clamp(minScale, maxScale);

            final scaleChange = newScale / _scale;
            canvasPosition = localFocalPoint - (localFocalPoint - canvasPosition) * scaleChange;
            _scale = newScale;
          });
        }
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        child: Stack(
          children: [
            Positioned(
              top: canvasPosition.dy,
              left: canvasPosition.dx,
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      canvasPosition += (details.delta * _scale);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      isDragging = false;
                    });
                  },
                  child: MouseRegion(
                    cursor: _cursor ,

                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(size: Size(4000, 4000), painter: FileTreeCanvasPainter(edges, Offset(2000, 2000))),

                        ...(components.values.toList()..sort((a, b) => a.index.compareTo(b.index))).map((e) {
                          e.canvasComponent.offset = componentBaseOffset;
                          return e.canvasComponent;
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void add(CanvasComponentContainer canvasComponentContainer) {
    canvasComponentContainer.index = indexCounter++;
    components[canvasComponentContainer.id] = canvasComponentContainer;
  }

  String put(CanvasComponent Function(GlobalKey<CanvasComponentState> key, TreeCanvasManager manager) builder) {
    GlobalKey<CanvasComponentState> globalKey = GlobalKey();
    var canvasComponent = builder(globalKey, widget.manager); // 递增 index

    setState(() {
      components[canvasComponent.id] = CanvasComponentContainer(canvasComponent, globalKey, indexCounter++);
    });
    return canvasComponent.id;
  }

  void move(String id, Offset offset) {
    setState(() {
      components[id]?.key.currentState?.position += offset;
    });
  }

  void jump(String id, Offset position) {
    setState(() {
      components[id]?.key.currentState?.setPosition(position);
    });
  }

  void raiseOneLayer(String id) {
    final container = components[id];
    if (container == null) return;

    // 先按 index 排好序，找出当前组件位置
    List<CanvasComponentContainer> sorted = components.values.toList()..sort((a, b) => a.index.compareTo(b.index));
    int currentPos = sorted.indexOf(container);

    // 如果已经在最顶层，就无法再升高一层
    if (currentPos >= sorted.length - 1) return;

    // 与上面一层（pos+1）交换 index
    final upper = sorted[currentPos + 1];
    final tempIndex = container.index;
    container.index = upper.index;
    upper.index = tempIndex;

    setState(() {});
  }

  /// 降低一层：与下方（index 更小）的那个组件交换 index
  void lowerOneLayer(String id) {
    final container = components[id];
    if (container == null) return;

    // 先按 index 排好序，找出当前组件位置
    List<CanvasComponentContainer> sorted = components.values.toList()..sort((a, b) => a.index.compareTo(b.index));
    int currentPos = sorted.indexOf(container);

    // 如果已经在最底层，就无法再降低一层
    if (currentPos <= 0) return;

    // 与下面一层（pos-1）交换 index
    final lower = sorted[currentPos - 1];
    final tempIndex = container.index;
    container.index = lower.index;
    lower.index = tempIndex;

    setState(() {});
  }

  void connectPoints(String startId, String endId) {
    final startComponent = components[startId];
    final endComponent = components[endId];

    if (startComponent == null || endComponent == null) return;

    setState(() {
      edges.add(Edge(startComponent.key, endComponent.key));
    });
  }
}

class CanvasComponentContainer {
  final String id;
  final CanvasComponent canvasComponent;
  late final GlobalKey<CanvasComponentState> key;
  late int index; // 组件的层级 index

  CanvasComponentContainer(this.canvasComponent, this.key, this.index) : id = canvasComponent.id;

  CanvasComponentContainer.component(this.canvasComponent)
    : id = canvasComponent.id,
      key = canvasComponent.canvasComponentKey;
}

```

<a id="view-component-tree-CanvasComponent-dart"></a>
### CanvasComponent.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:vertree/view/component/SizeListenerWidget.dart';
import 'package:vertree/view/component/tree/CanvasManager.dart';

abstract class CanvasComponent extends StatefulWidget {
  final GlobalKey<CanvasComponentState> canvasComponentKey;
  final String id;
  final TreeCanvasManager treeCanvasManager;
  Offset position;
  late Offset offset = Offset.zero;

  // 修正 constructor，确保传递的 key 被赋值给 canvasComponentKey
  CanvasComponent({
    required super.key, // 父类的 key
    required this.treeCanvasManager,
    this.position = Offset.zero,
  }) : // 备份传递的 key 到 canvasComponentKey
       canvasComponentKey = key as GlobalKey<CanvasComponentState>,
       id = const Uuid().v4();
}

abstract class CanvasComponentState<T extends CanvasComponent> extends State<T> with SingleTickerProviderStateMixin {
  late Offset position = widget.position;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  SystemMouseCursor _cursor = SystemMouseCursors.click;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animation = Tween<Offset>(
      begin: widget.position,
      end: widget.position,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animation.addListener(() {
      setPosition(_animation.value);
    });
  }

  String getId() {
    return widget.id;
  }

  Offset getCenterPosition() {
    return position + Offset(size.width / 2, size.height / 2);
  }

  bool isDragging = false;
  double scale = 1.0; // 初始缩放比例
  bool isHovered = false;

  void setPosition(Offset position) {
    setState(() {
      this.position = position;
    });
  }

  Size size = Size.zero;

  @override
  Widget build(BuildContext context) {
    return SizeListenerWidget(
      onSizeChange: (Size size) {
        this.size = size;
      },
      child: Positioned(
        left: position.dx + widget.offset.dx,
        top: position.dy + widget.offset.dy,
        child: MouseRegion(
          cursor: _cursor ,
          onEnter: (_) {
            if (!isDragging) {
              setState(() {
                scale = 1.02; // 鼠标悬停放大 1.1 倍
              });
              isHovered = true;
            }
          },
          onExit: (_) {
            if (!isDragging) {
              setState(() {
                scale = 1.0; // 鼠标移出恢复正常大小
              });
              isHovered = false;
            }
          },
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                isDragging = true;
                scale = 1.1; // 拖动时放大 1.2 倍
                _cursor = SystemMouseCursors.allScroll;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                position += details.delta;
                _cursor = SystemMouseCursors.allScroll;

              });
            },
            onPanEnd: (_) {
              setState(() {
                isDragging = false;
                if (isHovered) {
                  scale = 1.02;
                } else {
                  scale = 1.0; // 拖动结束恢复正常大小
                }
                _cursor = SystemMouseCursors.grab;

              });
            },
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 200), // 200ms 动画
              curve: Curves.easeInOut,
              child: buildComponent(),
            ),
          ),
        ),
      ),
    );
  }

  String put(
    CanvasComponent Function(GlobalKey<CanvasComponentState> key, TreeCanvasManager treeCanvasManager) builder,
    Offset position,
  ) {
    return widget.treeCanvasManager.put(builder);
  }

  void animateMove(Offset targetOffset) {
    _animation = Tween<Offset>(
      begin: position,
      end: position + targetOffset,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward(from: 0.0); // 重新启动动画
  }

  void move(Offset offset) {
    setPosition(position += offset);
  }

  void raiseLayer() {
    setState(() {
      widget.treeCanvasManager.raiseOneLayer(widget.id);
    });
  }

  void lowerLayer() {
    setState(() {
      widget.treeCanvasManager.lowerOneLayer(widget.id);
    });
  }

  Widget buildComponent();

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

```

<a id="view-component-tree-CanvasManager-dart"></a>
### CanvasManager.dart
```dart
import 'package:flutter/material.dart';

import 'CanvasComponent.dart';

class TreeCanvasManager {
  late String Function(
    CanvasComponent Function(
      GlobalKey<CanvasComponentState> key,
      TreeCanvasManager treeCanvasManager,
    )
    builder
  )
  put;
  late void Function(String id, Offset offset) move;

  late void Function(String id, Offset position) jump;


  // 新增的
  late void Function(String) raiseOneLayer;
  late void Function(String) lowerOneLayer;

  late void Function(String startId, String endId) connectPoints;
}

```

<a id="view-component-tree-EdgePainter-dart"></a>
### EdgePainter.dart
```dart
import 'package:flutter/material.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';
import 'package:vertree/view/component/tree/Point.dart';

class Edge {
  final GlobalKey<CanvasComponentState> startPoint;
  final GlobalKey<CanvasComponentState> endPoint;

  Edge(this.startPoint, this.endPoint);
}

class FileTreeCanvasPainter extends CustomPainter {
  final List<Edge> edges;
  final Offset baseOffset;

  FileTreeCanvasPainter(this.edges, this.baseOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final controlPointPaint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4.0
          ..style = PaintingStyle.fill;

    for (var edge in edges) {
      var start = edge.startPoint.currentState?.getCenterPosition() ?? Offset.zero;
      var end = edge.endPoint.currentState?.getCenterPosition() ?? Offset.zero;
      // Ensure start is always the leftmost and end is always the rightmost

      // 计算控制点，使曲线形成“圆角直角”效果
      Offset controlPoint;

      if (start.dx < end.dx) {
        controlPoint = Offset(start.dx, end.dy + (end.dy - end.dx) * 0.02);
      } else {
        controlPoint = Offset(end.dx, start.dy + (start.dy - start.dx) * 0.02);
      }

      final path =
          Path()
            ..moveTo(start.dx + baseOffset.dx, start.dy + baseOffset.dy)
            ..quadraticBezierTo(
              controlPoint.dx + baseOffset.dx,
              controlPoint.dy + baseOffset.dy,
              end.dx + baseOffset.dx,
              end.dy + baseOffset.dy,
            );

      canvas.drawPath(path, paint);

      // 绘制控制点，方便调试
      canvas.drawCircle(controlPoint + baseOffset, 2, controlPointPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

```

<a id="view-component-tree-FileLeaf-dart"></a>
### FileLeaf.dart
```dart
import 'package:flutter/material.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';

class FileLeaf extends CanvasComponent {
  FileLeaf(this.fileNode, {required this.sprout, super.key, required super.position, required super.treeCanvasManager});

  final FileNode fileNode;

  final void Function(FileNode parentNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) sprout;

  @override
  _FileNodeState createState() => _FileNodeState();
}

class _FileNodeState extends CanvasComponentState<FileLeaf> {
  FileNode get fileNode => widget.fileNode;

  String? childId;
  List<String> topBranchIds = [];
  List<String> bottomBranchIds = [];

  @override
  Widget buildComponent() {
    return GestureDetector(
      onTap: (){
        FileUtils.openFile(fileNode.mate.fullPath);
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 18, right: 10),
        child: Row(
          children: [
            Text(
              "${fileNode.mate.name} ${fileNode.version.toString()}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),

            IconButton(
              iconSize: 20,
              icon: Center(child: Icon(Icons.save, color: Colors.white, size: 14)),
              onPressed: () {
                widget.sprout(fileNode, position, widget.canvasComponentKey);
              },
            ),
          ],
        ),
      ),
    );
  }
}

```

<a id="view-component-tree-FileTree-dart"></a>
### FileTree.dart
```dart
import 'package:flutter/material.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';
import 'package:vertree/view/component/tree/EdgePainter.dart';
import 'package:vertree/view/component/tree/Canvas.dart';
import 'package:vertree/view/component/tree/CanvasManager.dart';
import 'package:vertree/view/component/tree/FileLeaf.dart';

class FileTree extends StatefulWidget {
  const FileTree({super.key, required this.rootNode, required this.height, required this.width});

  final double height;
  final double width;
  final FileNode rootNode;

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  final double _Xmobility = 200;
  final double _Ymobility = 60;

  FileNode get rootNode => widget.rootNode;
  final TreeCanvasManager treeCanvasManager = TreeCanvasManager();

  List<CanvasComponentContainer> canvasComponentContainers = [];
  List<Edge> edges = [];
  late final GlobalKey<CanvasComponentState> rootKey;
  late var initPosition = Offset(_Xmobility, widget.height / 2 - _Ymobility / 2);

  @override
  void initState() {
    rootKey = addChild(rootNode, initPosition);
    _buildTree(rootNode, initPosition, rootKey);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {


    return TreeCanvas(
      key: ValueKey(canvasComponentContainers.hashCode),
      height: widget.height,
      width: widget.width,
      manager: treeCanvasManager,
      children: canvasComponentContainers,
      edges: edges,
    );
  }

  void sprout(FileNode parentNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) async {
    Result<FileNode, String> sproutResult;


    if (parentNode.child == null) {
      sproutResult = await parentNode.backup();
      if (sproutResult.isErr) {
        return;
      }

      Offset childPosition = parentPosition + Offset(_Xmobility, 0);

      // 获取新生成的节点
      FileNode shoot = sproutResult.unwrap();
      setState(() {
        addChild(shoot, childPosition, parentKey: parentKey);
        canvasComponentContainers = List.from(canvasComponentContainers); // 强制 Flutter 识别变化
      });
    } else {
      sproutResult = await parentNode.branch();
      if (sproutResult.isErr) {
        return;
      }
      // 获取新生成的节点
      FileNode shoot = sproutResult.unwrap();

      bool top = shoot.mate.version.segments.last.branch % 2 == 0;
      double height = shoot.getParentRelativeHeight().toDouble();

      Offset branchPosition = parentPosition + Offset(_Xmobility, (top ? -_Ymobility : _Ymobility) * height);
      // 作为分支
      setState(() {
        addChild(shoot, branchPosition, parentKey: parentKey);
        canvasComponentContainers = List.from(canvasComponentContainers); // 强制 Flutter 识别变化
      });
    }
  }

  void _buildTree(FileNode fileNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) {
    // 处理子节点
    if (fileNode.child != null) {
      Offset childPosition = parentPosition + Offset(_Xmobility, 0);

      GlobalKey<CanvasComponentState> childKey = addChild(fileNode.child!, childPosition, parentKey: parentKey);
      _buildTree(fileNode.child!, parentPosition + Offset(_Xmobility, 0), childKey);
    }

    // 处理分支节点
    for (FileNode branch in fileNode.branches) {
      bool top = branch.mate.version.segments.last.branch % 2 == 0;

      double height = branch.getParentRelativeHeight().toDouble();

      Offset branchPosition = parentPosition + Offset(_Xmobility, (top ? -_Ymobility : _Ymobility) * height);
      GlobalKey<CanvasComponentState> childKey = addChild(branch, branchPosition, parentKey: parentKey);
      _buildTree(branch, branchPosition, childKey);
    }
  }

  /// **绘制子节点并连接**
  GlobalKey<CanvasComponentState> addChild(
    FileNode child,
    Offset childPosition, {
    GlobalKey<CanvasComponentState>? parentKey,
  }) {
    GlobalKey<CanvasComponentState> childKey = GlobalKey<CanvasComponentState>();

    canvasComponentContainers.add(
      CanvasComponentContainer.component(
        FileLeaf(child, sprout: sprout, key: childKey, treeCanvasManager: treeCanvasManager, position: childPosition),
      ),
    );

    if (parentKey != null) {
      edges.add(Edge(parentKey, childKey));
    }

    return childKey;
  }
}

```

<a id="view-component-tree-Point-dart"></a>
### Point.dart
```dart
import 'package:flutter/material.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';

class Point extends CanvasComponent {
  Point({super.key, required super.treeCanvasManager});

  @override
  PointState createState() => PointState();
}

class PointState extends CanvasComponentState<Point> {
  @override
  Widget buildComponent() {
    return Container(
      height: 6,
      width: 6,
      decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(10)),
    );
  }
}

```

<a id="view-page-BrandPage-dart"></a>
### BrandPage.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/page/MonitPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:window_manager/window_manager.dart';

class BrandPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20, // 4:3 aspect ratio (400x300)
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
              ),
            ),
            SizedBox(width: 8),
            Text("Vertree"),
          ],
        ),
        showMaximize: false,
        goHome: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 240,
                height: 180, // 4:3 aspect ratio (400x300)
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 16),
              Text("Vertree维树", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                "vertree维树，树状文件版本管理🌲，让每一次迭代都有备无患！",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: "监控页",
                    onPressed: () async {
                      go(MonitPage());
                    },
                    icon: Icon(Icons.monitor_heart_rounded),
                  ),
                  IconButton(
                    tooltip: "设置页",
                    onPressed: () async {
                      go(SettingPage());
                    },
                    icon: Icon(Icons.settings_rounded),
                  ),
                  IconButton(
                    tooltip: "完全退出维树",
                    onPressed: () async {
                      exit(0);
                    },
                    icon: Icon(Icons.exit_to_app_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

<a id="view-page-MonitPage-dart"></a>
### MonitPage.dart
```dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/MonitTaskCard.dart';

class MonitPage extends StatefulWidget {
  const MonitPage({super.key});

  @override
  State<MonitPage> createState() => _MonitPageState();
}

class _MonitPageState extends State<MonitPage> {
  /// 从 MonitService 中拿到监控任务列表
  List<FileMonitTask> monitTasks = [];

  @override
  void initState() {
    monitTasks.addAll(monitService.monitFileTasks);
    super.initState();
    // 初始化时，先确保 monitService 初始化完成（如果在 main.dart 里已确保，则无需 await）
  }

  /// 切换监控开关
  Future<void> _toggleTask(FileMonitTask task) async {
    // 调用服务进行启动/暂停
    await monitService.toggleFileMonitTaskStatus(task);
    setState(() {});
  }

  /// 选择文件并添加监控任务
  Future<void> _addNewTask() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // 允许选择任何文件
    );

    if (result != null && result.files.single.path != null) {
      String selectedFilePath = result.files.single.path!;

      final taskResult = await monitService.addFileMonitTask(selectedFilePath);
      taskResult.when(
        ok: (task) {
          setState(() {
            monitTasks.add(task);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("成功添加监控任务: ${task.filePath}")));
        },
        err: (error, msg) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("添加失败: $msg")));
        },
      );
    } else {
      // 用户取消了选择
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("未选择文件")));
    }
  }

  /// 演示移除某个任务
  Future<void> _removeTask(FileMonitTask task) async {
    await monitService.removeFileMonitTask(task.filePath);
    setState(() {
      monitTasks.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Row(
          children: const [Icon(Icons.monitor_heart_rounded, size: 20), SizedBox(width: 8), Text("Vertree 监控")],
        ),
        showMaximize: false,
      ),
      body:
          monitTasks.isEmpty
              ? const Center(child: Text("暂无监控任务"))
              : ListView.builder(
                itemCount: monitTasks.length,
                itemBuilder: (context, index) {
                  final task = monitTasks[index];
                  return Dismissible(
                    key: ValueKey(task.filePath),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) => _removeTask(task),
                    child: MonitTaskCard(
                      task: task,
                      onSwitchChanged: (value) async {
                        // 直接调用 toggle，让任务状态翻转即可
                        await _toggleTask(task);
                        // Flutter 的 switch 里可以由 toggleFileMonitTaskStatus 来负责更新状态
                        // 并 setState 刷新UI
                      },
                      onOpenFolder: () => FileUtils.openFolder(task.backupDirPath),
                    ),
                  );
                },
              ),
      // 右下角添加任务示例按钮
      floatingActionButton: FloatingActionButton(onPressed: _addNewTask, child: const Icon(Icons.add)),
    );
  }
}

```

<a id="view-page-SettingPage-dart"></a>
### SettingPage.dart
```dart
import 'package:flutter/material.dart';
import 'package:vertree/VerTreeRegistryService.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/Loading.dart';
import 'package:window_manager/window_manager.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late bool backupFile = VerTreeRegistryService.checkBackupKeyExists();
  late bool monitorFile = VerTreeRegistryService.checkMonitorKeyExists();
  late bool viewTreeFile = VerTreeRegistryService.checkViewTreeKeyExists(); // 检查是否存在

  bool autoStart = false;
  bool isLoading = false;

  /// 更新 `backupFile` 状态
  Future<void> _toggleBackupFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeBackupContextMenu();
      await showWindowsNotification("Vertree", "已添加 '备份当前文件版本' 到右键菜单");
    } else {
      success = VerTreeRegistryService.removeVerTreeBackupContextMenu();
      await showWindowsNotification("Vertree", "已从右键菜单移除 '备份当前文件版本' 功能按钮");
    }
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          backupFile = value;
        }
        isLoading = false;
      });
    });
  }

  /// 更新 `monitorFile` 状态
  Future<void> _toggleMonitorFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeMonitorContextMenu();
      await showWindowsNotification("Vertree", "已添加 '监控该文件' 到右键菜单");
    } else {
      success = VerTreeRegistryService.removeVerTreeMonitorContextMenu();
      await showWindowsNotification("Vertree", "已从右键菜单移除 '监控该文件' 功能按钮");
    }
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          monitorFile = value;
        }
        isLoading = false;
      });
    });
  }

  Future<void> _toggleViewTreeFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeViewContextMenu();
      await showWindowsNotification("Vertree", "已添加 '浏览文件版本树' 到右键菜单");
    } else {
      success = VerTreeRegistryService.removeVerTreeViewContextMenu();
      await showWindowsNotification("Vertree", "已从右键菜单移除 '浏览文件版本树' 功能按钮");
    }

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          viewTreeFile = value;
        }
        isLoading = false;
      });
    });
  }

  /// 更新 `autoStart` 状态
  void _toggleAutoStart(bool? value) {
    setState(() {
      autoStart = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertree维树',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)),
      home: LoadingWidget(
        isLoading: isLoading,
        child: Scaffold(
          appBar: VAppBar(
            title: Row(children: [Icon(Icons.settings_rounded, size: 20), SizedBox(width: 8), Text("Vertree 设置")]),
            showMaximize: false,
          ),
          body: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 10),
                      Icon(Icons.settings, size: 24),
                      SizedBox(width: 8),
                      Text("设置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  CheckboxListTile(title: Text("将“备份当前文件版本”增加到右键菜单"), value: backupFile, onChanged: _toggleBackupFile),
                  CheckboxListTile(title: Text("将“监控该文件”增加到右键菜单"), value: monitorFile, onChanged: _toggleMonitorFile),
                  CheckboxListTile(
                    title: Text("将“浏览文件版本树”增加到右键菜单"),
                    value: viewTreeFile,
                    onChanged: _toggleViewTreeFile,
                  ),
                  CheckboxListTile(title: Text("开机自启Vertree（推荐）"), value: autoStart, onChanged: _toggleAutoStart),
                  const SizedBox(height: 16),

                  // 新增按钮：选择文件并指定打开方式
                  ListTile(
                    leading: const Icon(Icons.open_in_new,size: 18,),
                    title: const Text("打开Config.json"),
                    onTap: (){

                      print("${configer.configFilePath}");

                      FileUtils.openFile(configer.configFilePath);

                    },
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

```

<a id="view-page-VersionTreePage-dart"></a>
### VersionTreePage.dart
```dart
import 'package:flutter/material.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/TreeBuilder.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/tree/FileTree.dart';

class FileTreePage extends StatefulWidget {
  const FileTreePage({super.key, required this.path});

  final String path;

  @override
  State<FileTreePage> createState() => _FileTreePageState();
}

class _FileTreePageState extends State<FileTreePage> {
  late String path = widget.path;
  FileNode? rootNode;

  @override
  void initState() {
    super.initState();
    buildTree(path).then((fileNodeResult) {
      setState(() {
        rootNode = fileNodeResult.unwrap();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertree维树',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)),
      home: Scaffold(
        appBar: VAppBar(
          title: Row(
            children: [
              Container(
                width: 20,
                height: 20, // 4:3 aspect ratio (400x300)
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
                ),
              ),
              SizedBox(width: 8),
              Text(
                "${rootNode?.mate.name ?? ""}.${rootNode?.mate.extension ?? ""}文本版本树",
              ),
            ],
          ),
          showMaximize: false,
        ),
        body:
            rootNode != null
                ? FileTree(
                  rootNode: rootNode!,
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                )
                : Container(),
      ),
    );
  }
}

```
