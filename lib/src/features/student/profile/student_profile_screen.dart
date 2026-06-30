import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/auth_repository.dart';
import '../../profile/profile_repository.dart';
import '../library/student_library_screen.dart';
import '../reports/student_reports_screen.dart';
import '../support/student_support_screen.dart';
import '../guide/student_guide_screen.dart';
import '../settings/student_settings_screen.dart';
import '../settings/student_language_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late final Future<UserProfile?> _futureProfile =
      ProfileRepository().fetchProfile();

  Future<void> _logout() async {
    try {
      await AuthRepository().logout();
    } catch (_) {}
    await SecureStorage.clearAll();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _futureProfile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.name.isNotEmpty == true
            ? profile!.name
            : AppStrings.t('User Name');
        final email = profile?.email.isNotEmpty == true
            ? profile!.email
            : AppStrings.t('User Email');
        final avatarUrl = profile?.image ?? '';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoader(message: AppStrings.t('Loading'));
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: AppStrings.t('Something went wrong'),
            retryLabel: AppStrings.t('Try Again'),
            onRetry: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentProfileScreen(),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpace.xl),
          children: [
            AnimatedPageEntrance(
              child: _ProfileHero(
                name: name,
                email: email,
                avatarUrl: avatarUrl,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            StaggeredReveal(
              children: [
                _ProfileTile(
                  title: AppStrings.t('Profile Settings'),
                  icon: Icons.settings,
                  gradient: AppGradients.brand,
                  onTap: () => _open(context, const StudentSettingsScreen()),
                ),
                const SizedBox(height: AppSpace.md),
                _ProfileTile(
                  title: AppStrings.t('Language and Currency'),
                  icon: Icons.language,
                  gradient: AppGradients.sky,
                  iconColor: AppPalette.info,
                  onTap: () => _open(context, const StudentLanguageScreen()),
                ),
                const SizedBox(height: AppSpace.md),
                _ProfileTile(
                  title: AppStrings.t('Library'),
                  icon: Icons.menu_book,
                  gradient: AppGradients.violet,
                  onTap: () => _open(context, const StudentLibraryScreen()),
                ),
                const SizedBox(height: AppSpace.md),
                _ProfileTile(
                  title: AppStrings.t('My Reports'),
                  icon: Icons.bar_chart,
                  gradient: AppGradients.success,
                  onTap: () => _open(context, const StudentReportsScreen()),
                ),
                const SizedBox(height: AppSpace.md),
                _ProfileTile(
                  title: AppStrings.t('Support'),
                  icon: Icons.support_agent,
                  gradient: AppGradients.gold,
                  onTap: () => _open(context, const StudentSupportScreen()),
                ),
                const SizedBox(height: AppSpace.md),
                _ProfileTile(
                  title: AppStrings.t('User Guide'),
                  icon: Icons.help_outline,
                  gradient: AppGradients.streak,
                  onTap: () => _open(context, const StudentGuideScreen()),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              label: AppStrings.t('Logout'),
              tone: AppButtonTone.danger,
              icon: Icons.logout,
              onPressed: _logout,
            ),
          ],
        );
      },
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

/// Gradyan kahraman kart: avatar + ad + e-posta.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  final String name;
  final String email;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      gradient: AppGradients.hero,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigasyon satırı: gradyan ikon çipi + başlık + chevron.
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradient,
    this.iconColor = Colors.white,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
