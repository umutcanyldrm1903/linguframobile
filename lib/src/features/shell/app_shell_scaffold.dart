import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';

class AppShellDestination {
  const AppShellDestination({
    required this.title,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
  });

  final String title;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  /// Rozet sayacı (örn. okunmamış mesaj/bildirim). null/0 ise gizli.
  final int? badge;
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.pages,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.roleLabel,
    required this.accentColor,
    this.onOpenAppHome,
  }) : assert(destinations.length == pages.length);

  final int currentIndex;
  final List<AppShellDestination> destinations;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onLogout;
  final String roleLabel;
  final Color accentColor;
  final VoidCallback? onOpenAppHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = destinations[currentIndex];
    // extendBody:true ile gövde, yüzen alt menünün arkasına uzanır. Sayfa
    // içeriğinin son öğesi (örn. Çıkış butonu) menünün altında kalmasın diye
    // alt menü yüksekliği kadar boşluk bırak.
    final navClearance = MediaQuery.of(context).padding.bottom + 84;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: 0.16),
              AppColors.background,
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -20,
              child: _GlowOrb(color: accentColor.withValues(alpha: 0.14)),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: _GlowOrb(color: AppColors.brand.withValues(alpha: 0.12)),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: _ShellHeader(
                      title: destination.title,
                      roleLabel: roleLabel,
                      accentColor: accentColor,
                      onOpenAppHome: onOpenAppHome,
                      onLogout: onLogout,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          child: ColoredBox(
                            color: theme.scaffoldBackgroundColor,
                            child: AnimatedSwitcher(
                              duration: AppMotion.normal,
                              switchInCurve: AppMotion.curve,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: AppMotion.curve,
                                );
                                return FadeTransition(
                                  opacity: curved,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.03, 0),
                                      end: Offset.zero,
                                    ).animate(curved),
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(currentIndex),
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(bottom: navClearance),
                                  child: pages[currentIndex],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 6, 10, 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: accentColor.withValues(alpha: 0.14),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontSize: 10.5,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w800
                      : FontWeight.w700,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.ink
                      : AppColors.muted,
                );
              }),
            ),
            child: NavigationBar(
              height: 64,
              elevation: 0,
              selectedIndex: currentIndex,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: _maybeBadge(item.badge, Icon(item.icon)),
                    selectedIcon: _maybeBadge(
                        item.badge, Icon(item.selectedIcon ?? item.icon)),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _maybeBadge(int? count, Widget child) {
  if (count == null || count <= 0) return child;
  return Badge(
    label: Text(count > 99 ? '99+' : '$count'),
    backgroundColor: AppColors.brand,
    child: child,
  );
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.title,
    required this.roleLabel,
    required this.accentColor,
    required this.onLogout,
    this.onOpenAppHome,
  });

  final String title;
  final String roleLabel;
  final Color accentColor;
  final Future<void> Function() onLogout;
  final VoidCallback? onOpenAppHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor, AppColors.brandDeep],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      roleLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'LinguFranca',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: AppStrings.t('Profile'),
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) async {
                if (value == 'app-home') {
                  onOpenAppHome?.call();
                  return;
                }
                if (value == 'logout') {
                  await onLogout();
                }
              },
              itemBuilder: (context) => [
                if (onOpenAppHome != null)
                  PopupMenuItem<String>(
                    value: 'app-home',
                    child: Row(
                      children: [
                        const Icon(Icons.home_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(AppStrings.t('Ana sayfaya dön')),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(AppStrings.t('Logout')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
