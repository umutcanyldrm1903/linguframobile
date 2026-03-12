import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../lessons/student_live_lesson_screen.dart';
import '../messages/student_chat_screen.dart';
import 'student_notifications_repository.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  final StudentNotificationsRepository _repository =
      StudentNotificationsRepository();

  bool _loading = true;
  bool _markingAllRead = false;
  bool _hasError = false;
  List<StudentNotificationItem> _items = const [];
  StudentNotificationType? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final items = await _repository.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  List<StudentNotificationItem> get _filtered {
    final filter = _filter;
    if (filter == null) return _items;
    return _items.where((item) => item.type == filter).toList(growable: false);
  }

  Future<void> _markAllAsRead() async {
    if (_markingAllRead || !_items.any((item) => item.unread)) {
      return;
    }

    setState(() {
      _markingAllRead = true;
    });

    try {
      await _repository.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((item) => item.copyWith(unread: false))
            .toList(growable: false);
        _markingAllRead = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _markingAllRead = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Something went wrong'))),
      );
    }
  }

  String? _actionLabel(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.lesson:
        return AppStrings.t('Join My Class');
      case StudentNotificationType.message:
        return AppStrings.t('Open Chat');
      case StudentNotificationType.payment:
        return null;
    }
  }

  VoidCallback? _buildAction(
    BuildContext context,
    StudentNotificationItem item,
  ) {
    final actionLabel = _actionLabel(item.type);
    if (actionLabel == null) {
      return null;
    }

    return () {
      if (item.type == StudentNotificationType.lesson && item.lesson != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentLiveLessonScreen(lesson: item.lesson!),
          ),
        );
        return;
      }

      if (item.type == StudentNotificationType.message && item.thread != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentChatScreen(
              partnerId: item.thread!.partnerId,
              name: item.thread!.partnerName,
            ),
          ),
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final anyUnread = _items.any((item) => item.unread);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Notifications'))),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  AppStrings.t('Notifications'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: anyUnread && !_markingAllRead ? _markAllAsRead : null,
                  child: Text(
                    _markingAllRead
                        ? AppStrings.t('Loading...')
                        : AppStrings.t('Mark all as read'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: AppStrings.t('All'),
                  active: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                _FilterChip(
                  label: AppStrings.t('Lessons'),
                  active: _filter == StudentNotificationType.lesson,
                  onTap: () =>
                      setState(() => _filter = StudentNotificationType.lesson),
                ),
                _FilterChip(
                  label: AppStrings.t('Payment'),
                  active: _filter == StudentNotificationType.payment,
                  onTap: () =>
                      setState(() => _filter = StudentNotificationType.payment),
                ),
                _FilterChip(
                  label: AppStrings.t('Messages'),
                  active: _filter == StudentNotificationType.message,
                  onTap: () =>
                      setState(() => _filter = StudentNotificationType.message),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      Text(AppStrings.t('Something went wrong')),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _load,
                        child: Text(AppStrings.t('Try Again')),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_loading && !_hasError && items.isEmpty)
              Text(
                AppStrings.t('No Data!'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (!_hasError)
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationTile(
                    item: item,
                    actionLabel: _actionLabel(item.type),
                    onTapAction: _buildAction(context, item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.actionLabel,
    required this.onTapAction,
  });

  final StudentNotificationItem item;
  final String? actionLabel;
  final VoidCallback? onTapAction;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(item.type);
    final color = _colorFor(item.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.unread
            ? AppColors.brand.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.time, style: Theme.of(context).textTheme.bodySmall),
                  if (item.unread)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onTapAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.lesson:
        return Icons.schedule;
      case StudentNotificationType.payment:
        return Icons.credit_card;
      case StudentNotificationType.message:
        return Icons.chat_bubble_outline;
    }
  }

  Color _colorFor(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.lesson:
        return AppColors.brand;
      case StudentNotificationType.payment:
        return const Color(0xFF22C55E);
      case StudentNotificationType.message:
        return AppColors.brandDeep;
    }
  }
}
