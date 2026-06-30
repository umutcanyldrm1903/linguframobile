import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../public/public_repository.dart';
import '../../../core/localization/app_currency_provider.dart';
import '../../../core/localization/app_locale_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';

class StudentLanguageScreen extends ConsumerStatefulWidget {
  const StudentLanguageScreen({super.key});

  @override
  ConsumerState<StudentLanguageScreen> createState() =>
      _StudentLanguageScreenState();
}

class _StudentLanguageScreenState extends ConsumerState<StudentLanguageScreen> {
  late final Future<_SettingsPayload> _future = _SettingsPayload.load();

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(appLocaleProvider);
    final currentCurrency = ref.watch(appCurrencyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(AppStrings.t('Language and Currency'))),
      body: AppGlowBackground(
        child: FutureBuilder<_SettingsPayload>(
          future: _future,
          builder: (context, snapshot) {
            final payload = snapshot.data;

            final languages = (payload?.languages ?? const <LanguageOption>[])
                .where((lang) => lang.isActive && lang.code.isNotEmpty)
                .toList(growable: false);
            final currencies = (payload?.currencies ?? const <CurrencyOption>[])
                .where((cur) => cur.code.isNotEmpty)
                .toList(growable: false);

            final fallbackLanguages = const [
              LanguageOption(
                code: 'tr',
                name: 'Turkish',
                direction: 'ltr',
                isDefault: false,
                isActive: true,
              ),
              LanguageOption(
                code: 'en',
                name: 'English',
                direction: 'ltr',
                isDefault: true,
                isActive: true,
              ),
            ];

            final displayLanguages =
                languages.isNotEmpty ? languages : fallbackLanguages;

            final fallbackCurrencies = const [
              CurrencyOption(
                code: 'TRY',
                name: 'TRY',
                rate: 1,
                position: '',
                isDefault: 'yes',
                status: 'active',
              ),
            ];
            final displayCurrencies =
                currencies.isNotEmpty ? currencies : fallbackCurrencies;

            return ListView(
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                AnimatedPageEntrance(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: AppStrings.t('Select language'),
                          icon: Icons.translate_rounded,
                        ),
                        for (final lang in displayLanguages) ...[
                          _OptionTile(
                            title: AppStrings.t(lang.name),
                            subtitle: lang.code.toUpperCase(),
                            isActive: currentLanguage == lang.code,
                            onTap: () => AppLocale.set(ref, lang.code),
                          ),
                          if (lang != displayLanguages.last)
                            const SizedBox(height: AppSpace.sm),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                AnimatedPageEntrance(
                  delay: const Duration(milliseconds: 90),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: AppStrings.t('Currency'),
                          icon: Icons.payments_rounded,
                        ),
                        for (final cur in displayCurrencies) ...[
                          _OptionTile(
                            title: cur.code,
                            subtitle: cur.name,
                            isActive: currentCurrency == cur.code,
                            onTap: () => AppCurrency.set(ref, cur.code),
                          ),
                          if (cur != displayCurrencies.last)
                            const SizedBox(height: AppSpace.sm),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsPayload {
  const _SettingsPayload({required this.languages, required this.currencies});

  final List<LanguageOption> languages;
  final List<CurrencyOption> currencies;

  static Future<_SettingsPayload> load() async {
    final repo = PublicRepository();
    final results = await Future.wait([
      repo.fetchLanguages(),
      repo.fetchCurrencies(),
    ]);

    final languages = results[0] is List<LanguageOption>
        ? results[0] as List<LanguageOption>
        : const <LanguageOption>[];
    final currencies = results[1] is List<CurrencyOption>
        ? results[1] as List<CurrencyOption>
        : const <CurrencyOption>[];

    return _SettingsPayload(languages: languages, currencies: currencies);
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    this.subtitle,
    this.isActive = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      radius: AppRadius.sm,
      border: false,
      shadow: const [],
      gradient: isActive ? AppGradients.brand : null,
      color: isActive ? null : AppPalette.cloud,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : AppColors.ink,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.0),
              border: Border.all(
                color: isActive ? Colors.transparent : AppPalette.line,
                width: 2,
              ),
            ),
            child: isActive
                ? const Icon(Icons.check_rounded,
                    size: 17, color: AppColors.brand)
                : null,
          ),
        ],
      ),
    );
  }
}
