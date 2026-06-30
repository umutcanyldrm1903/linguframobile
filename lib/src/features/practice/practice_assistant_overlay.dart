import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import 'practice_api_service.dart';
import 'screens/practice_visuals.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final PracticeAssistantRouteObserver practiceAssistantRouteObserver =
    PracticeAssistantRouteObserver();
final ValueNotifier<int> practiceAssistantSuppressions = ValueNotifier<int>(0);

class PracticeAssistantRouteObserver extends NavigatorObserver {
  final ValueNotifier<String> currentRoute = ValueNotifier<String>('/splash');

  void _publish(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty && currentRoute.value != name) {
      currentRoute.value = name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _publish(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _publish(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _publish(previousRoute);
  }
}

class PracticeAssistantOverlay extends StatefulWidget {
  const PracticeAssistantOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<PracticeAssistantOverlay> createState() =>
      _PracticeAssistantOverlayState();
}

class _PracticeAssistantOverlayState extends State<PracticeAssistantOverlay>
    with WidgetsBindingObserver {
  static const PracticeApiService _api = PracticeApiService();
  static const _hiddenRoutes = <String>{
    '/',
    '/home',
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/taster',
    '/about',
    '/blog',
    '/contact',
    '/corporate',
    '/terms',
    '/privacy',
    '/placement-test',
    '/after-test',
    '/instructor',
  };

  Map<String, dynamic>? _insight;
  Timer? _bubbleTimer;
  Timer? _refreshDebounce;
  String _route = '/splash';
  bool _visible = false;
  bool _bubbleVisible = false;
  bool _sheetOpen = false;
  bool _suppressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _route = practiceAssistantRouteObserver.currentRoute.value;
    practiceAssistantRouteObserver.currentRoute.addListener(_routeChanged);
    practiceAssistantSuppressions.addListener(_suppressionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(eventName: 'app_opened');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    practiceAssistantRouteObserver.currentRoute.removeListener(_routeChanged);
    practiceAssistantSuppressions.removeListener(_suppressionChanged);
    _bubbleTimer?.cancel();
    _refreshDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh(eventName: 'app_opened');
    }
  }

  void _routeChanged() {
    _route = practiceAssistantRouteObserver.currentRoute.value;
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _refresh(eventName: 'screen_view'),
    );
  }

  void _suppressionChanged() {
    if (!mounted) return;
    setState(() {
      _suppressed = practiceAssistantSuppressions.value > 0;
      if (_suppressed) _bubbleVisible = false;
    });
  }

  Future<void> _refresh({required String eventName}) async {
    final token = (await SecureStorage.getToken() ?? '').trim();
    final role = (await SecureStorage.getRole() ?? '').trim();
    final shouldShow = token.isNotEmpty &&
        role != 'instructor' &&
        !_hiddenRoutes.contains(_route);
    if (!shouldShow) {
      if (mounted) {
        setState(() {
          _visible = false;
          _bubbleVisible = false;
        });
      }
      return;
    }

    unawaited(_api.recordAssistantEvent(name: eventName, route: _route));
    final data = await _api.getAssistantInsight(
      route: _route,
      locale: AppStrings.code == 'tr' ? 'tr' : 'en',
    );
    if (!mounted) return;
    final insight = data == null ? null : Map<String, dynamic>.from(data);
    final serverVisible = insight?['visible'] != false;
    setState(() {
      _visible = serverVisible;
      _insight = insight;
      // The full speech bubble was covering bottom sheets and CTA buttons.
      // Keep the assistant available as a small floating mascot; the detailed
      // advice opens only when the user taps it.
      _bubbleVisible = false;
    });
    _bubbleTimer?.cancel();
  }

  PracticeMascotMood get _mood {
    return switch ('${_insight?['mood'] ?? 'happy'}') {
      'thinking' => PracticeMascotMood.thinking,
      'sad' => PracticeMascotMood.sad,
      'excited' => PracticeMascotMood.excited,
      'proud' => PracticeMascotMood.proud,
      'wink' => PracticeMascotMood.wink,
      _ => PracticeMascotMood.happy,
    };
  }

