import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/models/messaging_models.dart';
import '../../../../data/repositories/messaging_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  List<ChatMessage> _messages = [];
  ChatConversation? _conversation;
  bool _loading = true;
  String? _error;
  bool _searchOpen = false;
  String _searchQuery = '';
  bool _sending = false;
  bool _recording = false;
  DateTime? _recordingStartedAt;
  String? _recordingPath;
  Timer? _pollTimer;
  Timer? _typingDebounce;
  Timer? _typingClearTimer;
  Timer? _recordTick;
  Duration _recordElapsed = Duration.zero;
  bool _typingSent = false;
  String? _playingMessageId;
  Duration _playPosition = Duration.zero;
  Duration _playDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  String get _conversationId => widget.conversationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(_onComposeChanged);
    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _playPosition = pos);
    });
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _playingMessageId = null;
            _playPosition = Duration.zero;
          });
        }
      }
    });
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    _typingClearTimer?.cancel();
    _recordTick?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _textController.removeListener(_onComposeChanged);
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    unawaited(_clearTyping());
    unawaited(_audioRecorder.dispose());
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      unawaited(_pollOnce());
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
      unawaited(_clearTyping());
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final messages = await repo.fetchMessages(_conversationId);
      final poll = await repo.poll(_conversationId);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!mounted) return;
      setState(() {
        _messages = _mergeMessages(messages, poll.messages);
        _conversation = poll.conversation;
        _loading = false;
      });
      await repo.markRead(_conversationId);
      _startPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e);
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 2500),
      (_) => _pollOnce(),
    );
  }

  Future<void> _pollOnce() async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      // Sans `after` : snapshot récent (≤100) pour rafraîchir ticks + activité.
      final result = await repo.poll(_conversationId);
      if (!mounted) return;

      final me = ref.read(authStateProvider).valueOrNull?.id;
      final previousIds = _messages.map((m) => m.id).toSet();
      final merged = _mergeMessages(_messages, result.messages);
      final hadIncoming = result.messages.any(
        (m) =>
            me != null &&
            m.senderId != me &&
            !previousIds.contains(m.id),
      );

      setState(() {
        _conversation = result.conversation;
        _messages = merged;
      });

      if (hadIncoming) {
        await repo.markRead(_conversationId);
        _scrollToEnd(animated: true);
      }
    } catch (_) {
      // Silent — next poll retries
    }
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> existing,
    List<ChatMessage> incoming,
  ) {
    final map = <String, ChatMessage>{
      for (final m in existing) m.id: m,
    };
    for (final m in incoming) {
      map[m.id] = m;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  void _onComposeChanged() {
    setState(() {});
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _typingDebounce?.cancel();
      if (_typingSent) unawaited(_clearTyping());
      return;
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted || _textController.text.trim().isEmpty) return;
      try {
        await ref.read(messagingRepositoryProvider).setTyping(
              conversationId: _conversationId,
              isTyping: true,
            );
        _typingSent = true;
        _typingClearTimer?.cancel();
        _typingClearTimer = Timer(const Duration(seconds: 4), () {
          unawaited(_clearTyping());
        });
      } catch (_) {}
    });
  }

  Future<void> _clearTyping() async {
    if (!_typingSent) return;
    _typingSent = false;
    try {
      await ref.read(messagingRepositoryProvider).setTyping(
            conversationId: _conversationId,
            isTyping: false,
            isRecording: false,
          );
    } catch (_) {}
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    await _clearTyping();
    try {
      final msg = await ref.read(messagingRepositoryProvider).sendText(
            conversationId: _conversationId,
            content: text,
          );
      if (!mounted) return;
      setState(() {
        _messages = _mergeMessages(_messages, [msg]);
        _sending = false;
      });
      _scrollToEnd(animated: true);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _textController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<bool> _ensureMicPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autorise le micro pour enregistrer un vocal.'),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (_recording || _sending) return;
    if (!await _ensureMicPermission()) return;
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Micro non disponible.')),
        );
      }
      return;
    }

    try {
      String path;
      if (kIsWeb) {
        path = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        final dir = await getTemporaryDirectory();
        path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      await ref.read(messagingRepositoryProvider).setTyping(
            conversationId: _conversationId,
            isRecording: true,
          );
      _typingSent = true;

      setState(() {
        _recording = true;
        _recordingPath = path;
        _recordingStartedAt = DateTime.now();
        _recordElapsed = Duration.zero;
      });
      HapticFeedback.mediumImpact();

      _recordTick?.cancel();
      _recordTick = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (_recordingStartedAt == null) return;
        setState(() {
          _recordElapsed = DateTime.now().difference(_recordingStartedAt!);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _recordTick?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    await _clearTyping();
    final path = _recordingPath;
    if (path != null && !kIsWeb) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordingPath = null;
      _recordingStartedAt = null;
      _recordElapsed = Duration.zero;
    });
  }

  Future<void> _stopAndSendRecording() async {
    if (!_recording) return;
    _recordTick?.cancel();
    final started = _recordingStartedAt ?? DateTime.now();
    final path = _recordingPath;
    String? stoppedPath;
    try {
      stoppedPath = await _audioRecorder.stop();
    } catch (_) {}
    final filePath = stoppedPath ?? path;
    final durationMs =
        DateTime.now().difference(started).inMilliseconds.clamp(500, 600000);

    setState(() {
      _recording = false;
      _recordingPath = null;
      _recordingStartedAt = null;
      _recordElapsed = Duration.zero;
    });
    await _clearTyping();

    if (filePath == null || filePath.isEmpty) return;
    if (durationMs < 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message vocal trop court.')),
        );
      }
      return;
    }

    setState(() => _sending = true);
    try {
      XFile? xfile;
      if (kIsWeb) {
        final bytes = await XFile(filePath).readAsBytes();
        xfile = XFile.fromData(
          bytes,
          name: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
          mimeType: 'audio/mp4',
        );
      }
      final msg = await ref.read(messagingRepositoryProvider).sendAudio(
            conversationId: _conversationId,
            filePath: filePath,
            durationMs: durationMs,
            file: xfile,
          );
      if (!mounted) return;
      setState(() {
        _messages = _mergeMessages(_messages, [msg]);
        _sending = false;
      });
      _scrollToEnd(animated: true);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _toggleAudio(ChatMessage message) async {
    final url = message.attachmentUrl;
    if (url.isEmpty) return;

    if (_playingMessageId == message.id) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      setState(() {});
      return;
    }

    try {
      await _audioPlayer.setUrl(url);
      final dur = _audioPlayer.duration ??
          Duration(milliseconds: message.audioDurationMs);
      setState(() {
        _playingMessageId = message.id;
        _playDuration = dur;
        _playPosition = Duration.zero;
      });
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searchQuery = query);
    if (query.trim().isEmpty) {
      try {
        final msgs = await ref
            .read(messagingRepositoryProvider)
            .fetchMessages(_conversationId);
        msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        if (!mounted) return;
        setState(() => _messages = msgs);
      } catch (_) {}
      return;
    }
    try {
      final msgs = await ref.read(messagingRepositoryProvider).fetchMessages(
            _conversationId,
            search: query,
          );
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!mounted) return;
      setState(() => _messages = msgs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  void _scrollToEnd({bool animated = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target + 80);
    }
  }

  String _presenceLabel(ChatPeer? peer) {
    if (peer == null) return '';
    if (peer.isOnline) return 'En ligne';
    final seen = peer.lastSeenAt;
    if (seen == null) return 'Hors ligne';
    final local = seen.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Vu à l’instant';
    if (diff.inMinutes < 60) return 'Vu il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Vu il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Vu hier';
    return 'Vu ${DateFormat('dd/MM').format(local)}';
  }

  List<ChatMessage> get _visibleMessages {
    if (_searchQuery.trim().isEmpty) return _messages;
    final q = _searchQuery.trim().toLowerCase();
    return _messages
        .where((m) => m.content.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final conv = _conversation;
    final peer = conv?.peer;
    final hasText = _textController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF8),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: _searchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher dans la conversation…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AkadexColors.inkSoft),
                ),
                onChanged: (v) {
                  _typingDebounce?.cancel();
                  _typingDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () => _runSearch(v),
                  );
                },
              )
            : Row(
                children: [
                  _ChatAvatar(
                    name: conv?.displayName ?? '…',
                    avatarUrl: conv?.avatarUrl ?? '',
                    size: 38,
                    online: peer?.isOnline == true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv?.displayName ?? 'Conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AkadexColors.ink,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            _activityOrPresence(conv, peer),
                            key: ValueKey(_activityOrPresence(conv, peer)),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: (conv?.peerIsTyping == true ||
                                      conv?.peerIsRecording == true ||
                                      peer?.isOnline == true)
                                  ? AkadexColors.primary
                                  : AkadexColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Fermer' : 'Rechercher',
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchController.clear();
                  _runSearch('');
                }
              });
            },
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(me?.id),
          ),
          _ComposerBar(
            controller: _textController,
            focusNode: _focusNode,
            hasText: hasText,
            sending: _sending,
            recording: _recording,
            recordElapsed: _recordElapsed,
            onSend: _sendText,
            onMicDown: _startRecording,
            onMicUp: _stopAndSendRecording,
            onMicCancel: _cancelRecording,
          ),
        ],
      ),
    );
  }

  String _activityOrPresence(ChatConversation? conv, ChatPeer? peer) {
    if (conv?.peerIsRecording == true) {
      return 'en train d’enregistrer un message vocal…';
    }
    if (conv?.peerIsTyping == true) return 'en train d’écrire…';
    return _presenceLabel(peer);
  }

  Widget _buildBody(String? myId) {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _bootstrap,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final messages = _visibleMessages;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: AkadexColors.primary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Aucun message trouvé'
                    : 'Dis bonjour 👋',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AkadexColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Essaie un autre mot-clé.'
                    : 'Envoie le premier message de cette conversation.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AkadexColors.inkMuted),
              ),
            ],
          ),
        ),
      );
    }

    final items = _buildTimelineItems(messages);

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _DateSep) {
          return _DateSeparator(label: item.label);
        }
        final msg = (item as _MsgItem).message;
        final mine = myId != null && msg.senderId == myId;
        return _MessageBubble(
          message: msg,
          mine: mine,
          playing: _playingMessageId == msg.id && _audioPlayer.playing,
          playPosition: _playingMessageId == msg.id
              ? _playPosition
              : Duration.zero,
          playDuration: _playingMessageId == msg.id
              ? (_playDuration.inMilliseconds > 0
                  ? _playDuration
                  : Duration(milliseconds: msg.audioDurationMs))
              : Duration(milliseconds: msg.audioDurationMs),
          onToggleAudio: () => _toggleAudio(msg),
        );
      },
    );
  }

  List<Object> _buildTimelineItems(List<ChatMessage> messages) {
    final items = <Object>[];
    DateTime? lastDay;
    for (final m in messages) {
      final local = m.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (lastDay == null || day != lastDay) {
        items.add(_DateSep(_formatDateSep(day)));
        lastDay = day;
      }
      items.add(_MsgItem(m));
    }
    return items;
  }

  String _formatDateSep(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Aujourd’hui';
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    return DateFormat('EEEE d MMMM', 'fr_FR').format(day);
  }
}

