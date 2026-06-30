import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'instructor_guide_repository.dart';

class InstructorGuideScreen extends StatefulWidget {
  const InstructorGuideScreen({super.key});

  @override
  State<InstructorGuideScreen> createState() => _InstructorGuideScreenState();
}

class _InstructorGuideScreenState extends State<InstructorGuideScreen> {
  late Future<InstructorGuidePayload?> _guideFuture;

  @override
  void initState() {
    super.initState();
    _guideFuture = _fetchGuide();
  }

  Future<InstructorGuidePayload?> _fetchGuide() {
    return InstructorGuideRepository().fetchGuide();
  }

  void _reload() {
    setState(() {
      _guideFuture = _fetchGuide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('User Guide'))),
      body: AppGlowBackground(
        child: FutureBuilder<InstructorGuidePayload?>(
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

            final guide = snapshot.data;
            if (guide == null) {
              return AppEmptyState(
                title: AppStrings.t('No Data Found'),
                icon: Icons.menu_book_rounded,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                AnimatedPageEntrance(
                  child: GradientHero(
                    gradient: AppGradients.hero,
                    glowColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: AppRadius.all(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          guide.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (guide.subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            guide.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                StaggeredReveal(
                  children: [
                    for (final section in guide.sections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.lg),
                        child: _GuideSectionCard(section: section),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({required this.section});

  final InstructorGuideSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: section.title,
            icon: section.isOrdered
                ? Icons.format_list_numbered_rounded
                : Icons.checklist_rounded,
          ),
          ...List.generate(section.items.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == section.items.length - 1 ? 0 : AppSpace.md,
              ),
              child: _GuideItem(
                text: section.items[index],
                index: index,
                isOrdered: section.isOrdered,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.text,
    required this.index,
    required this.isOrdered,
  });

  final String text;
  final int index;
  final bool isOrdered;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOrdered)
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.28),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppPalette.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 13,
              color: AppPalette.successDeep,
            ),
          ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
