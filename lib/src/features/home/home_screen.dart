import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../student/instructors/student_instructors_screen.dart';
import '../student/packages/student_packages_screen.dart';
import '../public/public_repository.dart';
import '../public/public_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  Future<HomePayload?>? _homeFuture;
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _packagesKey = GlobalKey();
  final GlobalKey _instagramKey = GlobalKey();
  final GlobalKey _reviewsKey = GlobalKey();
  final GlobalKey _journeyKey = GlobalKey();
  final GlobalKey _corporateKey = GlobalKey();
  final GlobalKey _appKey = GlobalKey();
  bool _handledInitialNav = false;

  @override
  void initState() {
    super.initState();
    _homeFuture = PublicRepository().fetchHomePage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledInitialNav) return;
    _handledInitialNav = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleNav(args.trim());
      });
    }
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleNav(String id) {
    switch (id) {
      case 'home':
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
        break;
      case 'packages':
        _scrollTo(_packagesKey);
        break;
      case 'instagram':
        _scrollTo(_instagramKey);
        break;
      case 'instructors':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentInstructorsScreen(standalone: true),
          ),
        );
        break;
      case 'reviews':
        _scrollTo(_reviewsKey);
        break;
      case 'journey':
        _scrollTo(_journeyKey);
        break;
      case 'corporate':
        Navigator.pushNamed(context, '/corporate');
        break;
      case 'placement':
        Navigator.pushNamed(context, '/placement-test');
        break;
      case 'about':
        Navigator.pushNamed(context, '/about');
        break;
      case 'blog':
        Navigator.pushNamed(context, '/blog');
        break;
      case 'contact':
        Navigator.pushNamed(context, '/contact');
        break;
      case 'app':
        _scrollTo(_appKey);
        break;
      case 'terms':
        Navigator.pushNamed(context, '/terms');
        break;
      case 'privacy':
        Navigator.pushNamed(context, '/privacy');
        break;
    }
  }

  void _showNativeMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            _NativeMenuItem(
              label: AppStrings.t('Home'),
              onTap: () => _handleNav('home'),
            ),
            _NativeMenuItem(
              label: AppStrings.t('Packages'),
              onTap: () => _handleNav('packages'),
            ),
            _NativeMenuItem(
              label: AppStrings.t('Instructors'),
              onTap: () => _handleNav('instructors'),
            ),
            _NativeMenuItem(
              label: AppStrings.t('Corporate'),
              onTap: () => _handleNav('corporate'),
            ),
            _NativeMenuItem(
              label: AppStrings.t('About Us'),
              onTap: () => _handleNav('about'),
            ),
            _NativeMenuItem(
              label: AppStrings.t('Blog'),
              onTap: () => _handleNav('blog'),
            ),
            _NativeMenuItem(
              label: AppStrings.t('Contact Us'),
              onTap: () => _handleNav('contact'),
            ),
            _NativeMenuItem(
              label: AppStrings.t('2-Minute English Level Test'),
              onTap: () => _handleNav('placement'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLeadFormSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, bottom + 10),
            child: SingleChildScrollView(
              child: const _HeroFormCard(compact: true),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;
    final sectionGap = compact ? 14.0 : 24.0;

    return FutureBuilder<HomePayload?>(
      future: _homeFuture,
      builder: (context, snapshot) {
        final payload = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                if (compact)
                  _NativeHomeTopBar(
                    onLogin: () => Navigator.pushNamed(context, '/login'),
                    onRegister: () => Navigator.pushNamed(context, '/register'),
                    onMenu: () => _showNativeMenu(context),
                  )
                else
                  PublicHeader(onNavTap: _handleNav),
                HeroSection(
                  key: _heroKey,
                  hero: payload?.hero,
                  compact: compact,
                  showInlineForm: !compact,
                  onOpenLeadForm: compact ? _openLeadFormSheet : null,
                ),
                SizedBox(height: compact ? 12 : 16),
                StatsSection(counter: payload?.counter),
                SizedBox(height: sectionGap),
                InstructorSection(
                  instructors: payload?.selectedInstructors ?? const [],
                  section: payload?.featuredInstructorSection,
                ),
                SizedBox(height: sectionGap),
                PackagesSection(key: _packagesKey),
                SizedBox(height: sectionGap),
                InstagramSection(
                  key: _instagramKey,
                  onNavTap: _handleNav,
                  instructors: payload?.selectedInstructors ?? const [],
                ),
                SizedBox(height: sectionGap),
                ReviewsSection(reviews: payload?.testimonials ?? const []),
                SizedBox(height: sectionGap),
                JourneySection(key: _journeyKey, about: payload?.about),
                SizedBox(height: sectionGap),
                CorporateSection(
                  key: _corporateKey,
                  onNavTap: _handleNav,
                  banner: payload?.banner,
                ),
                SizedBox(height: sectionGap),
                const InstructorCtaSection(),
                SizedBox(height: sectionGap),
                AppDownloadSection(key: _appKey),
                SizedBox(height: sectionGap),
                FooterSection(onNavTap: _handleNav),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NativeHomeTopBar extends StatelessWidget {
  const _NativeHomeTopBar({
    required this.onLogin,
    required this.onRegister,
    required this.onMenu,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: AppColors.brandDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LinguFranca',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.t('Continue Learning'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onLogin,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppStrings.t('Log In'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: onRegister,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.ink,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                tooltip: AppStrings.t('Sign Up'),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: onMenu,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brand.withValues(alpha: 0.14),
                  foregroundColor: AppColors.brandDeep,
                ),
                icon: const Icon(Icons.menu_rounded),
                tooltip: AppStrings.t('Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NativeMenuItem extends StatelessWidget {
  const _NativeMenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

String _resolveImage(String? raw) {
  if (raw == null) return '';
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.startsWith('http')) return value;
  if (value.startsWith('//')) return 'https:$value';
  if (value.startsWith('/')) return AppConfig.webBaseUrl + value;
  return '${AppConfig.webBaseUrl}/$value';
}

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    this.hero,
    this.compact = false,
    this.showInlineForm = true,
    this.onOpenLeadForm,
  });

  final SectionData? hero;
  final bool compact;
  final bool showInlineForm;
  final VoidCallback? onOpenLeadForm;

  @override
  Widget build(BuildContext context) {
    final content = hero?.content ?? const <String, dynamic>{};
    String readText(String key, String fallback) {
      final raw = content[key];
      if (raw == null) return fallback;
      final cleaned = raw.toString().replaceAll(RegExp('<[^>]*>'), '').trim();
      return cleaned.isEmpty ? fallback : cleaned;
    }

    final eyebrow = readText(
      'short_title',
      AppStrings.t('Live online lessons'),
    );
    final title = readText(
      'title',
      AppStrings.t('Start your Learning Journey Today!'),
    );
    final description = readText(
      'sub_title',
      AppStrings.t(
        'Start live lessons with native English instructors who also speak Turkish.',
      ),
    );
    final primaryLabel = readText(
      'action_button_text',
      AppStrings.t('Start now with a free trial lesson!'),
    );
    final secondaryLabel = readText(
      'video_button_text',
      AppStrings.t('Explore packages'),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        compact ? 22 : 32,
        compact ? 14 : 20,
        compact ? 24 : 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D5B90), Color(0xFF0B466F), Color(0xFF082C46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: eyebrow),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  fontSize: compact ? 30 : null,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: compact ? 14 : null,
                ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(text: AppStrings.t('Free Trial Lesson')),
              _Pill(
                text: AppStrings.t('Native and expert instructors'),
                ghost: true,
              ),
              _Pill(
                text: AppStrings.t('Flexible times, live online'),
                ghost: true,
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(primaryLabel),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentPackagesScreen(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: Text(secondaryLabel),
              ),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/placement-test'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                ),
                child: Text(AppStrings.t('2-Minute English Level Test')),
              ),
              if (compact && onOpenLeadForm != null)
                OutlinedButton.icon(
                  onPressed: onOpenLeadForm,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(
                    AppStrings.t('Get pricing info on WhatsApp in minutes.'),
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: AppColors.brand),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.t('Let us find a plan for you.'),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 20),
            const Row(
              children: [
                _StoreBadge(text: 'App Store'),
                SizedBox(width: 10),
                _StoreBadge(text: 'Google Play'),
              ],
            ),
            const SizedBox(height: 22),
          ] else ...[
            const SizedBox(height: 14),
          ],
          if (showInlineForm) _HeroFormCard(compact: compact),
        ],
      ),
    );
  }
}

