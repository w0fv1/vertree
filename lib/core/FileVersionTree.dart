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
