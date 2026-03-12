import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../public/public_repository.dart';

class InstructorAgreementScreen extends StatefulWidget {
  const InstructorAgreementScreen({super.key});

  @override
  State<InstructorAgreementScreen> createState() =>
      _InstructorAgreementScreenState();
}

class _InstructorAgreementScreenState extends State<InstructorAgreementScreen> {
  late Future<LegalPage?> _agreementFuture;

  @override
  void initState() {
    super.initState();
    _agreementFuture = _fetchAgreement();
  }

  Future<LegalPage?> _fetchAgreement() {
    return PublicRepository().fetchLegalPage('terms-and-conditions');
  }

  void _reload() {
    setState(() {
      _agreementFuture = _fetchAgreement();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Agreement'))),
      body: FutureBuilder<LegalPage?>(
        future: _agreementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStrings.t('Something went wrong')),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _reload,
                    child: Text(AppStrings.t('Try Again')),
                  ),
                ],
              ),
            );
          }

          final page = snapshot.data;
          final title = page?.title.trim().isNotEmpty == true
              ? page!.title
              : AppStrings.t('Agreement');
          final body = _stripHtml(page?.content ?? '');

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                AppStrings.t(
                  'Please review and follow these basic terms while teaching.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  body.isEmpty ? AppStrings.t('No Data Found') : body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _stripHtml(String html) {
  return html
      .replaceAll(RegExp('<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
