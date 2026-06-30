import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../messages/chat_repository.dart';

enum _ThreadAction { report, block, unblock }

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({
    super.key,
    required this.partnerId,
    required this.name,
  });

  final int partnerId;
  final String name;

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          PopupMenuButton<_ThreadAction>(
            enabled: !_busyAction,
            onSelected: _handleThreadAction,
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.all(AppRadius.md),
            ),
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
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: AppGlowBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_blockedBannerText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
                  child: AppCard(
                    color: AppPalette.warning.withValues(alpha: 0.10),
                    border: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg, vertical: AppSpace.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppPalette.warning, size: 22),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            _blockedBannerText,
                            style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const AppLoader()
                    : _messages.isEmpty
                        ? AppEmptyState(
                            icon: Icons.forum_rounded,
                            title: AppStrings.t('No messages yet'),
                            message: AppStrings.t('Write your message...'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpace.xl),
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
    const radius = AppRadius.lg;
    const tail = Radius.circular(6);
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: isMe ? const Radius.circular(radius) : tail,
      bottomRight: isMe ? tail : const Radius.circular(radius),
    );

    final timeStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isMe ? Colors.white.withValues(alpha: 0.85) : AppColors.muted,
    );

    final content = Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(time, style: timeStyle),
        ],
      ],
    );

    final Widget bubble = isMe
        ? Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg, vertical: AppSpace.md),
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: bubbleRadius,
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.22),
            ),
            child: content,
          )
        : Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg, vertical: AppSpace.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: bubbleRadius,
              border: Border.all(color: AppPalette.line, width: 1.2),
              boxShadow: AppShadows.soft,
            ),
            child: content,
          );

    return AnimatedPageEntrance(
      offset: Offset(isMe ? 0.06 : -0.06, 0.04),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.md),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: bubble,
          ),
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
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppPalette.line, width: 1.2)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.cloud,
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppPalette.line, width: 1.2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
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
                  isDense: true,
                  hintText: AppStrings.t(
                    disabled
                        ? 'Messaging is disabled for this conversation.'
                        : 'Write your message...',
                  ),
                  hintStyle: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpace.md),
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
                    : AppShadows.glow(AppColors.brand, opacity: 0.30),
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
