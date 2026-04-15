import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import 'content_preview_launcher.dart';
import 'whatsapp_launcher.dart';

class TrialLessonActionResult {
  const TrialLessonActionResult({
    required this.message,
    required this.supportUrl,
  });

  final String message;
  final String supportUrl;
}

Future<void> requestTrialLessonWithLoginGate(
  BuildContext context, {
  required Future<TrialLessonActionResult> Function() submitRequest,
  ValueChanged<bool>? onLoadingChanged,
}) async {
  final token = await SecureStorage.getToken();
  if (!context.mounted) return;

  if (token == null || token.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.t('Log in to request a free trial lesson.'),
        ),
      ),
    );
    Navigator.pushNamed(context, '/login');
    return;
  }

  final role = await SecureStorage.getRole();
  if (!context.mounted) return;

  if (role == 'instructor') {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.t('Student Login'))));
    return;
  }

  final shouldSubmit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(AppStrings.t('Schedule Trial Lesson')),
        content: Text(
          AppStrings.t(
            'You are about to request a one-time free trial lesson from our support team!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppStrings.t('Confirm')),
          ),
        ],
      );
    },
  );

  if (shouldSubmit != true || !context.mounted) return;

  onLoadingChanged?.call(true);
  try {
    final result = await submitRequest();
    if (!context.mounted) return;

    final message = result.message.trim().isNotEmpty
        ? result.message.trim()
        : AppStrings.t('Deneme dersi talebiniz alindi.');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    final supportUrl = result.supportUrl.trim();
    if (supportUrl.isNotEmpty) {
      await _openSupportLink(context, supportUrl);
    }
  } catch (error) {
    if (!context.mounted) return;

    if (error is DioException && error.response?.statusCode == 401) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_extractTrialError(error))));
  } finally {
    onLoadingChanged?.call(false);
  }
}

Future<void> _openSupportLink(BuildContext context, String rawUrl) async {
  if (rawUrl.contains('wa.me') || rawUrl.contains('whatsapp')) {
    await openWhatsAppUrl(context, rawUrl: rawUrl);
    return;
  }

  await openContentPreview(
    context,
    title: AppStrings.t('Support'),
    rawUrl: rawUrl,
    browserActionLabel: AppStrings.t('Open Externally'),
  );
}

String _extractTrialError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is Map) {
        return message.values.map((value) => value.toString()).join('\n');
      }
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }
    }
  }

  return AppStrings.t('Something went wrong');
}
