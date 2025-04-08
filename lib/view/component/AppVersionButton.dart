import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vertree/I18nLang.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/main.dart';

class AppVersionDisplay extends StatefulWidget {
  final String appVersion;
  final String defaultLink;
  final Future<bool> Function() checkNewVersion;
  final Future<String?> Function() getNewVersionDownloadUrl;

  const AppVersionDisplay({
    Key? key,
    required this.appVersion,
    required this.defaultLink,
    required this.checkNewVersion,
    required this.getNewVersionDownloadUrl,
  }) : super(key: key);

  @override
  State<AppVersionDisplay> createState() => _AppVersionDisplayState();
}

class _AppVersionDisplayState extends State<AppVersionDisplay> {
  bool _hasNewVersion = false;
  String? _newVersionDownloadUrl;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final hasNewVersion = await widget.checkNewVersion();
        if (hasNewVersion) {
          widget.getNewVersionDownloadUrl().then((onValue) {
            if (onValue == null || onValue.isEmpty) {
              return;
            }


            setState(() {
              _hasNewVersion = true;
            });
            _newVersionDownloadUrl = onValue;
          });
        }
      } catch (e) {

      }
    });
  }

  Future<void> _openLink() async {
    final url = _hasNewVersion && _newVersionDownloadUrl != null ? _newVersionDownloadUrl! : widget.defaultLink;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // 可以添加一些错误处理逻辑，例如显示一个SnackBar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法打开链接')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _openLink,
      child: Stack(
        clipBehavior: Clip.none, // 允许子widget超出Stack的范围
        children: [
          Text('${widget.appVersion}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (_hasNewVersion)
            Positioned(
              top: -8, // 调整垂直位置
              right: -10, // 调整水平位置
              child: const Icon(
                Icons.fiber_new_outlined,
                size: 16.0,
                color: Colors.blue, // 可以自定义颜色
              ),
            ),
        ],
      ),
    );
  }
}
