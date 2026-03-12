import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(AppStrings.t('Instructions'))),
      body: FutureBuilder<InstructorInstructionsPayload?>(
        future: _instructionsFuture,
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

          final payload = snapshot.data;
          if (payload == null) {
            return Center(child: Text(AppStrings.t('No Data Found')));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(payload.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                payload.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...payload.sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InstructionSection(section: section),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InstructionSection extends StatelessWidget {
  const _InstructionSection({required this.section});

  final InstructorInstructionSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.brandDeep,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
