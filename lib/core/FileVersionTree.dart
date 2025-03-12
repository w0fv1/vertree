import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';

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
      List<String> bv = part.split('.');
      if (bv.length != 2) {
       logger.error("版本段格式错误，每段必须是 X.Y 形式: $part");
       bv = ["0","0"];
      }
      final branch = int.parse(bv[0]);
      final ver = int.parse(bv[1]);
      segs.add(Segment(branch, ver));
    }
    return segs;
  }

  /// 为了方便，这里提供一个从 Segment 列表构造的方法
  factory FileVersion.fromSegments(List<Segment> segs) {
    return FileVersion._(List<Segment>.from(segs));
  }

  /// 生成下一个版本（同分支下版本号+1）
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

  /// 创建一个新的分支，在末尾增加 (branch, 0)
  FileVersion branchVersion(int branchIndex) {
    final newSegs = List<Segment>.from(segments);
    newSegs.add(Segment(branchIndex, 0));
    return FileVersion.fromSegments(newSegs);
  }

  @override
  String toString() {
    return segments.map((seg) => '${seg.branch}.${seg.version}').join('-');
  }

  @override
  int compareTo(FileVersion other) {
    final minLen = segments.length < other.segments.length ? segments.length : other.segments.length;
    for (int i = 0; i < minLen; i++) {
      final diffBranch = segments[i].branch - other.segments[i].branch;
      if (diffBranch != 0) return diffBranch;
      final diffVer = segments[i].version - other.segments[i].version;
      if (diffVer != 0) return diffVer;
    }
    return segments.length - other.segments.length;
  }

  /// 判断是否与 [other] 在同一个分支
  bool isSameBranch(FileVersion other) {
    if (segments.length != other.segments.length) {
      return false;
    }
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].branch != other.segments[i].branch) {
        return false;
      }
    }
    return true;
  }

  /// 判断 [other] 是否为 [this] 的“第一个子版本”
  bool isChild(FileVersion other) {
    if (!isSameBranch(other)) return false;
    return segments.last.version + 1 == other.segments.last.version;
  }

  /// 判断 [other] 是否为 [this] 的“直接分支”
  bool isDirectBranch(FileVersion other) {
    if (other.segments.length != segments.length + 1) {
      return false;
    }
    final n = segments.length;
    for (int i = 0; i < n; i++) {
      if (segments[i] != other.segments[i]) {
        return false;
      }
    }
    final lastOther = other.segments[other.segments.length - 1];
    if (lastOther.version != 0) {
      return false;
    }
    return true;
  }

  /// 判断 [other] 是否为 [this] 的“间接分支”
  bool isIndirectBranch(FileVersion other) {
    if (other.segments.length <= segments.length) {
      return false;
    }
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] != other.segments[i]) {
        return false;
      }
    }
    return true;
  }
}

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

/// 文件元数据信息，增加了 label 属性，用于保存备注信息
class FileMeta {
  /// 文件全名（含扩展名），例如 "example#labelContent.0.0.txt"
  String fullName = "";

  /// 文件主名称，不含版本号和备注，例如 "example"
  String name = "";

  /// 可选的备注信息，例如 "labelContent"
  String? label;

  /// 文件版本，例如 FileVersion("0.0")
  FileVersion version = FileVersion("0.0");

  /// 文件扩展名，不含点号，例如 "txt"
  String extension = "";

  /// 文件完整路径（重命名时会更新）
  String fullPath;

  /// 对应的 File 对象（重命名时会更新）
  File originalFile;

  /// 文件大小，单位字节
  int fileSize = 0;

  /// 文件创建时间
  DateTime creationTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// 文件上次修改时间
  DateTime lastModifiedTime = DateTime.fromMillisecondsSinceEpoch(0);

  FileMeta(this.fullPath) : originalFile = File(fullPath) {
    // 1) 获取不带路径的完整文件名
    fullName = path.basename(fullPath);

    // 2) 分离扩展名
    extension = path.extension(fullPath).replaceFirst('.', '');

    // 3) 去除扩展名后的文件名
    final fileNameWithoutExt = path.basenameWithoutExtension(fullPath);
    // 文件名格式: <name>[#<label>].<version>
    final dotIndex = fileNameWithoutExt.indexOf('.');
    if (dotIndex == -1) {
      // 没有版本号，默认使用 0.0
      final hashIndex = fileNameWithoutExt.indexOf('#');
      if (hashIndex == -1) {
        name = fileNameWithoutExt;
        label = null;
      } else {
        name = fileNameWithoutExt.substring(0, hashIndex);
        label = fileNameWithoutExt.substring(hashIndex + 1);
      }
      version = FileVersion("0.0");
    } else {
      // 有版本号，前面的部分可能包含 label（使用 '#' 分隔）
      final basePart = fileNameWithoutExt.substring(0, dotIndex);
      final versionStr = fileNameWithoutExt.substring(dotIndex + 1);
      final hashIndex = basePart.indexOf('#');
      if (hashIndex == -1) {
        name = basePart;
        label = null;
      } else {
        name = basePart.substring(0, hashIndex);
        label = basePart.substring(hashIndex + 1);
      }
      version = versionStr.isEmpty ? FileVersion("0.0") : FileVersion(versionStr);
    }

    // 4) 若文件存在，则获取文件大小及时间信息
    if (originalFile.existsSync()) {
      final fileStat = originalFile.statSync();
      fileSize = fileStat.size;
      creationTime = fileStat.changed;
      lastModifiedTime = fileStat.modified;
    }
  }

