import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'instructor_instructions_repository.dart';

class InstructorInstructionsScreen extends StatefulWidget {
  const InstructorInstructionsScreen({super.key});

  @override
  State<InstructorInstructionsScreen> createState() =>
      _InstructorInstructionsScreenState();
}

class _InstructorInstructionsScreenState extends State<InstructorInstructionsScreen> {
  late Future<InstructorInstructionsPayload?> _instructionsFuture;

  @override
  void initState() {
    super.initState();
    _instructionsFuture = _fetchInstructions();
  }

  Future<InstructorInstructionsPayload?> _fetchInstructions() {
    return InstructorInstructionsRepository().fetchInstructions();
  }

  void _reload() {
    setState(() {
      _instructionsFuture = _fetchInstructions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(AppStrings.t('Instructions'))),
      body: AppGlowBackground(
        child: FutureBuilder<InstructorInstructionsPayload?>(
          future: _instructionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoader(message: AppStrings.t('Instructions'));
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message: AppStrings.t('Something went wrong'),
                onRetry: _reload,
                retryLabel: AppStrings.t('Try Again'),
              );
            }

            final payload = snapshot.data;
            if (payload == null) {
              return AppEmptyState(
                title: AppStrings.t('No Data Found'),
                icon: Icons.menu_book_rounded,
              );
            }

            return AnimatedPageEntrance(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  GradientHero(
                    gradient: AppGradients.hero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.all(AppRadius.sm),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Text(
                                payload.title,
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
                        if (payload.subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.md),
                          Text(
                            payload.subtitle,
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
                  const SizedBox(height: AppSpace.xl),
                  StaggeredReveal(
                    children: [
                      for (final section in payload.sections)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.lg),
                          child: _InstructionSection(section: section),
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

class _InstructionSection extends StatelessWidget {
  const _InstructionSection({required this.section});

  final InstructorInstructionSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: section.title,
            icon: Icons.checklist_rounded,
          ),
          for (var i = 0; i < section.items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == section.items.length - 1 ? 0 : AppSpace.md,
              ),
              child: _InstructionItem(text: section.items[i]),
            ),
        ],
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.12),
            borderRadius: AppRadius.all(AppRadius.sm),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.brand,
            size: 16,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
