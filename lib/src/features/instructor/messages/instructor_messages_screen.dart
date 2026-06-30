import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../messages/chat_repository.dart';
import 'instructor_chat_screen.dart';

class InstructorMessagesScreen extends StatefulWidget {
  const InstructorMessagesScreen({super.key});

  @override
  State<InstructorMessagesScreen> createState() =>
      _InstructorMessagesScreenState();
}

class _InstructorMessagesScreenState extends State<InstructorMessagesScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('Messages'))),
      body: AppGlowBackground(
        accent: AppColors.brand,
        child: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return AppLoader(message: AppStrings.t('Messages'));
    }
    if (_errorText != null && _threads.isEmpty) {
      return AppErrorState(
        message: _errorText!,
        onRetry: _loadThreads,
        retryLabel: AppStrings.t('Try Again'),
      );
    }
    if (_threads.isEmpty) {
      return AppEmptyState(
        icon: Icons.forum_rounded,
        title: AppStrings.t('No messages yet.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpace.xl),
      children: [
        SectionHeader(
          title: AppStrings.t('Messages'),
          icon: Icons.forum_rounded,
        ),
        const SizedBox(height: AppSpace.xs),
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
                      builder: (_) => InstructorChatScreen(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontWeight:
                        hasUnread ? FontWeight.w700 : FontWeight.w500,
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
                thread.lastTimeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(height: AppSpace.sm),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
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
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Colors.white,
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
    final fallback = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.brand,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: thread.partnerImage.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                thread.partnerImage,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => fallback,
              ),
            ),
    );
  }
}
