import 'package:flutter/material.dart';

/// 默认品牌 Logo 单一源文件。
const String kLogoDefault = 'assets/img/logo/logo.png';

const List<double> _invertColorMatrix = <double>[
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0, //
];

/// 根据主题自动选择是否对 Logo 做颜色反相（深色模式下反相）。
Widget themedLogoImage({
  required BuildContext context,
  double width = 20,
  double height = 20,
  BoxFit fit = BoxFit.contain,
}) {
  final brightness = Theme.of(context).brightness;
  final image = Image.asset(
    kLogoDefault,
    width: width,
    height: height,
    fit: fit,
  );

  if (brightness == Brightness.dark) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_invertColorMatrix),
      child: image,
    );
  }
  return image;
}

