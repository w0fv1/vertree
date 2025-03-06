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
