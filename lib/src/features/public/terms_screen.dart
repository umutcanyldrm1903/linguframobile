import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'public_header.dart';
import 'public_footer.dart';
import 'public_repository.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<LegalPage?>(
        future: PublicRepository().fetchLegalPage('terms-and-conditions'),
        builder: (context, snapshot) {
          final page = snapshot.data;
          final title = page?.title.isNotEmpty == true
              ? page!.title
              : AppStrings.t('Terms and Conditions');
          final body = _stripHtml(page?.content ?? '');

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const PublicHeader(),
              _HeroBanner(
                title: title,
                breadcrumb:
                    '${AppStrings.t('Home')}  >  ${AppStrings.t('Terms and Conditions')}',
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _LegalBlock(title: title, body: body),
              ),
              const SizedBox(height: 20),
              const PublicFooter(),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.title, required this.breadcrumb});

  final String title;
  final String breadcrumb;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D5B90),
            Color(0xFF0B466F),
            Color(0xFF082C46),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.10,
            child: Image.asset('assets/web/banner_bg.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  breadcrumb,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalBlock extends StatelessWidget {
  const _LegalBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body.isEmpty ? AppStrings.t('No Data Found') : body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

String _stripHtml(String html) {
  return html.replaceAll(RegExp('<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
}
