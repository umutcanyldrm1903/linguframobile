import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(AppStrings.t('Messages'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_errorText != null && _threads.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorText!),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadThreads,
                        child: Text(AppStrings.t('Try Again')),
                      ),
                    ],
                  ),
                )
              : _threads.isEmpty
                  ? Center(child: Text(AppStrings.t('No messages yet.')))
                  : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(AppStrings.t('Messages'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ..._threads.map(
                      (thread) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                    ),
                  ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.brandDeep.withValues(alpha: 0.2),
              child: (() {
                final initial = thread.partnerName.isNotEmpty
                    ? thread.partnerName.substring(0, 1)
                    : '?';
                if (thread.partnerImage.isEmpty) {
                  return Text(initial);
                }
                return ClipOval(
                  child: Image.network(
                    thread.partnerImage,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: Text(initial)),
                    ),
                  ),
                );
              })(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread.partnerName, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(thread.lastMessage, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(thread.lastTimeLabel, style: Theme.of(context).textTheme.bodyMedium),
                if (thread.unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandDeep,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      thread.unreadCount.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
