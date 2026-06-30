import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'support_models.dart';
import 'support_request_screen.dart';
import 'support_repository.dart';

class StudentSupportScreen extends StatefulWidget {
  const StudentSupportScreen({super.key});

  @override
  State<StudentSupportScreen> createState() => _StudentSupportScreenState();
}

class _StudentSupportScreenState extends State<StudentSupportScreen> {
  late Future<List<SupportTicketItem>> _ticketsFuture;

  static const _categories = <SupportCategory>[
    SupportCategory(
      keyName: 'plan-payment',
      title: 'Plan & Payment',
      icon: Icons.credit_card,
    ),
    SupportCategory(
      keyName: 'lessons',
      title: 'Lessons',
      icon: Icons.layers_outlined,
    ),
    SupportCategory(
      keyName: 'technical',
      title: 'Technical Issues',
      icon: Icons.build_outlined,
    ),
    SupportCategory(
      keyName: 'instructors',
      title: 'Instructors',
      icon: Icons.school_outlined,
    ),
    SupportCategory(
      keyName: 'account',
      title: 'Account & Profile',
      icon: Icons.person_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _fetchTickets();
  }

  Future<List<SupportTicketItem>> _fetchTickets() {
    return SupportRepository().fetchTickets();
  }

  void _refreshTickets() {
    setState(() {
      _ticketsFuture = _fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(AppStrings.t('Support')),
          bottom: TabBar(
            labelColor: AppColors.ink,
            indicatorColor: AppColors.brand,
            tabs: [
              Tab(text: AppStrings.t('Support')),
              Tab(text: AppStrings.t('My Support Requests')),
            ],
          ),
        ),
        body: AppGlowBackground(
          child: TabBarView(
            children: [
              _SupportTab(categories: _categories, onCreated: _refreshTickets),
              _TicketsTab(
                ticketsFuture: _ticketsFuture,
                onReload: _refreshTickets,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-category accent gradient/color for the icon chip. Purely presentational
/// — does not change category identity or routing.
({Gradient gradient, Color glow}) _categoryAccent(String keyName) {
  switch (keyName) {
    case 'plan-payment':
      return (gradient: AppGradients.gold, glow: AppPalette.goldDeep);
    case 'lessons':
      return (gradient: AppGradients.brand, glow: AppColors.brand);
    case 'technical':
      return (gradient: AppGradients.violet, glow: AppPalette.violet);
    case 'instructors':
      return (gradient: AppGradients.success, glow: AppPalette.success);
    case 'account':
      return (
        gradient: AppGradients.pair(AppPalette.info, AppColors.brandDeep),
        glow: AppPalette.info,
      );
    default:
      return (gradient: AppGradients.brand, glow: AppColors.brand);
  }
}

class _SupportTab extends StatelessWidget {
  const _SupportTab({required this.categories, required this.onCreated});

  final List<SupportCategory> categories;
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xl),
      children: [
        AnimatedPageEntrance(
          child: GradientHero(
            gradient: AppGradients.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppRadius.all(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        AppStrings.t('How can we help you?'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  AppStrings.t(
                    'Choose a category and send us your issue. We will reply via email.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        SectionHeader(
          title: AppStrings.t('Support'),
          icon: Icons.category_outlined,
        ),
        StaggeredReveal(
          children: [
            for (final cat in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: _CategoryCard(
                  category: cat,
                  onCreated: onCreated,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onCreated});

  final SupportCategory category;
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryAccent(category.keyName);
    return AppCard(
      onTap: () async {
        final created =
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => SupportRequestScreen(category: category),
              ),
            ) ??
            false;
        if (created) {
          onCreated();
        }
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: accent.gradient,
              borderRadius: AppRadius.all(AppRadius.md),
              boxShadow: AppShadows.glow(accent.glow, opacity: 0.30),
            ),
            child: Icon(category.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              AppStrings.t(category.title),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({required this.ticketsFuture, required this.onReload});

  final Future<List<SupportTicketItem>> ticketsFuture;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SupportTicketItem>>(
      future: ticketsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoader();
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: AppStrings.t('Something went wrong'),
            onRetry: onReload,
            retryLabel: AppStrings.t('Try Again'),
          );
        }

        final tickets = snapshot.data ?? const <SupportTicketItem>[];

        if (tickets.isEmpty) {
          return AppEmptyState(
            icon: Icons.inbox_rounded,
            title: AppStrings.t('You do not have any support requests yet.'),
            message: AppStrings.t('Create a new request from the Support tab.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpace.xl),
          children: [
            SectionHeader(
              title: AppStrings.t('My Support Requests'),
              icon: Icons.confirmation_number_outlined,
            ),
            StaggeredReveal(
              children: [
                for (final ticket in tickets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _TicketCard(ticket: ticket),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final SupportTicketItem ticket;

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(ticket.createdAt, ticket.createdAtRaw);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 19,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  ticket.category.isEmpty ? ticket.subject : ticket.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                dateText,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            ticket.message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF334155), height: 1.35),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value, String raw) {
    if (value == null) return raw;
    return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
  }
}
