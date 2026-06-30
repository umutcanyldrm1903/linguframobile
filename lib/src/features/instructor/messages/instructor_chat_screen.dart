import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../messages/chat_repository.dart';

enum _ThreadAction { report, block, unblock }

class InstructorChatScreen extends StatefulWidget {
  const InstructorChatScreen({
    super.key,
    required this.partnerId,
    required this.name,
  });

  final int partnerId;
  final String name;

  @override
  State<InstructorChatScreen> createState() => _InstructorChatScreenState();
}

class _InstructorChatScreenState extends State<InstructorChatScreen> {
  final ChatRepository _repository = ChatRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  bool _loading = true;
  bool _busyAction = false;
  List<ChatMessage> _messages = [];
  ChatModerationState _moderation = const ChatModerationState(
    blockedByMe: false,
    blockedByPartner: false,
  );
  int _userId = 0;

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is Map) {
          return message.values.map((value) => value.toString()).join('\n');
        }
      }
    }
    return AppStrings.t('Something went wrong');
  }

  @override
  void initState() {
    super.initState();
    _bootstrapThread();
  }

  Future<void> _bootstrapThread() async {
    await _loadUserId();
    if (!mounted) return;
    await Future.wait([
      _loadMessages(),
      _loadModerationState(),
    ]);
    if (!mounted) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshThreadState(),
    );
  }

  Future<void> _refreshThreadState() async {
    await _loadMessages(silent: true);
    if (!mounted) return;
    await _loadModerationState(silent: true);
  }

  Future<void> _loadUserId() async {
    final stored = await SecureStorage.getUserId();
    _userId = stored == null ? 0 : int.tryParse(stored) ?? 0;
  }

  Future<void> _loadModerationState({bool silent = false}) async {
    try {
      final moderation =
          await _repository.fetchModerationState(widget.partnerId);
      if (!mounted) return;
      setState(() => _moderation = moderation);
    } catch (error) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final shouldAutoScroll = !silent || _isNearBottom();
      final previousLastId = _messages.isEmpty ? null : _messages.last.id;
      final items = await _repository.fetchThreadMessages(widget.partnerId);
      if (mounted) {
        setState(() {
          _messages = items;
          _loading = false;
        });
        final hasNewTailMessage =
            items.isNotEmpty && items.last.id != previousLastId;
        if (hasNewTailMessage && shouldAutoScroll) {
          _jumpToBottom(animated: silent);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!_moderation.canSend) {
      _showSnack(_blockedBannerText);
      return;
    }

    _controller.clear();
    try {
      final message = await _repository.sendMessage(widget.partnerId, text);
      if (!mounted) return;
      setState(() => _messages = [..._messages, message]);
      _jumpToBottom(animated: true);
    } catch (error) {
      _controller.text = text;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
      await _loadModerationState(silent: true);
    }
  }

  Future<void> _handleThreadAction(_ThreadAction action) async {
    switch (action) {
      case _ThreadAction.report:
        await _reportUser();
        return;
      case _ThreadAction.block:
        await _blockUser();
        return;
      case _ThreadAction.unblock:
        await _unblockUser();
        return;
    }
  }

  Future<void> _reportUser() async {
    final reason = await _askForReason(
      title: AppStrings.t('Report User'),
      hint: AppStrings.t('Tell us why you are reporting this user.'),
      actionLabel: AppStrings.t('Send Report'),
    );
    if (!mounted || reason == null || reason.trim().isEmpty) return;

    setState(() => _busyAction = true);
    try {
      final latestIncoming = _messages.lastWhere(
        (message) => message.senderId == widget.partnerId,
        orElse: () => const ChatMessage(
          id: 0,
          senderId: 0,
          body: '',
          timeLabel: '',
          createdAt: null,
        ),
      );
      await _repository.reportUser(
        widget.partnerId,
        reason: reason,
        messageId: latestIncoming.id > 0 ? latestIncoming.id : null,
      );
      if (!mounted) return;
      _showSnack(AppStrings.t('Report submitted successfully.'));
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busyAction = false);
      }
    }
  }

  Future<void> _blockUser() async {
    final confirmed = await _confirmAction(
      title: AppStrings.t('Block User'),
      body: AppStrings.t(
        'Blocking this user will stop new messages in this conversation.',
      ),
      actionLabel: AppStrings.t('Block User'),
    );
    if (!mounted || !confirmed) return;

    setState(() => _busyAction = true);
    try {
      final state = await _repository.blockUser(widget.partnerId);
      if (!mounted) return;
      setState(() => _moderation = state);
      _showSnack(AppStrings.t('User blocked successfully.'));
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busyAction = false);
      }
    }
  }

  Future<void> _unblockUser() async {
    setState(() => _busyAction = true);
    try {
      final state = await _repository.unblockUser(widget.partnerId);
      if (!mounted) return;
      setState(() => _moderation = state);
      _showSnack(AppStrings.t('User unblocked successfully.'));
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busyAction = false);
      }
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String body,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppStrings.t('Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _askForReason({
    required String title,
    required String hint,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 120;
  }

  void _jumpToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollController.position.maxScrollExtent + 50;
        if (animated) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
          return;
        }
        _scrollController.jumpTo(target);
      }
    });
  }

  String get _blockedBannerText {
    if (_moderation.blockedByMe) {
      return AppStrings.t(
        'You blocked this user. Unblock the user to send messages again.',
      );
    }
    if (_moderation.blockedByPartner) {
      return AppStrings.t('This user is not accepting messages from you.');
    }
    return '';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.name,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        actions: [
          PopupMenuButton<_ThreadAction>(
            enabled: !_busyAction,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            onSelected: _handleThreadAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ThreadAction.report,
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 18, color: AppPalette.warning),
                    const SizedBox(width: AppSpace.sm),
                    Text(AppStrings.t('Report User')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _moderation.blockedByMe
                    ? _ThreadAction.unblock
                    : _ThreadAction.block,
                child: Row(
                  children: [
                    Icon(
                      _moderation.blockedByMe
                          ? Icons.lock_open_rounded
                          : Icons.block_rounded,
                      size: 18,
                      color: _moderation.blockedByMe
                          ? AppPalette.success
                          : AppPalette.danger,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      AppStrings.t(
                        _moderation.blockedByMe ? 'Unblock User' : 'Block User',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppGlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (_blockedBannerText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.sm,
                    AppSpace.lg,
                    0,
                  ),
                  child: AnimatedPageEntrance(
                    child: AppCard(
                      color: AppPalette.warning.withValues(alpha: 0.10),
                      border: false,
                      shadow: const [],
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppPalette.warning.withValues(alpha: 0.16),
                            ),
                            child: Icon(
                              _moderation.blockedByMe
                                  ? Icons.block_rounded
                                  : Icons.do_not_disturb_on_rounded,
                              color: AppPalette.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Text(
                              _blockedBannerText,
                              style: TextStyle(
                                color: AppPalette.warning.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? AppLoader(message: AppStrings.t('Loading...'))
                    : _messages.isEmpty
                        ? AppEmptyState(
                            icon: Icons.forum_rounded,
                            title: AppStrings.t('No messages yet'),
                            message:
                                AppStrings.t('Write your message...'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpace.lg,
                              AppSpace.lg,
                              AppSpace.lg,
                              AppSpace.sm,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (_, index) {
                              final msg = _messages[index];
                              final isMe = msg.senderId == _userId;
                              return _ChatBubble(
                                key: ValueKey(msg.id),
                                text: msg.body,
                                isMe: isMe,
                                time: msg.timeLabel,
                              );
                            },
                          ),
              ),
              _ChatInput(
                controller: _controller,
                onSend: _moderation.canSend ? _sendMessage : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final String time;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        gradient: isMe ? AppGradients.brand : null,
        color: isMe ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.lg),
          topRight: const Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(isMe ? AppRadius.lg : 6),
          bottomRight: Radius.circular(isMe ? 6 : AppRadius.lg),
        ),
        border: isMe ? null : Border.all(color: AppPalette.line, width: 1.2),
        boxShadow: isMe
            ? AppShadows.glow(AppColors.brand, opacity: 0.22)
            : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.32,
            ),
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              time,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.muted,
                  ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AnimatedPageEntrance(
        offset: Offset(isMe ? 0.06 : -0.06, 0.04),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: bubble,
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final disabled = onSend == null;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppPalette.line)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.cloud,
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppPalette.line, width: 1.2),
              ),
              child: TextField(
                controller: controller,
                enabled: !disabled,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.t(
                    disabled
                        ? 'Messaging is disabled for this conversation.'
                        : 'Write your message...',
                  ),
                  hintStyle: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.md,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          PressableScale(
            onTap: onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: disabled ? null : AppGradients.brand,
                color: disabled ? AppPalette.line : null,
                boxShadow: disabled
                    ? null
                    : AppShadows.glow(AppColors.brand, opacity: 0.34),
              ),
              child: Icon(
                Icons.send_rounded,
                color: disabled ? AppColors.muted : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
