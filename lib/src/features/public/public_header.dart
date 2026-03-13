import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../student/instructors/student_instructors_screen.dart';
import 'public_repository.dart';

class PublicHeader extends StatefulWidget {
  const PublicHeader({super.key, this.onNavTap});

  final ValueChanged<String>? onNavTap;

  @override
  State<PublicHeader> createState() => _PublicHeaderState();
}

class _PublicHeaderState extends State<PublicHeader> {
  late final Future<_HeaderPayload> _future = _HeaderPayload.load();

  void _handleNav(BuildContext context, String id) {
    if (widget.onNavTap != null) {
      widget.onNavTap!(id);
      return;
    }
    switch (id) {
      case 'home':
        Navigator.pushNamed(context, '/home');
        break;
      case 'packages':
        Navigator.pushNamed(context, '/home', arguments: 'packages');
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
      case 'corporate':
        Navigator.pushNamed(context, '/corporate');
        break;
      case 'placement':
        Navigator.pushNamed(context, '/placement-test');
        break;
      case 'terms':
        Navigator.pushNamed(context, '/terms');
        break;
      case 'privacy':
        Navigator.pushNamed(context, '/privacy');
        break;
      case 'instructors':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentInstructorsScreen(standalone: true),
          ),
        );
        break;
    }
  }

  void _showNavMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            children: [
              _MoreItem(
                label: AppStrings.t('Log In'),
                onTap: () => Navigator.pushNamed(context, '/login'),
              ),
              _MoreItem(
                label: AppStrings.t('Sign Up'),
                onTap: () => Navigator.pushNamed(context, '/register'),
              ),
              const Divider(),
              _MoreItem(
                label: AppStrings.t('Home'),
                onTap: () => _handleNav(context, 'home'),
              ),
              _MoreItem(
                label: AppStrings.t('Packages'),
                onTap: () => _handleNav(context, 'packages'),
              ),
              _MoreItem(
                label: AppStrings.t('About Us'),
                onTap: () => _handleNav(context, 'about'),
              ),
              _MoreItem(
                label: AppStrings.t('Blog'),
                onTap: () => _handleNav(context, 'blog'),
              ),
              _MoreItem(
                label: AppStrings.t('Contact Us'),
                onTap: () => _handleNav(context, 'contact'),
              ),
              _MoreItem(
                label: AppStrings.t('Instructors'),
                onTap: () => _handleNav(context, 'instructors'),
              ),
              _MoreItem(
                label: AppStrings.t('Corporate'),
                onTap: () => _handleNav(context, 'corporate'),
              ),
              _MoreItem(
                label: AppStrings.t('2-Minute English Level Test'),
                onTap: () => _handleNav(context, 'placement'),
              ),
              const Divider(),
              _MoreItem(
                label: AppStrings.t('Terms of Use'),
                onTap: () => _handleNav(context, 'terms'),
              ),
              _MoreItem(
                label: AppStrings.t('Privacy Policy'),
                onTap: () => _handleNav(context, 'privacy'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HeaderPayload>(
      future: _future,
      builder: (context, snapshot) {
        final payload = snapshot.data;
        final contact = payload?.contact;
        final socials = payload?.socials ?? const <SocialLinkItem>[];

        final locationLabel =
            _shortLocation(contact?.address) ?? 'Turkey/Istanbul';
        final emailLabel =
            _firstNonEmpty([contact?.emailOne, contact?.emailTwo]) ??
                'contact@lingufranca.com';
        final isCompact = MediaQuery.sizeOf(context).width < 900;

        if (isCompact) {
          final canPop = Navigator.of(context).canPop();
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
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
                    IconButton.filledTonal(
                      onPressed: () {
                        if (canPop) {
                          Navigator.of(context).pop();
                        } else {
                          _handleNav(context, 'home');
                        }
                      },
                      icon: Icon(
                        canPop ? Icons.arrow_back_rounded : Icons.home_rounded,
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
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emailLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                      onPressed: () => _showNavMenu(context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: AppColors.ink,
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

        return Column(
          children: [
            Container(
              color: AppColors.brandDeep,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        locationLabel,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.email, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        emailLabel,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.t('Follow Us On')}:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (socials.isEmpty) ...const [
                        _SocialIcon(icon: Icons.facebook),
                        _SocialIcon(icon: Icons.linked_camera),
                        _SocialIcon(icon: Icons.video_library),
                      ] else
                        ...socials.map(
                          (item) => _SocialIcon(
                            icon: _iconFor(item.icon),
                            onTap: item.url.isNotEmpty
                                ? () => _openUrl(item.url)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.brand,
                        child: const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Lingufranca',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: Text(AppStrings.t('Log In')),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(AppStrings.t('Sign Up')),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => _showNavMenu(context),
                        icon: const Icon(Icons.menu),
                        tooltip: AppStrings.t('Menu'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String? _shortLocation(String? address) {
    if (address == null || address.trim().isEmpty) return null;
    final cleaned = address.split('\n').first.trim();
    if (cleaned.length > 28) {
      return '${cleaned.substring(0, 28)}...';
    }
    return cleaned;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _HeaderPayload {
  const _HeaderPayload({required this.contact, required this.socials});

  final ContactInfo? contact;
  final List<SocialLinkItem> socials;

  static Future<_HeaderPayload> load() async {
    final repo = PublicRepository();
    ContactInfo? contact;
    List<SocialLinkItem> socials = const [];
    try {
      contact = await repo.fetchContactInfo();
    } catch (_) {}
    try {
      socials = await repo.fetchSocialLinks();
    } catch (_) {}
    return _HeaderPayload(contact: contact, socials: socials);
  }
}

IconData _iconFor(String raw) {
  final value = raw.toLowerCase();
  if (value.contains('facebook')) return Icons.facebook;
  if (value.contains('instagram')) return Icons.camera_alt;
  if (value.contains('twitter') || value.contains('x-twitter')) {
    return Icons.alternate_email;
  }
  if (value.contains('linkedin')) return Icons.work;
  if (value.contains('youtube')) return Icons.play_circle_fill;
  if (value.contains('whatsapp')) return Icons.chat;
  if (value.contains('telegram')) return Icons.send;
  return Icons.link;
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color(0xFF155E97),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: Colors.white70),
      ),
    );
  }
}
