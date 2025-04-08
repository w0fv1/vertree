import 'dart:convert'; // 用于 JSON 解码和编码
import 'package:http/http.dart' as http; // 用于发起 HTTP 请求

/// 应用版本检查器类
///
/// 用于从指定的 GitHub Release API 端点获取最新版本信息，
/// 并与当前应用版本进行比较。
class AppVersionInfo {
  /// 当前应用的版本号。
  final String currentVersion;

  /// GitHub Release API 的 URL (通常指向 latest release)。
  /// 例如: "https://api.github.com/repos/user/repo/releases/latest"
  final String releaseApiUrl;

  String? latestHtmlUrl;

  /// 构造函数。
  ///
  /// 需要提供 [currentVersion] (当前应用版本) 和 [releaseApiUrl] (GitHub API 地址)。
  AppVersionInfo({required this.currentVersion, required this.releaseApiUrl});

  /// 比较两个版本号字符串。
  ///
  /// 支持 'vX.Y.Z' 或 'X.Y.Z' 格式。比较时会忽略 'v' 前缀并转换为小写。
  ///
  /// 返回值:
  /// - `1`: 如果 version1 > version2
  /// - `-1`: 如果 version1 < version2
  /// - `0`: 如果 version1 == version2
  static int compareVersions(String version1, String version2) {
    // 清理版本号：去除首尾空格，去除开头的 'v' (不区分大小写)
    String cleanVersion(String v) => v.trim().toLowerCase().startsWith('v') ? v.trim().substring(1) : v.trim();

    String cleanV1 = cleanVersion(version1);
    String cleanV2 = cleanVersion(version2);

    // 按 '.' 分割版本号段
    List<String> parts1 = cleanV1.split('.');
    List<String> parts2 = cleanV2.split('.');

    // 确定比较的长度（取较长者）
    int length = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < length; i++) {
      // 获取对应段的数字，如果段不存在或无法解析为数字，则视为 0
      int num1 = i < parts1.length ? int.tryParse(parts1[i]) ?? 0 : 0;
      int num2 = i < parts2.length ? int.tryParse(parts2[i]) ?? 0 : 0;

      // 比较数字大小
      if (num1 > num2) {
        return 1; // version1 更大
      } else if (num1 < num2) {
        return -1; // version2 更大
      }
      // 如果相等，继续比较下一段
    }

    // 所有段都相等，版本相同
    return 0;
  }

  /// 从 GitHub API 获取最新的发布信息 (内部实现)。
  ///
  /// 返回包含发布信息的 Map，如果请求失败或解析失败则返回 null。
  Future<Map<String, dynamic>?> _fetchLatestReleaseInfo() async {
    try {
      print('正在从 $releaseApiUrl 获取最新版本信息...');
      final response = await http.get(Uri.parse(releaseApiUrl));

      if (response.statusCode == 200) {
        // 请求成功，解析 JSON 数据
        print('成功获取到 API 响应。');
        // print('响应体: ${response.body}'); // Debug: 打印原始响应体
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // 请求失败
        print('获取最新版本信息失败，HTTP 状态码: ${response.statusCode}');
        print('响应体: ${response.body}'); // 打印错误响应体可能有助于诊断
        return null;
      }
    } catch (e, stackTrace) {
      // 捕获网络或其他异常
      print('获取最新版本信息时发生异常: $e');
      print('堆栈跟踪: $stackTrace'); // 打印堆栈信息，便于调试
      return null;
    }
  }

  /// 检查是否存在比当前版本更新的版本。
  ///
  /// 首先从 GitHub API 获取最新发布信息，然后与 [currentVersion] 比较。
  ///
  /// 返回:
  /// - `Future<true>`: 如果检测到更新的版本。
  /// - `Future<false>`: 如果当前版本已是最新，或检查过程中发生错误。
  Future<bool> checkUpdate() async {
    final releaseInfo = await _fetchLatestReleaseInfo();
    if (releaseInfo == null) {
      print("未能获取最新版本信息，无法检查更新。");
      return false; // 获取信息失败
    }

    // 从返回的数据中提取 'tag_name' (即版本号)
    final latestVersionTag = releaseInfo['tag_name'];

    if (latestVersionTag is String && latestVersionTag.isNotEmpty) {
      print('获取到的最新版本标签: $latestVersionTag');
      // 使用静态方法比较版本号
      int comparisonResult = AppVersionInfo.compareVersions(currentVersion, latestVersionTag);

      // comparisonResult < 0 表示 latestVersionTag 更新
      if (comparisonResult < 0) {
        print('发现新版本！($latestVersionTag > $currentVersion)');
        return true;
      } else if (comparisonResult == 0) {
        print('当前版本 ($currentVersion) 已是最新。');
        return false;
      } else {
        // comparisonResult > 0 表示 currentVersion 比 latestVersionTag 还新
        print('当前版本 ($currentVersion) 比 GitHub 最新版本 ($latestVersionTag) 还新？检查 API URL 或版本号规则。');
        return false;
      }
    } else {
      print('未能从 API 响应中找到有效的 "tag_name"。');
      print('API 响应相关部分: ${releaseInfo['tag_name']}'); // 打印 tag_name 值以供调试
      return false; // tag_name 无效
    }
  }

  /// 获取最新发布版本的标签名 (例如 "v1.2.0")。
  ///
  /// 返回:
  /// - `Future<String?>`: 成功时返回最新版本的 `tag_name` 字符串，失败时返回 `null`。
  Future<String?> getLatestVersionTag() async {
    final releaseInfo = await _fetchLatestReleaseInfo();
    if (releaseInfo == null) {
      print("未能获取最新版本信息，无法获取版本标签。");
      return null;
    }

    final latestVersionTag = releaseInfo['tag_name'];

    if (latestVersionTag is String && latestVersionTag.isNotEmpty) {
      return latestVersionTag;
    } else {
      print('未能从 API 响应中找到有效的 "tag_name"。');
      return null;
    }
  }

  /// 获取最新发布版本的 GitHub 页面链接 (html_url)。
  ///
  /// 返回:
  /// - `Future<String?>`: 成功时返回最新版本的 `html_url`，失败时返回 `null`。
  Future<String?> getLatestReleaseUrl() async {
    final releaseInfo = await _fetchLatestReleaseInfo();
    if (releaseInfo == null) {
      print("未能获取最新版本信息，无法获取发布页面 URL。");
      return null; // 获取信息失败
    }

    // 从返回的数据中提取 'html_url'
    final htmlUrl = releaseInfo['html_url'];
    this.latestHtmlUrl = htmlUrl;

    if (htmlUrl is String && htmlUrl.isNotEmpty) {
      return htmlUrl;
    } else {
      print('未能从 API 响应中找到有效的 "html_url"。');
      return null; // html_url 无效
    }
  }
}
