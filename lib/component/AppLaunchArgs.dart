const String startupLaunchArg = '--startup';

bool containsStartupLaunchArg(Iterable<String> rawArgs) {
  for (final rawArg in rawArgs) {
    if (rawArg.trim().toLowerCase() == startupLaunchArg) {
      return true;
    }
  }
  return false;
}

List<String> stripRuntimeLaunchArgs(Iterable<String> rawArgs) {
  final args = <String>[];
  for (final rawArg in rawArgs) {
    final normalized = rawArg.trim();
    if (normalized.isEmpty) {
      continue;
    }
    if (normalized.toLowerCase() == startupLaunchArg) {
      continue;
    }
    args.add(normalized);
  }
  return args;
}

String buildWindowsLaunchCommand(
  String executablePath, {
  List<String> arguments = const [],
}) {
  final command = StringBuffer('"$executablePath"');
  for (final argument in arguments) {
    if (argument.isEmpty) {
      continue;
    }
    command.write(' ');
    command.write(_quoteWindowsArg(argument));
  }
  return command.toString();
}

String _quoteWindowsArg(String value) {
  final escaped = value.replaceAll('"', r'\"');
  if (escaped.contains(' ') ||
      escaped.contains('\t') ||
      escaped.contains('\n')) {
    return '"$escaped"';
  }
  return escaped;
}
