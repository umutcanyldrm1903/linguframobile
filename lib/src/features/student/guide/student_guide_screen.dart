import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../payment/payment_webview_screen.dart';
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
      appBar: AppBar(title: Text(AppStrings.t('User Guide'))),
      body: FutureBuilder<StudentGuidePayload?>(
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

          final payload = snapshot.data;
          if (payload == null || payload.items.isEmpty) {
            return Center(child: Text(AppStrings.t('No Data Found')));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                payload.title.isEmpty
                    ? AppStrings.t('User Guide')
                    : payload.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                payload.subtitle.isEmpty
                    ? AppStrings.t(
                        'Watch the user guide videos below to better understand the system and quickly find answers to your questions.',
                      )
                    : payload.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...payload.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GuideItemTile(item: item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideItemTile extends StatelessWidget {
  const _GuideItemTile({required this.item});

  final StudentGuideItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.hasUrl ? () => _openUrl(context, item.url) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.title)),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String value) async {
    final url = value.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(
          url: uri.toString(),
          title: AppStrings.t('User Guide'),
          successContains: '__never__success__',
          failContains: '__never__fail__',
        ),
      ),
    );
  }
}