  Future<void> _openAssistant() async {
    _bubbleTimer?.cancel();
    setState(() {
      _bubbleVisible = false;
      _sheetOpen = true;
    });
    unawaited(
      _api.recordAssistantEvent(name: 'assistant_opened', route: _route),
    );
    final context =
        appNavigatorKey.currentState?.overlay?.context ?? this.context;
    bool? result;
    try {
      result = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AssistantSheet(
          insight: _insight ?? const <String, dynamic>{},
          route: _route,
        ),
      );
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
    if (!mounted) return;
    if (result == false) {
      setState(() => _visible = false);
    } else {
      unawaited(_refresh(eventName: 'screen_view'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible && !_sheetOpen && !keyboardOpen && !_suppressed)
          Positioned(
            right: 12,
            bottom: 92,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _bubbleVisible && _insight != null
                        ? Container(
                            key: ValueKey<String>(
                              '${_insight?['id']}-${_insight?['message']}',
                            ),
                            constraints: const BoxConstraints(maxWidth: 235),
                            margin: const EdgeInsets.only(bottom: 8, right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD9E2EC),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              '${_insight?['message'] ?? ''}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF243B53),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Semantics(
                    button: true,
                    label: AppStrings.code == 'tr'
                        ? 'Akıllı Kalem Asistanı'
                        : 'Smart Pencil Assistant',
                    child: GestureDetector(
                      onTap: _openAssistant,
                      child: Material(
                        color: Colors.white,
                        elevation: 7,
                        shape: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: PracticeMascot(size: 48, mood: _mood),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet({required this.insight, required this.route});

  final Map<String, dynamic> insight;
  final String route;

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  static const PracticeApiService _api = PracticeApiService();
  final TextEditingController _question = TextEditingController();
  final ScrollController _messageScroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;

  bool get _isTr => AppStrings.code == 'tr';

  @override
  void dispose() {
    _question.dispose();
    _messageScroll.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_messageScroll.hasClients) return;
      _messageScroll.animateTo(
        _messageScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final message = _question.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add({'role': 'user', 'text': message});
      _question.clear();
    });
    _scrollToLatest();
    final data = await _api.sendAssistantMessage(
      message: message,
      route: widget.route,
      locale: _isTr ? 'tr' : 'en',
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.add({
        'role': 'assistant',
        'text':
            '${data?['reply'] ?? (_isTr ? 'Birlikte kısa bir pratikle başlayalım.' : 'Let’s start with a short practice.')}',
      });
    });
    _scrollToLatest();
  }

  Future<void> _openAction() async {
    final route = '${widget.insight['action_route'] ?? '/practice'}';
    unawaited(
      _api.recordAssistantEvent(
        name: 'assistant_action',
        route: widget.route,
        properties: {'target': route},
      ),
    );
    Navigator.of(context).pop();
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    if (practiceAssistantRouteObserver.currentRoute.value == route) return;
    navigator.pushNamed(route);
  }

  Future<void> _disableAssistant() async {
    await _api.updateAssistantPreferences({
      'assistant_enabled': false,
      'assistant_push_enabled': false,
    });
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .84,
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const PracticeMascot(
                size: 64,
                mood: PracticeMascotMood.happy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.insight['title'] ?? (_isTr ? 'Akıllı Kalem' : 'Smart Pencil')}',
                      style: const TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.insight['message'] ?? (_isTr ? 'Bugünkü çalışmanı birlikte planlayalım.' : 'Let’s plan today’s practice together.')}',
                      style: const TextStyle(
                        color: Color(0xFF486581),
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: _isTr ? 'Asistan ayarları' : 'Assistant settings',
                onSelected: (value) {
                  if (value == 'disable') _disableAssistant();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'disable',
                    child: Text(
                      _isTr ? 'Asistanı kapat' : 'Turn off assistant',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAction,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                '${widget.insight['action_label'] ?? (_isTr ? 'Öneriyi aç' : 'Open suggestion')}',
              ),
            ),
          ),
          if (_messages.isNotEmpty) ...[
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                controller: _messageScroll,
                shrinkWrap: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 4),
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final message = _messages[index];
                  final mine = message['role'] == 'user';
                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: mine
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        message['text'] ?? '',
                        style: TextStyle(
                          color: mine ? Colors.white : const Color(0xFF243B53),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _question,
                  textInputAction: TextInputAction.send,
                  onTap: _scrollToLatest,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: _isTr
                        ? 'Bugün ne çalışmalıyım?'
                        : 'What should I study today?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const PracticeMascot(
                        size: 24,
                        mood: PracticeMascotMood.thinking,
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isTr
                ? 'Asistan yalnızca uygulamadaki öğrenme verilerini kullanır.'
                : 'The assistant only uses learning activity from this app.',
            style: const TextStyle(
              color: Color(0xFF829AB1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
