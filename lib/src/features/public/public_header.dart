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

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
        final isCompact = MediaQuery.sizeOf(context).width < 430;

        return Column(
          children: [
            if (!isCompact)
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
                        const Icon(
                          Icons.place,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          locationLabel,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: Colors.white70,
                        ),
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
                      if (!isCompact) ...[
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
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
                      ] else ...[
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(width: 4),
                      ],
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

class _NavChip extends StatelessWidget {
  const _NavChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
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