class _HeroFormCard extends StatefulWidget {
  const _HeroFormCard({this.compact = false});

  final bool compact;

  @override
  State<_HeroFormCard> createState() => _HeroFormCardState();
}

class _HeroFormCardState extends State<_HeroFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  late final Future<PublicSettings?> _settingsFuture =
      PublicRepository().fetchSettings();
  bool _consentMarketing = false;
  bool _consentPrivacy = false;
  String _phoneType = 'Mobile';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final age = _ageController.text.trim();

    final messageLines = [
      AppStrings.t('Pricing information request'),
      '${AppStrings.t('First name')}: ${_firstNameController.text.trim()}',
      '${AppStrings.t('Last name')}: ${_lastNameController.text.trim()}',
      '${AppStrings.t('Email')}: $email',
      '${AppStrings.t('Phone type')}: ${AppStrings.t(_phoneType)}',
      '${AppStrings.t('Phone')}: $phone',
      '${AppStrings.t('User age')}: ${age.isEmpty ? '-' : age}',
      '${AppStrings.t('Marketing Consent')}: ${_consentMarketing ? AppStrings.t('YES') : AppStrings.t('NO')}',
      '${AppStrings.t('I have read and understood the Privacy Notice regarding processing, storage, and transfer of my personal data.')} ${_consentPrivacy ? AppStrings.t('YES') : AppStrings.t('NO')}',
      '${AppStrings.t('Page')}: ${AppConfig.webBaseUrl}',
    ];

    try {
      if (!_consentMarketing || !_consentPrivacy) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.t('Required'))));
        return;
      }

      final settings = await _settingsFuture;
      final waPhone = (settings?.whatsappLeadPhone ?? '').trim();
      if (waPhone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'WhatsApp number is not set. Add WHATSAPP_LEAD_PHONE=90xxxxxxxxxx to .env.',
              ),
            ),
          ),
        );
        return;
      }

      final encoded = Uri.encodeComponent(messageLines.join('\n'));
      final cleaned = waPhone.replaceAll(RegExp(r'\\D'), '');
      final waUrl = cleaned.isNotEmpty
          ? 'https://wa.me/$cleaned?text=$encoded'
          : 'https://wa.me/?text=$encoded';

      final ok = await launchUrl(
        Uri.parse(waUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Something went wrong'))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Something went wrong'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.compact ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('Fill out the form to get pricing information'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDeep,
                    fontSize: widget.compact ? 16 : null,
                  ),
            ),
            SizedBox(height: widget.compact ? 10 : 14),
            _Field(
              label: '${AppStrings.t('First name')} *',
              controller: _firstNameController,
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Name is required')
                  : null,
            ),
            SizedBox(height: widget.compact ? 8 : 10),
            _Field(
              label: '${AppStrings.t('Last name')} *',
              controller: _lastNameController,
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Name is required')
                  : null,
            ),
            SizedBox(height: widget.compact ? 8 : 10),
            _Field(
              label: '${AppStrings.t('Email')} *',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Email is required')
                  : null,
            ),
            SizedBox(height: widget.compact ? 8 : 10),
            Text(
              AppStrings.t('Phone type'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: widget.compact ? 4 : 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(AppStrings.t('Mobile')),
                  selected: _phoneType == 'Mobile',
                  onSelected: (_) => setState(() => _phoneType = 'Mobile'),
                ),
                ChoiceChip(
                  label: Text(AppStrings.t('Landline')),
                  selected: _phoneType == 'Landline',
                  onSelected: (_) => setState(() => _phoneType = 'Landline'),
                ),
              ],
            ),
            SizedBox(height: widget.compact ? 8 : 10),
            _Field(
              label: '${AppStrings.t('Phone')} *',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Phone is required')
                  : null,
            ),
            SizedBox(height: widget.compact ? 8 : 10),
            _Field(
              label: AppStrings.t('User age'),
              controller: _ageController,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: widget.compact ? 8 : 12),
            CheckboxListTile(
              value: _consentMarketing,
              onChanged: (value) =>
                  setState(() => _consentMarketing = value ?? false),
              title: Text(
                AppStrings.t(
                  'I agree to receive commercial electronic messages under the ETK Information Text.',
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _consentPrivacy,
              onChanged: (value) =>
                  setState(() => _consentPrivacy = value ?? false),
              title: Text(
                AppStrings.t(
                  'I have read and understood the Privacy Notice regarding processing, storage, and transfer of my personal data.',
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: widget.compact ? 6 : 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.lock_outline, size: 18),
                label: Text(AppStrings.t('Submit Now')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsSection extends StatelessWidget {
  const StatsSection({super.key, this.counter});

  final SectionData? counter;

  @override
  Widget build(BuildContext context) {
    final global = counter?.global ?? const <String, dynamic>{};
    String? readValue(String key) {
      final raw = global[key];
      if (raw == null) return null;
      final value = raw.toString().trim();
      return value.isEmpty ? null : value;
    }

    final stats = <_StatItemData>[
      if (readValue('total_student_count') != null)
        _StatItemData(
          label: AppStrings.t('Students'),
          value: readValue('total_student_count')!,
        ),
      if (readValue('total_instructor_count') != null)
        _StatItemData(
          label: AppStrings.t('Instructors'),
          value: readValue('total_instructor_count')!,
        ),
      if (readValue('total_awards_count') != null)
        _StatItemData(
          label: AppStrings.t('Years of experience'),
          value: readValue('total_awards_count')!,
        ),
    ];

    final fallbackStats = <_StatItemData>[
      _StatItemData(label: AppStrings.t('Students'), value: '+3.000'),
      _StatItemData(label: AppStrings.t('Instructors'), value: '+100'),
      _StatItemData(label: AppStrings.t('Years of experience'), value: '+6'),
    ];

    final displayStats = stats.isNotEmpty ? stats : fallbackStats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          runSpacing: 12,
          spacing: 16,
          children: displayStats
              .map((stat) => _StatItem(label: stat.label, value: stat.value))
              .toList(),
        ),
      ),
    );
  }
}

class InstagramSection extends StatelessWidget {
  const InstagramSection({
    super.key,
    required this.onNavTap,
    required this.instructors,
  });

  final ValueChanged<String> onNavTap;
  final List<FeaturedInstructor> instructors;

  @override
  Widget build(BuildContext context) {
    final displayItems = instructors.isNotEmpty
        ? instructors.take(8).toList(growable: false)
        : const <FeaturedInstructor>[];
    return Container(
      color: AppColors.brandDeep,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${AppStrings.t('Visit us on Instagram')}\n${AppStrings.t('Meet the team')}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.t(
                'Meet our team on Instagram. Follow daily English posts to learn new words, tips, and phrases. Improve your English in a fun way!',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                if (displayItems.isNotEmpty) {
                  final instructor = displayItems[index];
                  return _InstaCard(
                    instructor: instructor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StudentInstructorsScreen(standalone: true),
                      ),
                    ),
                  );
                }
                return _InstaCard(index: index);
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: displayItems.isNotEmpty ? displayItems.length : 6,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () async {
                final uri = Uri.parse('https://www.instagram.com/lingufranca/');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              child: Text(AppStrings.t('Visit')),
            ),
          ),
        ],
      ),
    );
  }
}

