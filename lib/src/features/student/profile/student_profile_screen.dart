import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/auth_repository.dart';
import '../../profile/profile_repository.dart';
import '../library/student_library_screen.dart';
import '../wishlist/student_wishlist_screen.dart';
import '../cart/student_cart_screen.dart';
import '../orders/student_orders_screen.dart';
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
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.brand.withOpacity(0.2),
                    child: avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.prefer,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 60,
                                height: 60,
                                child: Icon(Icons.person, color: AppColors.brand),
                              ),
                            ),
                          )
                        : const Icon(Icons.person, color: AppColors.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(email,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileTile(
              title: AppStrings.t('Profile Settings'),
              icon: Icons.settings,
              onTap: () => _open(context, const StudentSettingsScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('Language and Currency'),
              icon: Icons.language,
              onTap: () => _open(context, const StudentLanguageScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('Library'),
              icon: Icons.menu_book,
              onTap: () => _open(context, const StudentLibraryScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('Wishlist'),
              icon: Icons.favorite,
              onTap: () => _open(context, const StudentWishlistScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('Cart'),
              icon: Icons.shopping_cart,
              onTap: () => _open(context, const StudentCartScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('Orders'),
              icon: Icons.receipt_long,
              onTap: () => _open(context, const StudentOrdersScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('My Reports'),
              icon: Icons.bar_chart,
              onTap: () => _open(context, const StudentReportsScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('Support'),
              icon: Icons.support_agent,
              onTap: () => _open(context, const StudentSupportScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('User Guide'),
              icon: Icons.help_outline,
              onTap: () => _open(context, const StudentGuideScreen()),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              title: AppStrings.t('Logout'),
              icon: Icons.logout,
              onTap: _logout,
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            Icon(icon, color: AppColors.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
