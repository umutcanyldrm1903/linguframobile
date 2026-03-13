import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'public_repository.dart';
import 'public_page_scaffold.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<AboutPayload?> _future =
      PublicRepository().fetchAboutPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<AboutPayload?>(
        future: _future,
        builder: (context, snapshot) {
          final payload = snapshot.data;
          return PublicPageShell(
            title: AppStrings.t('About Us'),
            breadcrumb:
                '${AppStrings.t('Home')}  >  ${AppStrings.t('About Us')}',
            description: _tOr(
              'Meet the LinguFranca model, teaching quality and support structure in one place.',
              'LinguFranca egitim modelini, kalite standardini ve destek yapisini tek ekranda inceleyin.',
            ),
            icon: Icons.info_outline_rounded,
            children: [
              _AboutSection(payload: payload),
              _WhySection(payload: payload),
              _SupportSection(),
              _BrandStrip(payload: payload),
              _FaqSection(payload: payload),
            ],
          );
        },
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.payload});

  final AboutPayload? payload;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final about = payload?.about;
    final title = _firstNonEmpty([
      about?.content['title']?.toString(),
      AppStrings.t('About Us'),
    ]);
    final description = _firstNonEmpty([
      about?.content['description']?.toString(),
      AppStrings.t(
          'We offer transparent pricing tailored to local conditions. By processing in Turkish Lira, we reduce high foreign currency costs.'),
    ]);
    final image = _resolveImage(
      about?.global['image']?.toString(),
      fallback: 'assets/web/h2_banner_img.png',
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 18),
        decoration: BoxDecoration(
          color: AppColors.brandDeep,
          borderRadius: BorderRadius.circular(compact ? 24 : 20),
          boxShadow: compact
              ? [
                  BoxShadow(
                    color: AppColors.brandDeep.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            SizedBox(height: compact ? 12 : 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 20 : 16),
              child: _ImageView(path: image, height: compact ? 168 : 190),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  const _WhySection({required this.payload});

  final AboutPayload? payload;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final features = payload?.features;
    final title = _firstNonEmpty([
      features?.content['title']?.toString(),
      AppStrings.t('Why Choose Us'),
    ]);

    final items = _extractFeatureItems(features);
    final fallbackItems = [
      _FeatureItem(
        title: _tOr('Selected Instructor List', 'Seçkin Eğitmen Listesi'),
        description: _tOr(
          'Instructors are carefully selected, and their profiles are reviewed to ensure quality.',
          'Eğitmenlerimizi titizlikle seçiyor, profillerini detaylıca inceliyoruz.',
        ),
      ),
      _FeatureItem(
        title: _tOr('Secure Infrastructure', 'Güvenilir Altyapı'),
        description: _tOr(
          'Secure payment solutions and strong infrastructure keep your lessons safe.',
          'Güvenli ödeme çözümleri ve güçlü teknik altyapı ile derslerini güvenle al.',
        ),
      ),
      _FeatureItem(
        title: _tOr('Flexible Scheduling', 'Esnek Planlama'),
        description: _tOr(
          'Plan lessons around your schedule and manage time freely.',
          'Kendi programına uygun şekilde ders planla, zamanını özgürce yönet.',
        ),
      ),
    ];

    final displayItems = items.isNotEmpty ? items : fallbackItems;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          SizedBox(height: compact ? 10 : 12),
          ...displayItems.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: compact ? 10 : 12),
              child:
                  _InfoTile(title: item.title, description: item.description),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tOr('Turkish Support', 'Türkçe Desteği'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _tOr(
            'We offer Turkish speaking instructors so you can ask questions comfortably.',
            'Türkçe konuşan eğitmenlerle sorularını rahatça sor, hızlı ilerle.',
          ),
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/student'),
          child: Text(AppStrings.t('Instructors')),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(compact ? 24 : 20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/web/h4_cta_bg.jpg',
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/web/h4_cta_bg.jpg',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BrandStrip extends StatelessWidget {
  const _BrandStrip({required this.payload});

  final AboutPayload? payload;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final brands = payload?.brands ?? [];
    if (brands.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('Brands we work with'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: compact ? 8 : 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final brand = brands[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child:
                      _ImageView(path: brand.imageUrl, width: 90, height: 40),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: brands.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.payload});

  final AboutPayload? payload;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final faqs = payload?.faqs ?? [];
    if (faqs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('FAQs'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: compact ? 8 : 10),
          ...faqs.map(
            (faq) => Padding(
              padding: EdgeInsets.only(bottom: compact ? 10 : 12),
              child: _InfoTile(title: faq.question, description: faq.answer),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 20 : 16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brand.withValues(alpha: 0.15),
            child: const Icon(Icons.check, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageView extends StatelessWidget {
  const _ImageView({required this.path, this.width, this.height});

  final String path;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      );
    }
    return Image.asset(path, width: width, height: height, fit: BoxFit.cover);
  }
}

String _resolveImage(String? raw, {required String fallback}) {
  if (raw == null || raw.isEmpty) return fallback;
  if (raw.startsWith('http')) return raw;
  return '${AppConfig.webBaseUrl}/$raw';
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _tOr(String key, String fallback) {
  final value = AppStrings.t(key);
  return value == key ? fallback : value;
}

List<_FeatureItem> _extractFeatureItems(SectionData? features) {
  if (features == null) return [];
  final raw = features.content['items'] ??
      features.content['features'] ??
      features.content['feature_items'];
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((item) => _FeatureItem(
            title: (item['title'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
          ))
      .where((item) => item.title.isNotEmpty || item.description.isNotEmpty)
      .toList();
}

class _FeatureItem {
  const _FeatureItem({required this.title, required this.description});

  final String title;
  final String description;
}
