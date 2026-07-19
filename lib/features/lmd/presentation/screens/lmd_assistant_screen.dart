import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/lmd_assistant.dart';
import '../../data/lmd_knowledge.dart';

class LmdAssistantScreen extends StatefulWidget {
  const LmdAssistantScreen({super.key});

  @override
  State<LmdAssistantScreen> createState() => _LmdAssistantScreenState();
}

class _LmdAssistantScreenState extends State<LmdAssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Msg>[
    const _Msg(
      isUser: false,
      text:
          'Je suis l’assistant LMD Akadex (contexte RDC). '
          'Je m’appuie sur le décret n° 22/39, la loi-cadre 14/004 et les '
          'directives MESU. Pose ta question !',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    final reply = LmdAssistant.answer(text);
    setState(() {
      _messages.add(_Msg(isUser: true, text: text));
      _messages.add(_Msg(isUser: false, text: reply.text));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkadexColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assistant LMD',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Contexte République démocratique du Congo',
              style: TextStyle(fontSize: 12, color: AkadexColors.inkMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Guide complet',
            onPressed: () => context.push('/lmd'),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: LmdKnowledge.suggestedQuestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final q = LmdKnowledge.suggestedQuestions[i];
                return ActionChip(
                  label: Text(q, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _send(q),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Align(
                  alignment:
                      m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.86,
                    ),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? AkadexColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: m.isUser
                          ? null
                          : Border.all(color: AkadexColors.border),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        height: 1.4,
                        color: m.isUser ? Colors.white : AkadexColors.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ex. Combien de crédits par semestre ?',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  const _Msg({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}