class _DateSep {
  _DateSep(this.label);
  final String label;
}

class _MsgItem {
  _MsgItem(this.message);
  final ChatMessage message;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AkadexColors.border.withValues(alpha: 0.7)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AkadexColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.playing,
    required this.playPosition,
    required this.playDuration,
    required this.onToggleAudio,
  });

  final ChatMessage message;
  final bool mine;
  final bool playing;
  final Duration playPosition;
  final Duration playDuration;
  final VoidCallback onToggleAudio;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());
    final bubbleColor = mine ? AkadexColors.primary : Colors.white;
    final textColor = mine ? Colors.white : AkadexColors.ink;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 3,
            bottom: 3,
            left: mine ? 40 : 4,
            right: mine ? 4 : 40,
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: message.isAudio
                    ? const EdgeInsets.fromLTRB(10, 10, 14, 10)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 6),
                    bottomRight: Radius.circular(mine ? 6 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AkadexColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: mine
                      ? null
                      : Border.all(
                          color: AkadexColors.border.withValues(alpha: 0.9),
                        ),
                ),
                child: message.isAudio
                    ? _AudioBubbleContent(
                        mine: mine,
                        playing: playing,
                        position: playPosition,
                        duration: playDuration.inMilliseconds > 0
                            ? playDuration
                            : Duration(milliseconds: message.audioDurationMs),
                        onToggle: onToggleAudio,
                      )
                    : Text(
                        message.content,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AkadexColors.inkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    _DeliveryTicks(status: message.deliveryStatus),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryTicks extends StatelessWidget {
  const _DeliveryTicks({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isRead = status == 'read';
    final isDelivered = status == 'delivered' || isRead;
    final color = isRead ? const Color(0xFF4A9BFF) : AkadexColors.inkSoft;

    if (!isDelivered) {
      return Icon(Icons.check_rounded, size: 14, color: color);
    }
    return Icon(Icons.done_all_rounded, size: 15, color: color);
  }
}

class _AudioBubbleContent extends StatelessWidget {
  const _AudioBubbleContent({
    required this.mine,
    required this.playing,
    required this.position,
    required this.duration,
    required this.onToggle,
  });

  final bool mine;
  final bool playing;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds.clamp(1, 1 << 30);
    final progress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final fg = mine ? Colors.white : AkadexColors.primary;
    final track = mine
        ? Colors.white.withValues(alpha: 0.28)
        : AkadexColors.primary.withValues(alpha: 0.15);
    final label = _fmt(playing || position.inMilliseconds > 0
        ? position
        : duration);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: mine
                  ? Colors.white.withValues(alpha: 0.2)
                  : AkadexColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: fg,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: track,
                  color: fg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.sending,
    required this.recording,
    required this.recordElapsed,
    required this.onSend,
    required this.onMicDown,
    required this.onMicUp,
    required this.onMicCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final bool sending;
  final bool recording;
  final Duration recordElapsed;
  final VoidCallback onSend;
  final Future<void> Function() onMicDown;
  final Future<void> Function() onMicUp;
  final Future<void> Function() onMicCancel;

  @override
  Widget build(BuildContext context) {
    final mm = recordElapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = recordElapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: AkadexColors.border.withValues(alpha: 0.8),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: recording
            ? Row(
                children: [
                  IconButton(
                    onPressed: () => onMicCancel(),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AkadexColors.danger),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AkadexColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          _PulseDot(),
                          const SizedBox(width: 10),
                          Text(
                            'Enregistrement $mm:$ss',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AkadexColors.danger,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Relâche pour envoyer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AkadexColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundAction(
                    color: AkadexColors.primary,
                    icon: Icons.send_rounded,
                    onTap: () => onMicUp(),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AkadexColors.primaryMist,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AkadexColors.border.withValues(alpha: 0.9),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintStyle: TextStyle(color: AkadexColors.inkSoft),
                        ),
                        style: const TextStyle(
                          color: AkadexColors.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                        ),
                        onSubmitted: (_) {
                          if (hasText) onSend();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasText)
                    _RoundAction(
                      color: AkadexColors.primary,
                      icon: sending
                          ? null
                          : Icons.send_rounded,
                      loading: sending,
                      onTap: sending ? null : onSend,
                    )
                  else
                    GestureDetector(
                      onLongPressStart: (_) => onMicDown(),
                      onLongPressEnd: (_) => onMicUp(),
                      onTap: () => onMicDown(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AkadexColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AkadexColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.color,
    this.icon,
    this.onTap,
    this.loading = false,
  });

  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AkadexColors.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.name,
    required this.avatarUrl,
    this.size = 40,
    this.online = false,
  });

  final String name;
  final String avatarUrl;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AkadexColors.brandGradient,
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _initial(initial),
                  placeholder: (_, _) => _initial(initial),
                )
              : _initial(initial),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: AkadexColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initial(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// Splash : démarre une conversation avec [userId] puis redirige vers le chat.
class StartConversationScreen extends ConsumerStatefulWidget {
  const StartConversationScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<StartConversationScreen> createState() =>
      _StartConversationScreenState();
}

class _StartConversationScreenState
    extends ConsumerState<StartConversationScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      if (!mounted) return;
      context.go('/login');
      return;
    }
    try {
      final conv = await ref
          .read(messagingRepositoryProvider)
          .startConversation(widget.userId);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      context.replace('/messages/chat/${conv.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkadexColors.background,
      body: Center(
        child: _error == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Ouverture de la conversation…',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AkadexColors.inkMuted,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _start();
                      },
                      child: const Text('Réessayer'),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
