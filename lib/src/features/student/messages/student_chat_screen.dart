import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../messages/chat_repository.dart';

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen(
      {super.key, required this.partnerId, required this.name});

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
  List<ChatMessage> _messages = [];
  int _userId = 0;

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
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
    await _loadMessages();
    if (!mounted) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _loadMessages(silent: true),
    );
  }

  Future<void> _loadUserId() async {
    final stored = await SecureStorage.getUserId();
    _userId = stored == null ? 0 : int.tryParse(stored) ?? 0;
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
    _controller.clear();
    try {
      final message = await _repository.sendMessage(widget.partnerId, text);
      setState(() => _messages = [..._messages, message]);
      _jumpToBottom(animated: true);
    } catch (error) {
      _controller.text = text;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    }
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
        actions: const [
          Icon(Icons.more_vert),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
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
            onSend: _sendMessage,
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
    final background = isMe ? AppColors.brand : AppColors.surface;
    final textColor = isMe ? AppColors.ink : AppColors.ink;
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
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
              decoration: InputDecoration(
                hintText: AppStrings.t('Write your message...'),
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
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.send, color: AppColors.ink),
            ),
          )
        ],
      ),
    );
  }
}