  /// 设置备注信息，同时更新 fullName（格式为: <name>[#<label>].<version>.<extension>）
  void setLabel(String? newLabel) {
    label = newLabel;
    fullName =
    "$name${(newLabel != null && newLabel.isNotEmpty) ? "#$newLabel" : ""}.${version.toString()}.$extension";
  }

  /// 重命名文件，将当前文件按照新的备注更新文件名，并更新内部元数据
  /// 注意：该操作会调用文件系统的重命名方法，可能会影响依赖于旧路径的其他模块
  Future<void> renameFile(String? newLabel) async {
    // 1. 更新 label 以及 fullName（不改变 name、version、extension）
    setLabel(newLabel);

    // 2. 构造新文件完整路径
    final dir = path.dirname(fullPath);
    final newFullName = fullName;
    final newFullPath = path.join(dir, newFullName);

    // 3. 进行文件系统的重命名操作
    final newFile = await originalFile.rename(newFullPath);

    // 4. 更新内部字段
    fullPath = newFullPath;
    fullName = newFullName;
    originalFile = newFile;

    // 5. 更新文件大小及时间（如果需要）
    if (newFile.existsSync()) {
      final fileStat = newFile.statSync();
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
        'label: ${label ?? ""}, '
        'version: $version, '
        'extension: $extension, '
        'fullPath: $fullPath, '
        'fileSize: $fileSize bytes, '
        'creationTime: $creationTime, '
        'lastModifiedTime: $lastModifiedTime'
        ')';
  }
}


void main(List<String> args){
  FileMeta fileMeta = FileMeta("D:\\project\\vertree\\testree\\0.0.docx");
  print(fileMeta);
}

/// 文件节点，表示文件的一个版本，并可能有子版本（child）和分支（branches）
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

  // 分别存储偶数版本（topBranches）和奇数版本（bottomBranches）的分支
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

  List<FileNode> _getCloserParentBranches() {
    List<FileNode> branchesList = parent.topBranches.contains(this)
        ? parent.topBranches
        : parent.bottomBranches;
    if (!parent.topBranches.contains(this) && !parent.bottomBranches.contains(this)) {
      return [];
    }
    int index = branchesList.indexOf(this);
    if (branchesList.isEmpty) {
      return [];
    }
    return branchesList.sublist(0, index);
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
      if (branch.mate.version.segments.last.branch % 2 == 0) {
        topBranches.add(branch);
      } else {
        bottomBranches.add(branch);
      }
    }
  }

  Future<Result<FileNode, String>> safeBackup([String? label]) async {
    try {
      final newVersion = mate.version.nextVersion();
      final newFileName =
          '${mate.name}${label != null ? "#$label" : ""}.${newVersion.toString()}.${mate.extension}';
      final dirPath = path.dirname(mate.fullPath);
      final newFilePath = path.join(dirPath, newFileName);
      final newFile = File(newFilePath);
      if (!newFile.existsSync()) {
        return await backup(label);
      } else {
        return await branch(label);
      }
    } catch (e) {
      return Result.eMsg("safeBackup 失败: ${e.toString()}");
    }
  }

  Future<Result<FileNode, String>> backup([String? label]) async {
    if (child != null) {
      return Result.eMsg("当前版本已有长子，不允许备份");
    }
    try {
      final newVersion = mate.version.nextVersion();
      final newFileName =
          '${mate.name}${label != null ? "#$label" : ""}.${newVersion.toString()}.${mate.extension}';
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

  Future<Result<FileNode, String>> branch([String? label]) async {
    try {
      final branchedVersion = mate.version.branchVersion(branchIndex + 1);
      final newFileName =
          '${mate.name}${label != null ? "#$label" : ""}.${branchedVersion.toString()}.${mate.extension}';
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

  bool push(FileNode node) {
    if (mate.version.compareTo(node.mate.version) == 0) {
      return false;
    }
    if (mate.version.isChild(node.mate.version)) {
      addChild(node);
      return true;
    }
    if (mate.version.isDirectBranch(node.mate.version)) {
      addBranch(node);
      return true;
    }
    if (child != null) {
      if (child!.push(node)) {
        return true;
      }
    }
    for (var branch in branches) {
      if (branch.push(node)) {
        return true;
      }
    }
    return false;
  }

  String toTreeString({int level = 0, String label = 'Root'}) {
    final indent = ' ' * (level * 4);
    final buffer = StringBuffer();
    buffer.writeln('$indent$label[${mate.fullName} (version: ${mate.version})]');
    if (child != null) {
      buffer.write(child!.toTreeString(level: level, label: 'Child'));
    }
    for (var branch in branches) {
      buffer.write(branch.toTreeString(level: level + 1, label: 'Branch'));
    }
    return buffer.toString();
  }


  @override
  String toString() {
    return 'FileNode(file: $mate, child: [$child], branches: [$branches])';
  }
}
