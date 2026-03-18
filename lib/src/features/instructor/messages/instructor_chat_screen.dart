import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          PopupMenuButton<_ThreadAction>(
            enabled: !_busyAction,
            onSelected: _handleThreadAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ThreadAction.report,
                child: Text(AppStrings.t('Report User')),
              ),
              PopupMenuItem(
                value: _moderation.blockedByMe
                    ? _ThreadAction.unblock
                    : _ThreadAction.block,
                child: Text(
                  AppStrings.t(
                    _moderation.blockedByMe ? 'Unblock User' : 'Block User',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_blockedBannerText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFFFF7ED),
              child: Text(
                _blockedBannerText,
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == _userId;
                      return _ChatBubble(
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
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final String time;

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final background = isMe ? AppColors.brandDeep : AppColors.surface;
    final textColor = isMe ? Colors.white : AppColors.ink;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : AppColors.muted,
                  ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !disabled,
              decoration: InputDecoration(
                hintText: AppStrings.t(
                  disabled
                      ? 'Messaging is disabled for this conversation.'
                      : 'Write your message...',
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: CircleAvatar(
              radius: 22,
              backgroundColor:
                  disabled ? const Color(0xFFCBD5E1) : AppColors.brandDeep,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
