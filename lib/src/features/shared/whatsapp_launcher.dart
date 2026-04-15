import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import 'content_preview_launcher.dart';

Future<void> openWhatsAppUrl(
  BuildContext context, {
  required String rawUrl,
}) async {
  final value = rawUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.t('Link not found.'))));
    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (opened || !context.mounted) return;

  await openContentPreview(
    context,
    title: 'WhatsApp',
    rawUrl: value,
    browserActionLabel: AppStrings.t('Open Externally'),
  );
}

Future<void> openWhatsAppLead(
  BuildContext context, {
  required String phone,
  required List<String> messageLines,
  String? missingPhoneMessage,
  String fallbackRoute = '/contact',
}) async {
  final cleaned = phone.replaceAll(RegExp(r'\D+'), '');
  if (cleaned.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          missingPhoneMessage ??
              AppStrings.t(
                'WhatsApp line is not configured right now. Opening contact page.',
              ),
        ),
      ),
    );
    Navigator.pushNamed(context, fallbackRoute);
    return;
  }

  final content = messageLines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
  final encoded = Uri.encodeComponent(content);
  await openWhatsAppUrl(
    context,
    rawUrl: 'https://wa.me/$cleaned?text=$encoded',
  );
}
