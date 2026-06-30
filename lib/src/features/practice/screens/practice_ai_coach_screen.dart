import 'package:flutter/material.dart';

import '../practice_api_service.dart';
import '../practice_premium_offer_service.dart';
import 'practice_visuals.dart';

class PracticeAiCoachScreen extends StatefulWidget {
  const PracticeAiCoachScreen({super.key});

  @override
  State<PracticeAiCoachScreen> createState() => _PracticeAiCoachScreenState();
}

class _PracticeAiCoachScreenState extends State<PracticeAiCoachScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final TextEditingController _question = TextEditingController(
    text: 'Complete: I would like ___ coffee.',
  );
  final TextEditingController _wrong = TextEditingController(text: 'many');
  final TextEditingController _correct = TextEditingController(text: 'some');
  final TextEditingController _roleplayInput = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loadingExplain = false;
  bool _loadingChat = false;
  int? _sessionId;
  String _explanation = '';

  @override
  void dispose() {
    final sessionId = _sessionId;
    if (sessionId != null && sessionId > 0) {
      // Roleplay oturumunu sunucuda kapat (fire-and-forget).
      _api.endRoleplay({'session_id': sessionId});
    }
    _question.dispose();
    _wrong.dispose();
    _correct.dispose();
    _roleplayInput.dispose();
    super.dispose();
  }

  Future<void> _explain() async {
    setState(() => _loadingExplain = true);
    final data = await _api.explainWithAi({
      'question': _question.text.trim(),
      'user_answer': _wrong.text.trim(),
      'correct_answer': _correct.text.trim(),
    });
    if (!mounted) return;
    if (data?['premium_required'] == true) {
      setState(() => _loadingExplain = false);
      await _showAiLimitOffer(data, trigger: PracticePremiumTrigger.aiExplain);
      return;
    }
    setState(() {
      _loadingExplain = false;
      _explanation =
          '${data?['explanation'] ?? 'Doğru cevapla kendi cevabını karsilastir ve kalibi tekrar et.'}';
    });
  }

  Future<void> _startRoleplay() async {
    setState(() => _loadingChat = true);
    final data = await _api.startRoleplay({'scenario': 'Cafe order'});
    if (!mounted) return;
    if (data?['premium_required'] == true) {
      setState(() => _loadingChat = false);
      await _showAiLimitOffer(data, trigger: PracticePremiumTrigger.roleplay);
      return;
    }
    final rawMessages = data?['messages'];
    setState(() {
      _loadingChat = false;
      _sessionId = _asInt(data?['session_id']);
      _messages
        ..clear()
        ..addAll(rawMessages is List
            ? rawMessages.whereType<Map>().map((item) => {
                  'role': '${item['role'] ?? 'assistant'}',
                  'content': '${item['content'] ?? ''}',
                })
            : [
                {
                  'role': 'assistant',
                  'content': 'Hello! What would you like to order?',
                }
              ]);
    });
  }

  Future<void> _sendRoleplay() async {
    final text = _roleplayInput.text.trim();
    final sessionId = _sessionId;
    if (text.isEmpty) return;
    if (sessionId == null || sessionId <= 0) {
      await _startRoleplay();
    }
    final resolvedSessionId = _sessionId;
    if (resolvedSessionId == null || resolvedSessionId <= 0) return;
    setState(() {
      _loadingChat = true;
      _messages.add({'role': 'user', 'content': text});
      _roleplayInput.clear();
    });
    final data = await _api.sendRoleplayMessage({
      'session_id': resolvedSessionId,
      'message': text,
    });
    if (!mounted) return;
    if (data?['premium_required'] == true) {
      setState(() {
        _loadingChat = false;
        _messages.add({
          'role': 'assistant',
          'content':
              'Ücretsiz konuşma sınırına ulaştın. Premium ile devam edebilirsin.',
        });
      });
      await _showAiLimitOffer(data, trigger: PracticePremiumTrigger.roleplay);
      return;
    }
    setState(() {
      _loadingChat = false;
      _messages.add({
        'role': 'assistant',
        'content':
            '${data?['reply'] ?? 'Good try. Say it shorter and clearer.'}',
      });
    });
  }

  Future<void> _showAiLimitOffer(
    Map<String, dynamic>? data, {
    required PracticePremiumTrigger trigger,
  }) async {
    final coinUnlock = data?['coin_unlock_available'] == true;
    final coinCost = (data?['coin_cost'] as num?)?.toInt();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PracticeMascot(size: 92, mood: PracticeMascotMood.thinking),
            const SizedBox(height: 10),
            const Text(
              'AI hakkın doldu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: practiceInk,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              coinUnlock && coinCost != null
                  ? '$coinCost mücevher ile ekstra hak alabilir veya Premium ile sınırları genişletebilirsin.'
                  : 'Premium ile AI açıklama ve roleplay sınırlarını genişletebilirsin.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: practiceMuted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            if (coinUnlock)
              PracticePrimaryButton(
                label: 'MÜCEVHERLE HAK AL',
                color: practiceBlue,
                onPressed: () => Navigator.pop(sheetContext, 'shop'),
              ),
            if (coinUnlock) const SizedBox(height: 10),
            PracticePrimaryButton(
              label: 'PREMIUM’A GEÇ',
              color: practicePurple,
              onPressed: () => Navigator.pop(sheetContext, 'premium'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'shop') {
      Navigator.pushNamed(context, '/practice/shop');
      return;
    }
    if (action == 'premium') {
      await PracticePremiumOfferService.instance.showOffer(
        context,
        trigger: trigger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF9AA0A6),
        centerTitle: true,
        title: const Text(
          'AI Coach',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PracticeMascot(
                  size: 108,
                  mood: PracticeMascotMood.thinking,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: PracticeSpeechBubble(
                    text: 'Yanlış cevabı açıklayayım veya roleplay yapalim.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Neden yanlış?',
              color: practiceBlue,
              children: [
                _SmallField(controller: _question, label: 'Soru'),
                _SmallField(controller: _wrong, label: 'Benim cevabım'),
                _SmallField(controller: _correct, label: 'Doğru cevap'),
                const SizedBox(height: 12),
                PracticePrimaryButton(
                  label: _loadingExplain ? 'ACIKLANIYOR...' : 'AI ACIKLA',
                  color: practiceBlue,
                  onPressed: _loadingExplain ? null : () => _explain(),
                ),
                if (_explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _explanation,
                    style: const TextStyle(
                      color: practiceInk,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Roleplay',
              color: practiceGreen,
              children: [
                if (_messages.isEmpty)
                  PracticePrimaryButton(
                    label:
                        _loadingChat ? 'BAŞLIYOR...' : 'CAFE SENARYOSU BAŞLAT',
                    onPressed: _loadingChat ? null : () => _startRoleplay(),
                  )
                else
                  for (final message in _messages)
                    _ChatBubble(
                      mine: message['role'] == 'user',
                      text: message['content'] ?? '',
                    ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _roleplayInput,
                        decoration: InputDecoration(
                          hintText: 'Cevabını yaz...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _loadingChat ? null : () => _sendRoleplay(),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.color,
    required this.children,
  });

  final String title;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.mine, required this.text});

  final bool mine;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? practiceBlue : const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? Colors.white : practiceInk,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}
