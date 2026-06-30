import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../shared/content_preview_launcher.dart';
import 'student_guide_repository.dart';

class StudentGuideScreen extends StatefulWidget {
  const StudentGuideScreen({super.key});

  @override
  State<StudentGuideScreen> createState() => _StudentGuideScreenState();
}

class _StudentGuideScreenState extends State<StudentGuideScreen> {
  late Future<StudentGuidePayload?> _guideFuture;

  @override
  void initState() {
    super.initState();
    _guideFuture = _fetchGuide();
  }

  Future<StudentGuidePayload?> _fetchGuide() {
    return StudentGuideRepository().fetchGuide();
  }

  void _reload() {
    setState(() {
      _guideFuture = _fetchGuide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.t('User Guide')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGlowBackground(
        child: SafeArea(
          top: false,
          child: FutureBuilder<StudentGuidePayload?>(
            future: _guideFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppLoader(message: AppStrings.t('User Guide'));
              }

              if (snapshot.hasError) {
                return AppErrorState(
                  message: AppStrings.t('Something went wrong'),
                  onRetry: _reload,
                  retryLabel: AppStrings.t('Try Again'),
                );
              }

              final payload = snapshot.data;
              if (payload == null || payload.items.isEmpty) {
                return AppEmptyState(
                  icon: Icons.menu_book_rounded,
                  title: AppStrings.t('No Data Found'),
                );
              }

              final title = payload.title.isEmpty
                  ? AppStrings.t('User Guide')
                  : payload.title;
              final subtitle = payload.subtitle.isEmpty
                  ? AppStrings.t(
                      'Watch the user guide videos below to better understand the system and quickly find answers to your questions.',
                    )
                  : payload.subtitle;

              return ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  AnimatedPageEntrance(
                    child: GradientHero(
                      gradient: AppGradients.hero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: AppRadius.all(AppRadius.md),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.md),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  SectionHeader(
                    title: AppStrings.t('User Guide'),
                    icon: Icons.video_library_rounded,
                  ),
                  StaggeredReveal(
                    children: [
                      for (final item in payload.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: _GuideItemTile(item: item),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GuideItemTile extends StatelessWidget {
  const _GuideItemTile({required this.item});

  final StudentGuideItem item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.hasUrl;
    return AppCard(
      onTap: enabled ? () => _openUrl(context, item.url) : null,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 44,
            decoration: BoxDecoration(
              gradient: enabled ? AppGradients.brand : null,
              color: enabled ? null : AppPalette.line,
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: enabled
                  ? AppShadows.glow(AppColors.brand, opacity: 0.26)
                  : null,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: enabled ? Colors.white : AppColors.muted,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              item.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: enabled ? AppColors.brand : AppColors.muted,
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String value) async {
    final url = value.trim();
    if (url.isEmpty) return;

    if (!context.mounted) return;
    await openContentPreview(
      context,
      title: item.title.isNotEmpty ? item.title : AppStrings.t('User Guide'),
      rawUrl: url,
    );
  }
}
