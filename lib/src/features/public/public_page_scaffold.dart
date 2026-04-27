import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'public_footer.dart';
import 'public_header.dart';

// Keep the app in native-mode across all viewport sizes.
bool isCompactPublicLayout(BuildContext context) => true;

Widget publicAppViewport(
  BuildContext context,
  Widget child, {
  bool expandHeight = false,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final viewportHeight = MediaQuery.sizeOf(context).height;
      final targetPhoneWidth =
          constraints.maxWidth <= 520 ? constraints.maxWidth : 430.0;
      final targetPhoneHeight = expandHeight
          ? (targetPhoneWidth <= 0 ? viewportHeight : targetPhoneWidth * 2.05)
          : viewportHeight;
      final viewportChild = SizedBox(
        width: targetPhoneWidth,
        height: targetPhoneHeight,
        child: child,
      );

      if (constraints.maxWidth <= 520) {
        if (!expandHeight) {
          return child;
        }
        return ColoredBox(
          color: Colors.white,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: viewportChild,
            ),
          ),
        );
      }

      final framedViewport = expandHeight
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: viewportChild,
            )
          : viewportChild;

      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEFF4FF),
              Color(0xFFF7FAFF),
              Color(0xFFF2F7FD),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.74),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandNight.withValues(alpha: 0.08),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: framedViewport,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PublicPageShell extends StatelessWidget {
  const PublicPageShell({
    super.key,
    required this.title,
    required this.breadcrumb,
    required this.children,
    this.description,
    this.icon = Icons.language_rounded,
    this.sectionSpacing,
  });

  final String title;
  final String breadcrumb;
  final String? description;
  final IconData icon;
  final List<Widget> children;
  final double? sectionSpacing;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final spacing = sectionSpacing ?? (compact ? 12 : 16);

    if (compact) {
      return publicAppViewport(
        context,
        ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.paddingOf(context).top + 8,
            0,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            PublicPageHero(
              title: title,
              breadcrumb: breadcrumb,
              description: description,
              icon: icon,
            ),
            SizedBox(height: spacing),
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) SizedBox(height: spacing),
            ],
          ],
        ),
        expandHeight: true,
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const PublicHeader(),
        PublicPageHero(
          title: title,
          breadcrumb: breadcrumb,
          description: description,
          icon: icon,
        ),
        SizedBox(height: spacing),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) SizedBox(height: spacing),
        ],
        SizedBox(height: spacing),
        const PublicFooter(),
      ],
    );
  }
}

class PublicPageHero extends StatelessWidget {
  const PublicPageHero({
    super.key,
    required this.title,
    required this.breadcrumb,
    this.description,
    this.icon = Icons.language_rounded,
  });

  final String title;
  final String breadcrumb;
  final String? description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3D5CFF),
                Color(0xFF2C49E7),
                Color(0xFF2237A7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandDeep.withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  child: const SizedBox(width: 120, height: 120),
                ),
              ),
              Positioned(
                left: -24,
                bottom: -34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.18),
                  ),
                  child: const SizedBox(width: 110, height: 110),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            breadcrumb,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    if (description != null &&
                        description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D5B90),
            Color(0xFF0B466F),
            Color(0xFF082C46),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.10,
            child: Image.asset('assets/web/banner_bg.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  breadcrumb,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
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
