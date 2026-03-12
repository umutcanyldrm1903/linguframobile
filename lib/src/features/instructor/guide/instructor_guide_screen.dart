import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(AppStrings.t('User Guide'))),
      body: FutureBuilder<InstructorGuidePayload?>(
        future: _guideFuture,
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

          final guide = snapshot.data;
          if (guide == null) {
            return Center(child: Text(AppStrings.t('No Data Found')));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(guide.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                guide.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...guide.sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GuideSectionCard(section: section),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({required this.section});

  final InstructorGuideSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...List.generate(section.items.length, (index) {
            final marker =
                section.isOrdered ? '${index + 1}.' : String.fromCharCode(8226);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      marker,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      section.items[index],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
