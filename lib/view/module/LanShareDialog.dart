import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/main.dart';

class LanShareDialog extends StatelessWidget {
  const LanShareDialog({super.key, required this.shareData});

  final Map<String, dynamic> shareData;

  String? get _sharePageUrl => shareData['sharePageUrl'] as String?;
  List<dynamic> get _directDownloads =>
      (shareData['directDownloads'] as List?) ?? const <dynamic>[];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sharePageUrl = _sharePageUrl;
    final fileName = (shareData['fileName'] as String?) ?? '';
    final fileSize = (shareData['fileSize'] as num?)?.toInt() ?? 0;
    final expiresAt = _formatDateTime(shareData['expiresAt'] as String?);

    return AlertDialog(
      title: Text(
        appLocale.getText(LocaleKey.fileleaf_shareDialogTitle).tr([fileName]),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocale.getText(LocaleKey.fileleaf_shareDialogHint),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    icon: Icons.insert_drive_file_outlined,
                    label: appLocale.getText(LocaleKey.fileleaf_propertyName),
                    value: fileName,
                  ),
                  _StatCard(
                    icon: Icons.data_object_rounded,
                    label: appLocale.getText(LocaleKey.fileleaf_propertySize),
                    value: _formatBytes(fileSize),
                  ),
                  _StatCard(
                    icon: Icons.timer_outlined,
                    label: appLocale.getText(LocaleKey.fileleaf_shareExpiresAt),
                    value: expiresAt,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (sharePageUrl != null) ...[
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: QrImageView(
                        data: sharePageUrl,
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  appLocale.getText(LocaleKey.fileleaf_shareLandingLink),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _SelectableUrlCard(text: sharePageUrl),
                const SizedBox(height: 18),
              ],
              Text(
                appLocale.getText(LocaleKey.fileleaf_shareCandidates),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appLocale.getText(LocaleKey.fileleaf_shareBrowserHint),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              ..._directDownloads.map((item) {
                final directDownload = item as Map;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DirectDownloadCard(
                    ip: directDownload['ip']?.toString() ?? '',
                    url: directDownload['downloadUrl']?.toString() ?? '',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocale.getText(LocaleKey.fileleaf_propertyClose)),
        ),
        FilledButton.tonalIcon(
          onPressed: sharePageUrl == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: sharePageUrl));
                  showToast(
                    appLocale.getText(LocaleKey.fileleaf_shareCopiedLink),
                  );
                },
          icon: const Icon(Icons.copy_all_rounded),
          label: Text(appLocale.getText(LocaleKey.fileleaf_shareCopyLink)),
        ),
        FilledButton.icon(
          onPressed: sharePageUrl == null
              ? null
              : () async {
                  final uri = Uri.parse(sharePageUrl);
                  if (!await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  )) {
                    showToast(
                      appLocale.getText(LocaleKey.fileleaf_shareOpenFailed),
                    );
                  }
                },
          icon: const Icon(Icons.open_in_browser_rounded),
          label: Text(appLocale.getText(LocaleKey.fileleaf_shareOpenLanding)),
        ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _formatDateTime(String? isoText) {
    if (isoText == null || isoText.isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(isoText);
    if (parsed == null) {
      return isoText;
    }
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 228),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.64),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableUrlCard extends StatelessWidget {
  const _SelectableUrlCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SelectableText(text),
      ),
    );
  }
}

class _DirectDownloadCard extends StatelessWidget {
  const _DirectDownloadCard({required this.ip, required this.url});

  final String ip;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lan_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ip,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    showToast(
                      appLocale.getText(LocaleKey.fileleaf_shareCopiedLink),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(
                    appLocale.getText(LocaleKey.fileleaf_shareCopyLink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(url),
          ],
        ),
      ),
    );
  }
}
