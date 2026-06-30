import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(AppStrings.t('Agreement'))),
      body: AppGlowBackground(
        child: FutureBuilder<LegalPage?>(
          future: _agreementFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoader(message: AppStrings.t('Agreement'));
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message: AppStrings.t('Something went wrong'),
                onRetry: _reload,
                retryLabel: AppStrings.t('Try Again'),
              );
            }

            final page = snapshot.data;
            final title = page?.title.trim().isNotEmpty == true
                ? page!.title
                : AppStrings.t('Agreement');
            final body = _stripHtml(page?.content ?? '');

            if (body.isEmpty) {
              return AppEmptyState(
                title: AppStrings.t('No Data Found'),
                message: AppStrings.t(
                  'Please review and follow these basic terms while teaching.',
                ),
                icon: Icons.gavel_rounded,
              );
            }

            return AnimatedPageEntrance(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  StaggeredReveal(
                    children: [
                      GradientHero(
                        gradient: AppGradients.hero,
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.all(AppRadius.md),
                              ),
                              child: const Icon(
                                Icons.handshake_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpace.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.t(
                                      'Please review and follow these basic terms while teaching.',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.88),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      SectionHeader(
                        title: AppStrings.t('Agreement'),
                        subtitle: AppStrings.t('Terms and Conditions'),
                        icon: Icons.gavel_rounded,
                      ),
                      AppCard(
                        child: SelectableText(
                          body,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.ink,
                                height: 1.55,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
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
