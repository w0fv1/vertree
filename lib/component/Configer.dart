import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vertree/main.dart';

class Configer {
  static const String _configFileName = "config.json";
  late String configFilePath;

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
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          _config = decoded;
        } else if (decoded is Map) {
          _config = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        } else {
          // Corrupted or unexpected schema; reset to empty.
          _config = {};
          await _saveConfig();
        }
      } catch (e) {
        logger.error("Error reading config file: $e");
        _config = {};
        await _saveConfig();
      }
    } else {
      // 如果不存在配置文件，则创建一个空配置
      await _saveConfig();
    }
  }

  T _setAndReturnDefault<T>(String key, T defaultValue) {
    set<T>(key, defaultValue);
    return defaultValue;
  }

  bool? _tryParseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'y') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'n') return false;
    }
    return null;
  }

  int? _tryParseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  double? _tryParseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// 通用的 get 方法：根据 key 获取配置
  T get<T>(String key, T defaultValue) {
    if (!_config.containsKey(key)) {
      return _setAndReturnDefault<T>(key, defaultValue);
    }

    final value = _config[key];

    if (value is T) {
      return value;
    }

    // Best-effort backward compatibility when schema/types change across versions.
    try {
      if (defaultValue is bool) {
        final parsed = _tryParseBool(value);
        if (parsed != null) return _setAndReturnDefault<T>(key, parsed as T);
      } else if (defaultValue is int) {
        final parsed = _tryParseInt(value);
        if (parsed != null) return _setAndReturnDefault<T>(key, parsed as T);
      } else if (defaultValue is double) {
        final parsed = _tryParseDouble(value);
        if (parsed != null) return _setAndReturnDefault<T>(key, parsed as T);
      } else if (defaultValue is String) {
        final str = value?.toString();
        if (str != null) return _setAndReturnDefault<T>(key, str as T);
      }
    } catch (e) {
      logger.error("Config key '$key' type mismatch: $e");
    }

    return _setAndReturnDefault<T>(key, defaultValue);
  }


  /// 通用的 set 方法：设置配置并立即写入文件
  T set<T>(String key, T value) {
    _config[key] = value;
    _saveConfig();
    return get(key, value);
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
