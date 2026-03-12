import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
        body: TabBarView(
          children: [
            _SupportTab(categories: _categories, onCreated: _refreshTickets),
            _TicketsTab(
              ticketsFuture: _ticketsFuture,
              onReload: _refreshTickets,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTab extends StatelessWidget {
  const _SupportTab({required this.categories, required this.onCreated});

  final List<SupportCategory> categories;
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          AppStrings.t('How can we help you?'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.t(
            'Choose a category and send us your issue. We will reply via email.',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...categories.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () async {
                final created =
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupportRequestScreen(category: cat),
                      ),
                    ) ??
                    false;
                if (created) {
                  onCreated();
                }
              },
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.brand.withValues(alpha: 0.15),
                      child: Icon(cat.icon, color: AppColors.brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.t(cat.title),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.t('Something went wrong')),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onReload,
                  child: Text(AppStrings.t('Try Again')),
                ),
              ],
            ),
          );
        }

        final tickets = snapshot.data ?? const <SupportTicketItem>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.t('My Support Requests'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (tickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.brand.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.inbox,
                        size: 34,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.t('You do not have any support requests yet.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.t(
                        'Create a new request from the Support tab.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ...tickets.map(
              (ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TicketCard(ticket: ticket),
              ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.category.isEmpty ? ticket.subject : ticket.category,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF334155)),
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
