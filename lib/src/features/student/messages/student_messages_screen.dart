import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../messages/chat_repository.dart';
import 'student_chat_screen.dart';

class StudentMessagesScreen extends StatefulWidget {
  const StudentMessagesScreen({super.key});

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  final ChatRepository _repository = ChatRepository();
  Timer? _pollTimer;
  bool _loading = true;
  List<ChatThread> _threads = const [];
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadThreads();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 8), (_) => _loadThreads(silent: true));
  }

  Future<void> _loadThreads({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final items = await _repository.fetchThreads();
      if (!mounted) return;
      setState(() {
        _threads = items;
        _loading = false;
        _errorText = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = AppStrings.t('Something went wrong');
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppLoader(message: AppStrings.t('Messages'));
    }

    if (_errorText != null && _threads.isEmpty) {
      return AppErrorState(
        message: _errorText!,
        retryLabel: AppStrings.t('Try Again'),
        onRetry: _loadThreads,
      );
    }

    if (_threads.isEmpty) {
      return AppEmptyState(
        icon: Icons.forum_rounded,
        title: AppStrings.t('No messages yet.'),
        message: AppStrings.t('Messages'),
        actionLabel: AppStrings.t('Try Again'),
        onAction: _loadThreads,
      );
    }

    final totalUnread =
        _threads.fold<int>(0, (sum, t) => sum + (t.unreadCount > 0 ? t.unreadCount : 0));

    return AppGlowBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.xl,
            AppSpace.xl,
            AppSpace.xxl,
          ),
          children: [
            SectionHeader(
              icon: Icons.forum_rounded,
              title: AppStrings.t('Messages'),
              subtitle: totalUnread > 0
                  ? '$totalUnread ${AppStrings.t('unread')}'
                  : null,
            ),
            const SizedBox(height: AppSpace.sm),
            StaggeredReveal(
              children: [
                for (final thread in _threads)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _MessageTile(
                      thread: thread,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentChatScreen(
                            partnerId: thread.partnerId,
                            name: thread.partnerName,
                          ),
                        ),
                      ),
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

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = thread.unreadCount > 0;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(thread: thread),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.partnerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  thread.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasUnread ? AppColors.ink : AppColors.muted,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (thread.lastTimeLabel.isNotEmpty)
                Text(
                  thread.lastTimeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasUnread ? AppColors.brand : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (hasUnread) ...[
                const SizedBox(height: AppSpace.sm),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: AppRadius.pill,
                    boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.30),
                  ),
                  child: Text(
                    thread.unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final initial =
        thread.partnerName.isNotEmpty ? thread.partnerName.substring(0, 1) : '?';

    Widget fallback() => Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.brand,
          ),
          child: Text(
            initial.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        );

    final avatar = thread.partnerImage.isEmpty
        ? fallback()
        : ClipOval(
            child: Image.network(
              thread.partnerImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (_, __, ___) => fallback(),
            ),
          );

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.line, width: 1.5),
        boxShadow: AppShadows.soft,
      ),
      child: avatar,
    );
  }
}
