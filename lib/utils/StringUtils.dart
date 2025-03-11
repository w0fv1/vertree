class StringUtils {
  /// 截取字符串，如果超出最大长度，则加指定后缀，默认".."
  static String truncate(String? input, int maxLength, [String suffix = ".."]) {
    if (input == null) {
      return "";
    }

    if (input.length <= maxLength) {
      return input;
    }
    return "${input.substring(0, maxLength)}$suffix";
  }
}