class InstructorSection extends StatelessWidget {
  const InstructorSection({super.key, required this.instructors, this.section});

  final List<FeaturedInstructor> instructors;
  final FeaturedInstructorSection? section;

  @override
  Widget build(BuildContext context) {
    final sectionTitle = (section?.title ?? '').trim();
    final sectionSubtitle = (section?.subtitle ?? '').trim();
    final titleText = sectionTitle.isNotEmpty
        ? sectionTitle
        : AppStrings.t('Choose your favorite instructor and plan your lesson');

    final items = instructors.isNotEmpty
        ? instructors.map((item) {
            final imageUrl = _resolveImage(item.imageUrl);
            return _InstructorCardData(
              name: item.name,
              title: item.jobTitle.isNotEmpty
                  ? item.jobTitle
                  : AppStrings.t('Instructor'),
              image: imageUrl.isNotEmpty ? imageUrl : (item.imageUrl ?? ''),
              isNetwork: imageUrl.isNotEmpty,
              rating: item.avgRating,
              courseCount: item.courseCount,
            );
          }).toList()
        : const [
            _InstructorCardData(
              name: 'Ethan Granger',
              title: 'Developer',
              image: 'assets/web/h2_instructor01.png',
            ),
            _InstructorCardData(
              name: 'Jason Thorne',
              title: 'Developer',
              image: 'assets/web/h2_instructor02.png',
            ),
            _InstructorCardData(
              name: 'Mark Davenport',
              title: 'Developer',
              image: 'assets/web/h2_instructor03.png',
            ),
          ];

    return _Section(
      eyebrow: AppStrings.t('Instructors'),
      title: titleText,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionSubtitle.isNotEmpty) ...[
              Text(
                sectionSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items
                  .map(
                    (item) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const StudentInstructorsScreen(standalone: true),
                        ),
                      ),
                      child: _InstructorCard(item: item),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class PackagesSection extends StatefulWidget {
  const PackagesSection({super.key});

  @override
  State<PackagesSection> createState() => _PackagesSectionState();
}

class _PackagesSectionState extends State<PackagesSection> {
  _PlanData? _selectedPlan;
  final GlobalKey _formKey = GlobalKey();
  int _flowSession = 0;
  bool _highlightForm = false;
  bool _sheetOpen = false;
  late final Future<PlanPayload?> _plansFuture =
      PublicRepository().fetchStudentPlans();

  Future<void> _handleStart(_PlanData plan) async {
    setState(() {
      _selectedPlan = plan;
      _flowSession += 1;
      _highlightForm = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final formContext = _formKey.currentContext;
      if (formContext != null) {
        Scrollable.ensureVisible(
          formContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _highlightForm = false);
    });

    if (_sheetOpen) return;

    final width = MediaQuery.sizeOf(context).width;
    final useBottomSheet = width < 720;
    if (!useBottomSheet) return;

    _sheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PlanFlowSheet(
          key: ValueKey('${plan.id}_sheet_$_flowSession'),
          plan: plan,
          inline: false,
        ),
      );
    } finally {
      _sheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      eyebrow: AppStrings.t('Packages'),
      title: AppStrings.t('Choose the plan that fits you best'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(
                'Pick a package, fill out a short form, and send your details via WhatsApp.',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            FutureBuilder<PlanPayload?>(
              future: _plansFuture,
              builder: (context, snapshot) {
                final payload = snapshot.data;
                final plans = payload?.plans ?? const <StudentPlan>[];

                List<StudentPlan> reorderPlans(List<StudentPlan> source) {
                  final list = List<StudentPlan>.from(source);
                  StudentPlan? premium;
                  for (final plan in list) {
                    final text = (plan.displayTitle.isNotEmpty
                            ? plan.displayTitle
                            : plan.title)
                        .toLowerCase();
                    if (text.contains('premium')) {
                      premium = plan;
                      break;
                    }
                  }

                  if (premium == null) return list;

                  final others = list.where((plan) => plan != premium).toList();
                  if (others.isEmpty) return [premium];

                  others.sort(
                    (a, b) => b.lessonsTotal.compareTo(a.lessonsTotal),
                  );

                  final first = others.removeAt(0);
                  return [first, premium, ...others];
                }

                final displayPlans =
                    plans.isEmpty ? const <StudentPlan>[] : reorderPlans(plans);

                final mappedPlans = displayPlans.isNotEmpty
                    ? displayPlans.asMap().entries.map((entry) {
                        final plan = entry.value;
                        final tone = _planToneForIndex(entry.key);
                        final title = plan.displayTitle.isNotEmpty
                            ? plan.displayTitle
                            : (plan.title.isNotEmpty ? plan.title : 'Plan');
                        final isPremium = title.toLowerCase().contains(
                              'premium',
                            );
                        final isFeatured = plan.featured || isPremium;
                        final primaryBadge = plan.label.isNotEmpty
                            ? plan.label
                            : (isPremium ? AppStrings.t('En Populer') : null);
                        final secondaryBadge =
                            isPremium ? AppStrings.t('En Avantajli') : null;
                        final subtitle =
                            '${plan.durationMonths} ${AppStrings.t('Months')}';
                        final lessons =
                            '${plan.lessonsTotal} ${AppStrings.t('Lessons')}';

                        return _PlanData(
                          id: plan.key.isNotEmpty
                              ? plan.key
                              : 'plan_${entry.key}',
                          title: title,
                          subtitle: subtitle,
                          lessons: lessons,
                          highlight: AppStrings.t('Start'),
                          tone: tone,
                          badge: primaryBadge,
                          badgeSecondary: secondaryBadge,
                          featured: isFeatured,
                        );
                      }).toList()
                    : [
                        _PlanData(
                          id: 'plan_6m',
                          title: 'Progress Builder',
                          subtitle: AppStrings.t('Beginner'),
                          lessons: '48 ${AppStrings.t('Lessons')}',
                          highlight: AppStrings.t('Start'),
                          tone: _PlanTone.sunset,
                        ),
                        _PlanData(
                          id: 'plan_12m',
                          title: 'Premium Paket',
                          subtitle: AppStrings.t('Most Popular'),
                          lessons: '96 ${AppStrings.t('Lessons')}',
                          highlight: AppStrings.t('Start'),
                          tone: _PlanTone.sky,
                          badge: AppStrings.t('En Populer'),
                          badgeSecondary: AppStrings.t('En Avantajli'),
                          featured: true,
                        ),
                        _PlanData(
                          id: 'plan_3m',
                          title: 'Core Starter',
                          subtitle: AppStrings.t('Short term'),
                          lessons: '24 ${AppStrings.t('Lessons')}',
                          highlight: AppStrings.t('Start'),
                          tone: _PlanTone.slate,
                        ),
                      ];

                return Column(
                  children: [
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: CircularProgressIndicator(),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F1FF), Color(0xFFF8F0FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 14.0;
                          final columns = constraints.maxWidth < 260
                              ? 1
                              : (constraints.maxWidth < 900 ? 2 : 3);
                          final cardWidth = columns == 1
                              ? constraints.maxWidth
                              : (constraints.maxWidth -
                                      (spacing * (columns - 1))) /
                                  columns;

                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: spacing,
                            runSpacing: spacing,
                            children: mappedPlans
                                .map(
                                  (plan) => SizedBox(
                                    width: cardWidth,
                                    child: _PlanCard(
                                      plan: plan,
                                      selected: _selectedPlan?.id == plan.id,
                                      onStart: () {
                                        _handleStart(plan);
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedContainer(
                      key: _formKey,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: _highlightForm
                              ? AppColors.brand.withOpacity(0.75)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _highlightForm
                            ? [
                                BoxShadow(
                                  color: AppColors.brand.withOpacity(0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 18),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _PlanFlowSheet(
                          key: ValueKey(
                            '${_selectedPlan?.id ?? 'empty'}_$_flowSession',
                          ),
                          plan: _selectedPlan,
                          inline: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentPackagesScreen(),
                          ),
                        ),
                        child: Text(AppStrings.t('View All')),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanFlowSheet extends StatefulWidget {
  const _PlanFlowSheet({super.key, required this.plan, this.inline = false});

  final _PlanData? plan;
  final bool inline;

  @override
  State<_PlanFlowSheet> createState() => _PlanFlowSheetState();
}

class _PlanFlowSheetState extends State<_PlanFlowSheet> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  late final Future<PublicSettings?> _settingsFuture;

  int _stepIndex = 0;
  String _lessonPlace = 'Online (Zoom)';
  String? _studentType;
  String? _goal;
  String? _level;
  String? _frequency;
  String? _when;

  int get _totalSteps => 9;

  @override
  void initState() {
    super.initState();
    _settingsFuture = PublicRepository().fetchSettings();
  }

  @override
  void didUpdateWidget(covariant _PlanFlowSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentId = widget.plan?.id ?? '';
    final previousId = oldWidget.plan?.id ?? '';
    if (currentId == previousId) return;

    setState(() {
      _stepIndex = 0;
      _lessonPlace = 'Online (Zoom)';
      _studentType = null;
      _goal = null;
      _level = null;
      _frequency = null;
      _when = null;
    });

    _detailsController.clear();
    _fullNameController.clear();
    _phoneController.clear();
    _emailController.clear();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStep() {
    if (widget.plan == null) return false;
    switch (_stepIndex) {
      case 1:
        if (_studentType == null) {
          _showError(AppStrings.t('Required'));
          return false;
        }
        break;
      case 2:
        if (_goal == null) {
          _showError(AppStrings.t('Required'));
          return false;
        }
        break;
      case 3:
        if (_level == null) {
          _showError(AppStrings.t('Required'));
          return false;
        }
        break;
      case 4:
        if (_frequency == null) {
          _showError(AppStrings.t('Required'));
          return false;
        }
        break;
      case 5:
        if (_detailsController.text.trim().isEmpty) {
          _showError(AppStrings.t('Write a short note (required)'));
          return false;
        }
        break;
      case 6:
        if (_when == null) {
          _showError(AppStrings.t('Required'));
          return false;
        }
        break;
      case 7:
        if (_fullNameController.text.trim().isEmpty ||
            _phoneController.text.trim().isEmpty) {
          _showError(AppStrings.t('Required'));
          return false;
        }
        final email = _emailController.text.trim();
        if (email.isNotEmpty && !email.contains('@')) {
          _showError(AppStrings.t('The email must be a valid email address'));
          return false;
        }
        break;
    }
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_stepIndex < _totalSteps - 1) {
      setState(() {
        _stepIndex += 1;
      });
    }
  }

  void _back() {
    if (_stepIndex == 0) return;
    setState(() {
      _stepIndex -= 1;
    });
  }

  String _buildMessage() {
    final selectedPlan = widget.plan;
    if (selectedPlan == null) return '';

    final plan = [
      selectedPlan.title,
      selectedPlan.lessons,
    ].where((value) => value.trim().isNotEmpty).join(' - ');

    final lines = <String>[
      AppStrings.t('New Language Course Request'),
      '${AppStrings.t('Package')}: $plan',
      '',
      '${AppStrings.t('Lesson location')}: ${AppStrings.t(_lessonPlace)}',
      '${AppStrings.t('Learner')}: ${AppStrings.t(_studentType ?? '')}',
      '${AppStrings.t('Goal')}: ${AppStrings.t(_goal ?? '')}',
      '${AppStrings.t('Level')}: ${AppStrings.t(_level ?? '')}',
      '${AppStrings.t('Frequency')}: ${AppStrings.t(_frequency ?? '')}',
      '${AppStrings.t('Preferred start')}: ${AppStrings.t(_when ?? '')}',
      '${AppStrings.t('Notes')}: ${_detailsController.text.trim()}',
      '',
      '${AppStrings.t('Full name')}: ${_fullNameController.text.trim()}',
      '${AppStrings.t('Phone')}: ${_phoneController.text.trim()}',
      '${AppStrings.t('Email')}: ${_emailController.text.trim().isEmpty ? '-' : _emailController.text.trim()}',
      '',
      '${AppStrings.t('Page')}: ${AppConfig.webBaseUrl}',
    ];
    return lines.join('\n');
  }

  Future<void> _sendWhatsApp(String phone) async {
    final message = Uri.encodeComponent(_buildMessage());
    final cleaned = phone.replaceAll(RegExp(r'\\D'), '');
    final url = cleaned.isNotEmpty
        ? 'https://wa.me/$cleaned?text=$message'
        : 'https://wa.me/?text=$message';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!widget.inline) {
      Navigator.pop(context);
    }
  }

  Widget _buildOptionGroup({
    required List<String> options,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      children: options.map((option) {
        final selected = option == groupValue;
        final baseTint = AppColors.brandDeep.withOpacity(0.04);
        final hoverTint = AppColors.brandDeep.withOpacity(0.06);
        final borderTint = AppColors.brandDeep.withOpacity(0.18);
        final selectedBorder = AppColors.brand;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onChanged(option),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? hoverTint : baseTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? selectedBorder : borderTint,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? selectedBorder
                            : AppColors.brandDeep.withOpacity(0.28),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? selectedBorder : Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.t(option),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepContent() {
    const questionStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 20,
      color: AppColors.ink,
    );
    switch (_stepIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('Where should the lesson take place?'),
              style: questionStyle,
            ),
            _buildOptionGroup(
              options: const ['Online (Zoom)'],
              groupValue: _lessonPlace,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _lessonPlace = value);
              },
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('Does the learner attend school?'),
              style: questionStyle,
            ),
            _buildOptionGroup(
              options: const [
                'Adult',
                'University',
                'High school',
                'Middle school',
                'Primary school',
                'Preschool',
              ],
              groupValue: _studentType,
              onChanged: (value) => setState(() => _studentType = value),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('What is your goal for taking lessons?'),
              style: questionStyle,
            ),
            _buildOptionGroup(
              options: const [
                'Business English',
                'Speaking practice',
                'School support',
                'YDS',
                'IELTS',
                'TOEFL',
                'PTE',
                'Other',
              ],
              groupValue: _goal,
              onChanged: (value) => setState(() => _goal = value),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('What level?'), style: questionStyle),
            _buildOptionGroup(
              options: const [
                'Beginner (A1)',
                'Elementary (A2)',
                'Intermediate (B1)',
                'Upper-intermediate (B2)',
                'Advanced (C1)',
                'Proficient (C2)',
              ],
              groupValue: _level,
              onChanged: (value) => setState(() => _level = value),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('How often?'), style: questionStyle),
            _buildOptionGroup(
              options: const [
                '3 or more per week',
                'Twice a week',
                'Once a week',
                'Other',
              ],
              groupValue: _frequency,
              onChanged: (value) => setState(() => _frequency = value),
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(
                'What should the instructor know or pay attention to?',
              ),
              style: questionStyle,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppStrings.t(
                  'Example: Weekday evenings work. Focused on speaking practice. Goal: YDS...',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('When would you like to start?'),
              style: questionStyle,
            ),
            _buildOptionGroup(
              options: const [
                'At a specific time (within 3 weeks)',
                'Within 2 months',
                'Within 6 months',
                'I just want information',
              ],
              groupValue: _when,
              onChanged: (value) => setState(() => _when = value),
            ),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('Your contact details'), style: questionStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: AppStrings.t('Full name'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppStrings.t('Phone (WhatsApp)'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppStrings.t('Email (optional)'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        );
      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('All set!'), style: questionStyle),
            const SizedBox(height: 8),
            Text(AppStrings.t('You can send your details to us via WhatsApp.')),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SelectableText(
                _buildMessage(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<PublicSettings?>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        final phone = snapshot.data?.whatsappLeadPhone ?? '';
        final hasPlan = widget.plan != null;
        final selectedLabel = hasPlan
            ? '${widget.plan!.title} - ${widget.plan!.lessons}'
            : AppStrings.t('(Not selected)');
        final progress =
            !hasPlan || _totalSteps <= 1 ? 0.0 : _stepIndex / (_totalSteps - 1);

        final borderRadius = widget.inline
            ? BorderRadius.circular(18)
            : const BorderRadius.vertical(top: Radius.circular(18));
        final decoration = BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: borderRadius,
          border: Border.all(
            color: AppColors.brandDeep.withOpacity(0.10),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 52,
              offset: const Offset(0, 18),
            ),
          ],
        );

        Widget progressBar() {
          return ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.brandDeep.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDeep],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        Widget emptyState() {
          if (!hasPlan) {
            return Column(
              key: const ValueKey('_plan_flow_empty'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('Select a package to continue'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.t(
                    'Choose a package above and click "Start" to continue.',
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniStepRow(
                        index: 1,
                        label: AppStrings.t('Choose Your Plan'),
                      ),
                      const SizedBox(height: 10),
                      _MiniStepRow(
                        index: 2,
                        label: AppStrings.t('Fill out the contact form'),
                      ),
                      const SizedBox(height: 10),
                      _MiniStepRow(
                        index: 3,
                        label: AppStrings.t('Send via WhatsApp'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        }

        Widget formState() {
          if (!hasPlan) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepContent(),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (_stepIndex > 0)
                      OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: Text(AppStrings.t('Back')),
                      ),
                    ElevatedButton(
                      onPressed: _stepIndex == _totalSteps - 1
                          ? (phone.isEmpty ? null : () => _sendWhatsApp(phone))
                          : _next,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: Text(
                        _stepIndex == _totalSteps - 1
                            ? AppStrings.t('Send via WhatsApp')
                            : AppStrings.t('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        Widget content() {
          return Column(
            key: ValueKey(hasPlan ? '_plan_flow_form' : '_plan_flow_empty'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.t('Selected package')}: $selectedLabel',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              progressBar(),
              if (phone.isEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE4E2)),
                  ),
                  child: Text(
                    AppStrings.t(
                      'WhatsApp number is not set. Add WHATSAPP_LEAD_PHONE=90xxxxxxxxxx to .env.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!hasPlan) emptyState() else formState(),
            ],
          );
        }

        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: decoration,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.inline) ...[
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: content(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (widget.inline) {
      return body;
    }
    return SafeArea(child: body);
  }
}

class _MiniStepRow extends StatelessWidget {
  const _MiniStepRow({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({super.key, required this.reviews});

  final List<TestimonialItem> reviews;

  @override
  Widget build(BuildContext context) {
    final items = reviews.isNotEmpty
        ? reviews
            .map(
              (review) => _ReviewCardData(
                name: review.name,
                title: review.designation.isNotEmpty
                    ? review.designation
                    : AppStrings.t('Student'),
                rating: review.rating.round().clamp(1, 5),
                comment: review.comment,
              ),
            )
            .toList()
        : const [
            _ReviewCardData(
              name: 'Kerem Özer',
              title: 'Öğrenci',
              rating: 5,
              comment:
                  'İlk dersten itibaren konuşma pratiği yaptık. Çok hızlı ilerledim.',
            ),
            _ReviewCardData(
              name: 'Erhan Keser',
              title: 'Öğrenci',
              rating: 5,
              comment:
                  'Eğitmenim hedefime göre ders planı yaptı. Şimdi özgüvenim arttı.',
            ),
            _ReviewCardData(
              name: 'Orhan Dalkılıç',
              title: 'Öğrenci',
              rating: 5,
              comment:
                  'Esnek saatler ve düzenli geri bildirimlerle gerçekten sonuç aldım.',
            ),
          ];

    return _Section(
      eyebrow: AppStrings.t('Read Our Reviews!'),
      title: AppStrings.t('Real reviews, real progress'),
      background: const Color(0xFF0D5B90),
      titleColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('Shared from lesson experiences'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children:
                  items.map((review) => _ReviewCard(review: review)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class JourneySection extends StatelessWidget {
  const JourneySection({super.key, this.about});

  final SectionData? about;

  @override
  Widget build(BuildContext context) {
    final content = about?.content ?? const <String, dynamic>{};
    String readText(String key, String fallback) {
      final raw = content[key];
      if (raw == null) return fallback;
      final cleaned = raw.toString().replaceAll(RegExp('<[^>]*>'), '').trim();
      return cleaned.isEmpty ? fallback : cleaned;
    }

    final eyebrow = readText('short_title', AppStrings.t('Öğrenim yolu'));
    final title = readText(
      'title',
      AppStrings.t('Özgüvenli İngilizceye giden net bir yol'),
    );
    final steps = [
      _JourneyStep(
        title: AppStrings.t('Hedefini belirle'),
        description: AppStrings.t('What is your goal for taking lessons?'),
        icon: Icons.flag,
      ),
      _JourneyStep(
        title: AppStrings.t('Eğitmeninle tanış'),
        description: AppStrings.t(
          'Choose your favorite instructor and plan your lesson',
        ),
        icon: Icons.people_alt,
      ),
      _JourneyStep(
        title: AppStrings.t('İlerlemeni takip et'),
        description: AppStrings.t('Manage packages and track your progress'),
        icon: Icons.trending_up,
      ),
    ];

    return _Section(
      eyebrow: eyebrow,
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(
                'Seni adım adım yönlendiriyoruz: sade bir plan, destekleyici bir koç ve ölçülebilir ilerleme.',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            _CheckPill(text: AppStrings.t('Size özel plan ve canlı dersler')),
            _CheckPill(
              text: AppStrings.t('Seviyeye uygun içerik ve geri bildirim'),
            ),
            _CheckPill(
              text: AppStrings.t('Esnek program ve raporlanabilir ilerleme'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: steps.map((step) => _JourneyCard(step: step)).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text(AppStrings.t('Hemen Basla')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CorporateSection extends StatelessWidget {
  const CorporateSection({super.key, required this.onNavTap, this.banner});

  final ValueChanged<String> onNavTap;
  final SectionData? banner;

  @override
  Widget build(BuildContext context) {
    final content = banner?.content ?? const <String, dynamic>{};
    final global = banner?.global ?? const <String, dynamic>{};
    String readText(String key, String fallback) {
      final raw = content[key];
      if (raw == null) return fallback;
      final cleaned = raw.toString().replaceAll(RegExp('<[^>]*>'), '').trim();
      return cleaned.isEmpty ? fallback : cleaned;
    }

    final title = readText(
      'title',
      AppStrings.t('Corporate language training for companies'),
    );
    final description = readText(
      'sub_title',
      AppStrings.t(
        'Improve your team\'s skills with online English training programs. Let your company cover the training costs and move forward with a flexible, reportable system.',
      ),
    );
    final rawImage = (global['image'] ?? global['background'] ?? '').toString();
    final image = _resolveImage(rawImage);
    final hasImage = image.isNotEmpty;

    return _Section(
      eyebrow: AppStrings.t('Corporate'),
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFF1F5FF),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(color: AppColors.ink, height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text(AppStrings.t('Free Trial Lesson')),
                  ),
                  ElevatedButton(
                    onPressed: () => onNavTap('corporate'),
                    child: Text(AppStrings.t('Submit your company')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.network(
                        image,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/web/h2_banner_img.png',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/web/h2_banner_img.png',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructorCtaSection extends StatelessWidget {
  const InstructorCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFCE9C0), Color(0xFFFFF4DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: AppStrings.t('Become Instructor')),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(
              'Join our platform as an instructor, teach online, and manage your time freely. Track your journey with a modern panel and earning opportunities.',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 12),
          _CheckPill(text: AppStrings.t('Save time')),
          _CheckPill(text: AppStrings.t('Location freedom')),
          _CheckPill(text: AppStrings.t('Earning opportunity')),
          _CheckPill(text: AppStrings.t('Modern interface')),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: Text(AppStrings.t('Become Instructor')),
          ),
        ],
      ),
    );
  }
}

class AppDownloadSection extends StatelessWidget {
  const AppDownloadSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _Section(
      eyebrow: AppStrings.t('Mobile App'),
      title: AppStrings.t(
        'Download our app and start your English journey today!',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.brandDeep,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t(
                  'Live lessons, instructor selection, package management, and notifications at your fingertips.',
                ),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              _AppBullet(
                text: AppStrings.t(
                  'Stay connected with live lessons and notifications',
                ),
              ),
              _AppBullet(
                text: AppStrings.t(
                  'Pick your favorite instructor and schedule a trial lesson instantly',
                ),
              ),
              _AppBullet(
                text: AppStrings.t('Manage packages and track your progress'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: const [
                  _StoreBadge(text: 'App Store'),
                  _StoreBadge(text: 'Google Play'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key, required this.onNavTap});

  final ValueChanged<String> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandDeep,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.school, color: AppColors.brandDeep, size: 16),
              ),
              SizedBox(width: 8),
              Text(
                'lingufranca',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t('Dil öğrenmenin en pratik yolu.'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _FooterLink(
                label: AppStrings.t('Home'),
                onTap: () => onNavTap('home'),
              ),
              _FooterLink(
                label: AppStrings.t('Packages'),
                onTap: () => onNavTap('packages'),
              ),
              _FooterLink(
                label: AppStrings.t('Blog'),
                onTap: () => onNavTap('blog'),
              ),
              _FooterLink(
                label: AppStrings.t('Contact Us'),
                onTap: () => onNavTap('contact'),
              ),
              _FooterLink(
                label: AppStrings.t('Instructors'),
                onTap: () => onNavTap('instructors'),
              ),
              _FooterLink(
                label: AppStrings.t('Terms of Use'),
                onTap: () => onNavTap('terms'),
              ),
              _FooterLink(
                label: AppStrings.t('Privacy Policy'),
                onTap: () => onNavTap('privacy'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              _SocialIcon(icon: Icons.facebook),
              SizedBox(width: 8),
              _SocialIcon(icon: Icons.linked_camera),
              SizedBox(width: 8),
              _SocialIcon(icon: Icons.play_circle),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.t('Payment Method'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: const [
              _Tag(text: 'iyzico'),
              _Tag(text: 'VISA'),
              _Tag(text: 'Mastercard'),
              _Tag(text: 'TROY'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2010-2024 lingufranca.com',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white24,
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

class SliderSection extends StatelessWidget {
  const SliderSection({super.key, this.slider});

  final SectionData? slider;

  @override
  Widget build(BuildContext context) {
    final content = slider?.content ?? const <String, dynamic>{};
    final rawItems = content['items'];
    final items = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(item);
        }
      }
    }
    if (items.isEmpty && content.isNotEmpty) {
      items.add(Map<String, dynamic>.from(content));
    }
    if (items.isEmpty) {
      items.add({
        'title': AppStrings.t('Start your Learning Journey Today!'),
        'subtitle': AppStrings.t(
          'Discover a World of Knowledge and Skills at Your Fingertips - Unlock Your Potential and Achieve Your Dreams with Our Comprehensive Learning Resources!',
        ),
        'button_text': AppStrings.t('Get Started'),
      });
    }

    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          String readText(String key, String fallback) {
            final raw = item[key];
            if (raw == null) return fallback;
            final cleaned =
                raw.toString().replaceAll(RegExp('<[^>]*>'), '').trim();
            return cleaned.isEmpty ? fallback : cleaned;
          }

          final title = readText(
            'title',
            AppStrings.t('Start your Learning Journey Today!'),
          );
          final subtitle = readText(
            'sub_title',
            AppStrings.t(
              'Discover a World of Knowledge and Skills at Your Fingertips - Unlock Your Potential and Achieve Your Dreams with Our Comprehensive Learning Resources!',
            ),
          );
          final buttonText = readText(
            'action_button_text',
            AppStrings.t('Get Started'),
          );
          final image = _resolveImage(
            (item['image'] ?? item['banner_image'] ?? item['thumbnail'])
                ?.toString(),
          );

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F5B92), Color(0xFF0B3E63)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  if (image.isNotEmpty)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  Container(color: Colors.black.withOpacity(0.35)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: Text(buttonText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrendingCategoriesSection extends StatelessWidget {
  const TrendingCategoriesSection({super.key, required this.categories});

  final List<TrendingCategory> categories;

  @override
  Widget build(BuildContext context) {
    final items = categories.isNotEmpty
        ? categories
        : [
            TrendingCategory(
              id: 1,
              slug: 'general-english',
              name: AppStrings.t('General English'),
              icon: null,
              subCategories: const [],
            ),
            TrendingCategory(
              id: 2,
              slug: 'business',
              name: AppStrings.t('Business English'),
              icon: null,
              subCategories: const [],
            ),
            TrendingCategory(
              id: 3,
              slug: 'speaking',
              name: AppStrings.t('Speaking Practice'),
              icon: null,
              subCategories: const [],
            ),
          ];

    return _Section(
      eyebrow: AppStrings.t('Trending Categories'),
      title: AppStrings.t('Top Category We Have'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: items
              .map((category) => _TrendingCategoryCard(category: category))
              .toList(),
        ),
      ),
    );
  }
}

class _TrendingCategoryCard extends StatelessWidget {
  const _TrendingCategoryCard({required this.category});

  final TrendingCategory category;

  @override
  Widget build(BuildContext context) {
    final iconUrl = _resolveImage(category.icon);
    final subCategories = category.subCategories;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconUrl.isNotEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brand.withOpacity(0.12),
                  child: ClipOval(
                    child: Image.network(
                      iconUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, __, ___) => SizedBox(
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.category,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ),
                )
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brand.withOpacity(0.12),
                  child: const Icon(Icons.category, color: AppColors.brand),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (subCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: subCategories
                  .map(
                    (sub) => Chip(
                      label: Text(
                        '${sub.name} (${sub.courseCount})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.brand.withOpacity(0.12),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class BrandStripSection extends StatelessWidget {
  const BrandStripSection({super.key, required this.brands});

  final List<BrandItem> brands;

  @override
  Widget build(BuildContext context) {
    final items = brands.isNotEmpty
        ? brands
        : [
            BrandItem(name: 'iyzico', imageUrl: '', url: ''),
            BrandItem(name: 'visa', imageUrl: '', url: ''),
            BrandItem(name: 'troy', imageUrl: '', url: ''),
          ];

    return _Section(
      eyebrow: AppStrings.t('Brands Section'),
      title: AppStrings.t('Brands we work with'),
      child: SizedBox(
        height: 70,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final brand = items[index];
            final imageUrl = _resolveImage(brand.imageUrl);
            return Container(
              width: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          brand.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        brand.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: items.length,
        ),
      ),
    );
  }
}

class NewsletterSection extends StatefulWidget {
  const NewsletterSection({super.key, this.newsletter});

  final SectionData? newsletter;

  @override
  State<NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<NewsletterSection> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Email is required'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await PublicRepository().submitNewsletter(email: email);
      if (!mounted) return;
      _emailController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.t('Subscribed at'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Something went wrong'))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.newsletter?.content ?? const <String, dynamic>{};
    String readText(String key, String fallback) {
      final raw = content[key];
      if (raw == null) return fallback;
      final cleaned = raw.toString().replaceAll(RegExp('<[^>]*>'), '').trim();
      return cleaned.isEmpty ? fallback : cleaned;
    }

    final title = readText(
      'title',
      AppStrings.t('Want to stay informed about'),
    );
    final subtitle = readText(
      'sub_title',
      AppStrings.t('new courses and study'),
    );
    final buttonLabel = readText(
      'action_button_text',
      AppStrings.t('Subscribe Now'),
    );

    return _Section(
      eyebrow: AppStrings.t('Newsletter Section'),
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: AppStrings.t('Type your email'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaqSection extends StatelessWidget {
  const FaqSection({super.key, this.section, required this.future});

  final SectionData? section;
  final Future<List<FaqItem>>? future;

  @override
  Widget build(BuildContext context) {
    final content = section?.content ?? const <String, dynamic>{};
    String readText(String key, String fallback) {
      final raw = content[key];
      if (raw == null) return fallback;
      final cleaned = raw.toString().replaceAll(RegExp('<[^>]*>'), '').trim();
      return cleaned.isEmpty ? fallback : cleaned;
    }

    final title = readText('title', AppStrings.t('FAQs'));

    return _Section(
      eyebrow: AppStrings.t('Frequently Asked Questions'),
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FutureBuilder<List<FaqItem>>(
          future: future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <FaqItem>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (items.isEmpty) {
              return Text(AppStrings.t('No data found'));
            }
            return Column(
              children: items
                  .map(
                    (faq) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        title: Text(
                          faq.question,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          Text(
                            faq.answer,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.background,
    this.titleColor,
  });

  final String eyebrow;
  final String title;
  final Widget child;
  final Color? background;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _Eyebrow(
              text: eyebrow,
              color: titleColor ?? AppColors.brand,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor ?? AppColors.ink,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? AppColors.brand,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.ghost = false});

  final String text;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final background = ghost ? Colors.transparent : AppColors.brand;
    final textColor = ghost ? Colors.white : AppColors.ink;
    final border = ghost ? Border.all(color: Colors.white24) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: border,
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.controller,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class _StatItemData {
  const _StatItemData({required this.label, required this.value});

  final String label;
  final String value;
}

class _InstaCard extends StatelessWidget {
  const _InstaCard({this.index, this.instructor, this.onTap});

  final int? index;
  final FeaturedInstructor? instructor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final assets = const [
      'assets/web/course_thumb01.jpg',
      'assets/web/course_thumb02.jpg',
      'assets/web/course_thumb03.jpg',
      'assets/web/h2_instructor01.png',
      'assets/web/h2_instructor02.png',
      'assets/web/h2_instructor03.png',
    ];
    final asset = assets[(index ?? 0) % assets.length];
    final imageUrl = _resolveImage(instructor?.imageUrl);
    final hasNetwork = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: hasNetwork
                  ? Image.network(
                      imageUrl,
                      height: 190,
                      width: 160,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, __, ___) => Image.asset(
                        asset,
                        height: 190,
                        width: 160,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      asset,
                      height: 190,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brand,
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructorCardData {
  const _InstructorCardData({
    required this.name,
    required this.title,
    required this.image,
    this.isNetwork = false,
    this.rating = 0,
    this.courseCount = 0,
  });

  final String name;
  final String title;
  final String image;
  final bool isNetwork;
  final double rating;
  final int courseCount;
}

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({required this.item});

  final _InstructorCardData item;

  @override
  Widget build(BuildContext context) {
    final fallbackAsset = 'assets/web/h2_instructor01.png';
    final hasImage = item.image.isNotEmpty;

    Widget avatarChild() {
      if (!hasImage) {
        return Image.asset(
          fallbackAsset,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        );
      }

      if (!item.isNetwork) {
        return Image.asset(
          item.image,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        );
      }

      return Image.network(
        item.image,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFF1F5F9),
            child: ClipOval(child: avatarChild()),
          ),
          const SizedBox(height: 10),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(item.title, style: const TextStyle(color: AppColors.muted)),
          if (item.rating > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${item.rating.toStringAsFixed(1)} / 5 • ${item.courseCount} ${AppStrings.t('Courses')}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              _Tag(text: AppStrings.t('Speaking Lessons')),
              _Tag(text: AppStrings.t('General English')),
              _Tag(text: AppStrings.t('Business English')),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const StudentInstructorsScreen(standalone: true),
                  ),
                );
              },
              child: Text(AppStrings.t('Schedule Lesson')),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlanTone { sunset, sky, slate }

_PlanTone _planToneForIndex(int index) {
  switch (index % 3) {
    case 0:
      return _PlanTone.sunset;
    case 1:
      return _PlanTone.sky;
    default:
      return _PlanTone.slate;
  }
}

class _PlanData {
  const _PlanData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lessons,
    required this.highlight,
    required this.tone,
    this.badge,
    this.badgeSecondary,
    this.featured = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String lessons;
  final String highlight;
  final _PlanTone tone;
  final String? badge;
  final String? badgeSecondary;
  final bool featured;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, this.selected = false, this.onStart});

  final _PlanData plan;
  final bool selected;
  final VoidCallback? onStart;

  Widget _gradientButton({
    required String label,
    required List<Color> colors,
    required VoidCallback? onTap,
    Color? borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(999),
            border: borderColor != null ? Border.all(color: borderColor) : null,
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLarge(BuildContext context) {
    final featuredAccent = const Color(0xFF38BDF8);
    final warmAccent = const Color(0xFFF59E0B);
    final stoneAccent = const Color(0xFFCBD5E1);

    Color accent;
    List<Color> cardBg;
    List<Color> lessonBg;
    Color baseBorderColor;
    Color topBarColor;

    if (plan.featured) {
      accent = featuredAccent;
      cardBg = const [Color(0xFFF4FBFF), Color(0xFFE7F2FF)];
      lessonBg = const [Color(0xFF7FD0FF), Color(0xFF2F9CFF)];
      baseBorderColor = const Color(0xFF93C5FD);
      topBarColor = featuredAccent;
    } else {
      switch (plan.tone) {
        case _PlanTone.sunset:
          accent = warmAccent;
          cardBg = const [Color(0xFFFFF4E6), Color(0xFFFEF2D6)];
          lessonBg = const [Color(0xFFFFCC8A), Color(0xFFF59E0B)];
          baseBorderColor = const Color(0xFFF8D59A);
          topBarColor = warmAccent;
          break;
        case _PlanTone.sky:
          // Web spec: base card uses the "default" blue-ish background and an
          // orange top bar. Keep accent orange (selection) to match.
          accent = warmAccent;
          cardBg = const [Color(0xFFFDFDFF), Color(0xFFF1F6FF)];
          lessonBg = const [Color(0xFFFFCC8A), Color(0xFFF59E0B)];
          baseBorderColor = const Color(0xFFDBE7F5);
          topBarColor = warmAccent;
          break;
        case _PlanTone.slate:
          accent = stoneAccent;
          cardBg = const [Color(0xFFF6F7FB), Color(0xFFE6EBF3)];
          lessonBg = const [Color(0xFFD9DEE6), Color(0xFFBFC7D2)];
          baseBorderColor = stoneAccent;
          topBarColor = stoneAccent;
          break;
      }
    }

    final borderColor = selected ? accent : baseBorderColor;
    final offsetY = plan.featured ? -12.0 : 0.0;

    final card = Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardBg,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF0F172A,
                ).withOpacity(plan.featured ? 0.25 : 0.15),
                blurRadius: plan.featured ? 70 : 50,
                offset: Offset(0, plan.featured ? 30 : 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (plan.badge != null || plan.badgeSecondary != null)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (plan.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: plan.featured
                              ? const Color(0xFF0EA5E9)
                              : warmAccent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: (plan.featured
                                      ? const Color(0xFF0EA5E9)
                                      : warmAccent)
                                  .withOpacity(plan.featured ? 0.30 : 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          AppStrings.t(plan.badge!).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.55,
                          ),
                        ),
                      ),
                    if (plan.badgeSecondary != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: warmAccent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: warmAccent.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          AppStrings.t(plan.badgeSecondary!).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.55,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Text(
                plan.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.44,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plan.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBE7F5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DiagonalStripePainter(
                            color: const Color(0x2E94A3B8),
                            spacing: 8,
                            thickness: 2,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x3394A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            Transform.rotate(
                              angle: math.pi / 4,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: plan.featured
                                        ? featuredAccent
                                        : (plan.tone == _PlanTone.slate
                                            ? stoneAccent
                                            : warmAccent),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _gradientButton(
                              label: plan.highlight,
                              colors: const [
                                Color(0xFF6CC3FF),
                                Color(0xFF2B8EF1),
                              ],
                              borderColor: const Color(0xFF2B8EF1),
                              onTap: onStart,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: lessonBg,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.40)),
                ),
                child: Text(
                  plan.lessons.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.44,
                    color:
                        plan.featured ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: topBarColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
          ),
        ),
      ],
    );

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStart,
          borderRadius: BorderRadius.circular(26),
          child: card,
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final warmAccent = const Color(0xFFF59E0B);
    final skyAccent = const Color(0xFF3B82F6);
    final slateAccent = const Color(0xFF64748B);

    Color accent;
    Color background;

    if (plan.featured) {
      accent = skyAccent;
      background = const Color(0xFFEAF5FF);
    } else {
      switch (plan.tone) {
        case _PlanTone.sunset:
          accent = warmAccent;
          background = const Color(0xFFFFF7E6);
          break;
        case _PlanTone.sky:
          accent = skyAccent;
          background = const Color(0xFFF0F9FF);
          break;
        case _PlanTone.slate:
          accent = slateAccent;
          background = const Color(0xFFF1F5F9);
          break;
      }
    }

    final borderColor = selected ? accent : accent.withOpacity(0.25);

    Widget chip(String text, {Color? color, Color? textColor}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color ?? accent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          AppStrings.t(text),
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    final chips = <Widget>[
      if (plan.badge != null) chip(plan.badge!, color: accent),
      if (plan.badgeSecondary != null)
        chip(
          plan.badgeSecondary!,
          color: warmAccent,
          textColor: const Color(0xFF1F2937),
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chips.isNotEmpty) ...[
                  Wrap(spacing: 8, runSpacing: 6, children: chips),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.emoji_events, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              fontSize: 12,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: onStart,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        plan.highlight,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        plan.lessons,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 230;
        return compact ? _buildCompact(context) : _buildLarge(context);
      },
    );
  }
}

class _DiagonalStripePainter extends CustomPainter {
  _DiagonalStripePainter({
    required this.color,
    required this.spacing,
    required this.thickness,
  });

  final Color color;
  final double spacing;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    // Draw 45-degree diagonal stripes across the panel, similar to the web
    // repeating-linear-gradient(135deg, ...).
    final max = size.width + size.height;
    for (double i = -size.height; i < max; i += spacing) {
      final start = Offset(i, 0);
      final end = Offset(i + size.height, size.height);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.thickness != thickness;
  }
}

class _ReviewCardData {
  const _ReviewCardData({
    required this.name,
    required this.title,
    required this.comment,
    required this.rating,
  });

  final String name;
  final String title;
  final String comment;
  final int rating;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final _ReviewCardData review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              review.rating,
              (index) =>
                  const Icon(Icons.star, color: Color(0xFFF6A105), size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Text(review.comment, style: const TextStyle(color: AppColors.ink)),
          const SizedBox(height: 12),
          Text(
            review.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            review.title,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep {
  const _JourneyStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.step});

  final _JourneyStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brand,
            child: Icon(step.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          Text(step.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            step.description,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CheckPill extends StatelessWidget {
  const _CheckPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.brand, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _AppBullet extends StatelessWidget {
  const _AppBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
