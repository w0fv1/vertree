import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vertree/main.dart';

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
        logger.error("Error reading config file: $e");
        await _saveConfig();
      }
    } else {
      // 如果不存在配置文件，则创建一个空配置
      await _saveConfig();
    }
  }

  /// 通用的 get 方法：根据 key 获取配置
  T get<T>(String key, T defaultValue) {
    if (!_config.containsKey(key)) {
      set<T>(key, defaultValue); // Save the missing key with its default value
    }
    return _config[key] as T;
  }


  /// 通用的 set 方法：设置配置并立即写入文件
  T set<T>(String key, T value) {
    _config[key] = value;
    _saveConfig();
    return get(key,value);
  }


  Future<void> _saveConfig() async {
    final dir = await getApplicationSupportDirectory();
    final configFile = File('${dir.path}/$_configFileName');

    final encoder = JsonEncoder.withIndent("  "); // Pretty print with indentation
    final formattedJson = encoder.convert(_config);

    await configFile.writeAsString(formattedJson);
  }

  /// 将配置转换为 JSON（可根据需要使用）
  Map<String, dynamic> toJson() => _config;
}
