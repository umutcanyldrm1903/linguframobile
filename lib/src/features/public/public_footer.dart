import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../student/instructors/student_instructors_screen.dart';
import 'public_repository.dart';

class PublicFooter extends StatefulWidget {
  const PublicFooter({super.key, this.onNavTap});

  final ValueChanged<String>? onNavTap;

  @override
  State<PublicFooter> createState() => _PublicFooterState();
}

class _PublicFooterState extends State<PublicFooter> {
  late final Future<List<SocialLinkItem>> _future =
      PublicRepository().fetchSocialLinks();

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
              builder: (_) => const StudentInstructorsScreen(standalone: true)),
        );
        break;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 900;

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.brandDeep,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LinguFranca',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.t('Contact Us'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CompactFooterButton(
                    label: AppStrings.t('Home'),
                    onTap: () => _handleNav(context, 'home'),
                  ),
                  _CompactFooterButton(
                    label: AppStrings.t('Packages'),
                    onTap: () => _handleNav(context, 'packages'),
                  ),
                  _CompactFooterButton(
                    label: AppStrings.t('Contact Us'),
                    onTap: () => _handleNav(context, 'contact'),
                  ),
                  _CompactFooterButton(
                    label: AppStrings.t('Corporate'),
                    onTap: () => _handleNav(context, 'corporate'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FutureBuilder<List<SocialLinkItem>>(
                future: _future,
                builder: (context, snapshot) {
                  final socials = snapshot.data ?? const <SocialLinkItem>[];
                  final items = socials.isNotEmpty
                      ? socials
                      : const <SocialLinkItem>[
                          SocialLinkItem(icon: 'facebook', url: ''),
                          SocialLinkItem(icon: 'instagram', url: ''),
                          SocialLinkItem(icon: 'youtube', url: ''),
                        ];

                  return Row(
                    children: items.take(4).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: item.url.isNotEmpty
                              ? () => _openUrl(item.url)
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              _iconFor(item.icon),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

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
                  fontWeight: FontWeight.w800,
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
                onTap: () => _handleNav(context, 'home'),
              ),
              _FooterLink(
                label: AppStrings.t('Packages'),
                onTap: () => _handleNav(context, 'packages'),
              ),
              _FooterLink(
                label: AppStrings.t('About Us'),
                onTap: () => _handleNav(context, 'about'),
              ),
              _FooterLink(
                label: AppStrings.t('Blog'),
                onTap: () => _handleNav(context, 'blog'),
              ),
              _FooterLink(
                label: AppStrings.t('Contact Us'),
                onTap: () => _handleNav(context, 'contact'),
              ),
              _FooterLink(
                label: AppStrings.t('Instructors'),
                onTap: () => _handleNav(context, 'instructors'),
              ),
              _FooterLink(
                label: AppStrings.t('Corporate'),
                onTap: () => _handleNav(context, 'corporate'),
              ),
              _FooterLink(
                label: AppStrings.t('Terms of Use'),
                onTap: () => _handleNav(context, 'terms'),
              ),
              _FooterLink(
                label: AppStrings.t('Privacy Policy'),
                onTap: () => _handleNav(context, 'privacy'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<SocialLinkItem>>(
            future: _future,
            builder: (context, snapshot) {
              final socials = snapshot.data ?? const <SocialLinkItem>[];
              final items = socials.isNotEmpty
                  ? socials
                  : const <SocialLinkItem>[
                      SocialLinkItem(icon: 'facebook', url: ''),
                      SocialLinkItem(icon: 'instagram', url: ''),
                      SocialLinkItem(icon: 'youtube', url: ''),
                    ];

              return Row(
                children: items.take(6).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap:
                          item.url.isNotEmpty ? () => _openUrl(item.url) : null,
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          _iconFor(item.icon),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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
          Text(
            '© 2010-2026 lingufranca.com',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CompactFooterButton extends StatelessWidget {
  const _CompactFooterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(label),
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
