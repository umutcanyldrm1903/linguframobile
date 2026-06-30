import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../lessons/student_live_lesson_screen.dart';
import '../messages/student_chat_screen.dart';
import 'student_notifications_repository.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({
    super.key,
    this.repository,
  });

  final StudentNotificationsRepository? repository;

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
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
      final items =
          await (widget.repository ?? StudentNotificationsRepository())
              .fetchNotifications();
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
      await (widget.repository ?? StudentNotificationsRepository())
          .markAllAsRead();
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
    final unreadCount = _items.where((item) => item.unread).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(AppStrings.t('Notifications'))),
      body: AppGlowBackground(
        child: RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              AnimatedPageEntrance(
                child: GradientHero(
                  gradient: AppGradients.hero,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t('Notifications'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            AppStatPill(
                              icon: Icons.mark_email_unread_rounded,
                              label: unreadCount > 0
                                  ? '$unreadCount ${AppStrings.t('Notifications')}'
                                  : AppStrings.t('No Data!'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white.withValues(alpha: 0.92),
                        size: 44,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AnimatedPageEntrance(
                delay: const Duration(milliseconds: 60),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppGhostButton(
                    label: _markingAllRead
                        ? AppStrings.t('Loading...')
                        : AppStrings.t('Mark all as read'),
                    icon: Icons.done_all_rounded,
                    expand: false,
                    onPressed:
                        anyUnread && !_markingAllRead ? _markAllAsRead : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              AnimatedPageEntrance(
                delay: const Duration(milliseconds: 100),
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    AppChip(
                      label: AppStrings.t('All'),
                      icon: Icons.all_inbox_rounded,
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    AppChip(
                      label: AppStrings.t('Lessons'),
                      icon: Icons.schedule_rounded,
                      selected: _filter == StudentNotificationType.lesson,
                      onTap: () => setState(
                          () => _filter = StudentNotificationType.lesson),
                    ),
                    AppChip(
                      label: AppStrings.t('Payment'),
                      icon: Icons.credit_card_rounded,
                      color: AppPalette.success,
                      selected: _filter == StudentNotificationType.payment,
                      onTap: () => setState(
                          () => _filter = StudentNotificationType.payment),
                    ),
                    AppChip(
                      label: AppStrings.t('Messages'),
                      icon: Icons.chat_bubble_outline_rounded,
                      color: AppColors.brandDeep,
                      selected: _filter == StudentNotificationType.message,
                      onTap: () => setState(
                          () => _filter = StudentNotificationType.message),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.xxxl),
                  child: AppLoader(),
                ),
              if (!_loading && _hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xxxl),
                  child: AppErrorState(
                    message: AppStrings.t('Something went wrong'),
                    retryLabel: AppStrings.t('Try Again'),
                    onRetry: _load,
                  ),
                ),
              if (!_loading && !_hasError && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xxxl),
                  child: AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: AppStrings.t('No Data!'),
                  ),
                ),
              if (!_hasError && items.isNotEmpty)
                StaggeredReveal(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: _NotificationTile(
                          item: item,
                          actionLabel: _actionLabel(item.type),
                          onTapAction: _buildAction(context, item),
                        ),
                      ),
                  ],
                ),
            ],
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
    final theme = Theme.of(context);
    final icon = _iconFor(item.type);
    final color = _colorFor(item.type);
    return AppCard(
      radius: AppRadius.md,
      color: item.unread ? AppColors.brand.withValues(alpha: 0.06) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.unread)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 9,
                      height: 9,
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
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: actionLabel!,
                onPressed: onTapAction,
                tone: _toneFor(item.type),
                icon: _actionIconFor(item.type),
                expand: false,
                height: 44,
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

  IconData _actionIconFor(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.lesson:
        return Icons.videocam_rounded;
      case StudentNotificationType.payment:
        return Icons.credit_card_rounded;
      case StudentNotificationType.message:
        return Icons.chat_rounded;
    }
  }

  AppButtonTone _toneFor(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.lesson:
        return AppButtonTone.brand;
      case StudentNotificationType.payment:
        return AppButtonTone.success;
      case StudentNotificationType.message:
        return AppButtonTone.violet;
    }
  }

  Color _colorFor(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.lesson:
        return AppColors.brand;
      case StudentNotificationType.payment:
        return AppPalette.success;
      case StudentNotificationType.message:
        return AppColors.brandDeep;
    }
  }
}
