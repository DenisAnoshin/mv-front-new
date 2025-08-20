import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart' show Ticker; 
import '../stores/chat_store.dart';
import '../stores/user_store.dart';
import '../theme/telegram_colors.dart';
import '../widgets/message_bubble.dart';
import '../widgets/audio_message.dart';
// import '../widgets/date_divider.dart';
import '../widgets/chat_background.dart';
import '../widgets/app_bar/chat_app_bar.dart';
import '../widgets/message_context_menu.dart';
import 'user_profile_page.dart';
import '../widgets/attachments/attachment_sheet.dart';
import '../widgets/emoji/emoji_panel.dart';
import '../widgets/recording/record_pulse.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatItem chat;
  const ChatDetailPage({super.key, required this.chat});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  Future<void>? _loadFuture;
  
  bool _hasText = false;

  // Edge-swipe back state
  double _backDragDx = 0.0; // current horizontal translation
  bool _backDragActive = false; // only when started from left edge
  late final AnimationController _backSlideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  Animation<double>? _backSlideTween;

  // AnimatedList state + local copy of messages to keep in sync
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _listInitialized = false;
  
  // Composer/emoji state
  final FocusNode _inputFocus = FocusNode();
  bool _emojiOpen = false;
  late final AnimationController _emojiController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  // Recording state
  bool _isRecording = false;
  bool _recordLocked = false;
  bool _isPaused = false;
  Duration _recordElapsed = Duration.zero;
  Duration _elapsedBase = Duration.zero;
  Ticker? _ticker;
  late final AnimationController _blinkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: 0.4,
    upperBound: 1.0,
  )..repeat(reverse: true);
  Offset? _pressOrigin;
  static const double _lockThreshold = 60.0; // drag up to lock
  // Arming phase (hold before crossing threshold)
  bool _isArming = false;
  double _micDragDy = 0.0; // negative when dragging up
  static const double _armThreshold = 50.0; // must reach to start recording

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
    _backSlideController.addListener(() {
      if (_backSlideTween != null) {
        setState(() {
          _backDragDx = _backSlideTween!.value;
        });
      }
    });
  }
  
  late final AnimationController _emptyIconController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  // Playback (preview while paused) state
  bool _isPlayingBack = false;
  double _playbackProgress = 0.0; // 0..1
  double _playBaseProgress = 0.0; // accumulated progress when paused
  Ticker? _playTicker;

  String _statusForAppBar(ChatItem chat) {
    switch (chat.type) {
      case ChatType.direct:
        return 'last seen recently';
      case ChatType.group:
        final count = chat.memberCount ?? chat.participantIds.length;
        return '$count members';
      case ChatType.channel:
        final count = chat.subscriberCount ?? (chat.participantIds.length * 100);
        return '$count subscribers';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _load(context);
  }

  Future<void> _load(BuildContext context) async {
    final me = context.read<UserStore>().currentUser!;
    final userStore = context.read<UserStore>();
    await context.read<ChatStore>().loadChatBundle(widget.chat.id, me, userStore: userStore);
  }

  Future<void> _send() async {
    final me = context.read<UserStore>().currentUser!;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await context.read<ChatStore>().sendMessage(chatId: widget.chat.id, text: text, me: me);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _closeEmojiIfOpen() {
    if (_emojiOpen) {
      setState(() {
        _emojiOpen = false;
        _emojiController.reverse();
      });
    }
  }

  void _toggleEmojiPanel() {
    setState(() {
      _emojiOpen = !_emojiOpen;
      if (_emojiOpen) {
        _inputFocus.unfocus();
        _emojiController.forward();
      } else {
        _emojiController.reverse();
        _inputFocus.requestFocus();
      }
    });
  }

  void _insertEmoji(String emoji) {
    final TextSelection sel = _controller.selection;
    final String text = _controller.text;
    if (sel.isValid) {
      final String newText = text.replaceRange(sel.start, sel.end, emoji);
      final int caret = sel.start + emoji.length;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: caret),
      );
    } else {
      _controller.text = text + emoji;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  // Recording helpers
  void _startTickerFromZero() {
    _ticker?.dispose();
    _ticker = createTicker((elapsed) {
      setState(() => _recordElapsed = _elapsedBase + elapsed);
    })..start();
  }

  void _startRecording(Offset globalPosition) {
    _closeEmojiIfOpen();
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordLocked = false;
      _recordElapsed = Duration.zero;
      _elapsedBase = Duration.zero;
      _pressOrigin = globalPosition;
      _isArming = false;
    });
    _startTickerFromZero();
  }

  void _lockRecording() {
    if (_recordLocked) return;
    setState(() => _recordLocked = true);
  }

  void _pauseRecording() {
    if (!_isRecording || _isPaused) return;
    _ticker?.dispose();
    _ticker = null;
    setState(() {
      _isPaused = true;
      _elapsedBase = _recordElapsed; // freeze time
    });
    _resetPlayback();
  }

  void _resumeRecording() {
    if (!_isRecording || !_isPaused) return;
    setState(() => _isPaused = false);
    _startTickerFromZero();
    _resetPlayback();
  }

  void _cancelRecording() {
    _ticker?.dispose();
    _ticker = null;
    _resetPlayback();
    setState(() {
      _isRecording = false;
      _recordLocked = false;
      _isPaused = false;
      _recordElapsed = Duration.zero;
      _elapsedBase = Duration.zero;
      _isArming = false;
      _micDragDy = 0.0;
    });
  }

  Future<void> _sendRecording() async {
    final me = context.read<UserStore>().currentUser!;
    final human = _formatDuration(_recordElapsed);
    _ticker?.dispose();
    _ticker = null;
    _resetPlayback();
    setState(() {
      _isRecording = false;
      _recordLocked = false;
      _isPaused = false;
      _isArming = false;
      _micDragDy = 0.0;
    });
    await context.read<ChatStore>().sendAudioMessage(
      chatId: widget.chat.id,
      durationSec: _recordElapsed.inSeconds,
      me: me,
      url: 'assets/mock/sample_audio.mp3',
      sizeBytes: (_recordElapsed.inSeconds * 9 * 1024),
    );
  }

  // Immediate pan (no hold) handlers
  void _onMicPanDown(DragDownDetails d) {
    _pressOrigin = d.globalPosition;
    setState(() {
      _isArming = true;
      _micDragDy = 0.0;
    });
  }

  void _onMicPanUpdate(DragUpdateDetails d) {
    if (_pressOrigin == null) return;
    final Offset gp = d.globalPosition;
    if (_isRecording) {
      if (_recordLocked) return;
      final dy = gp.dy - _pressOrigin!.dy;
      if (dy < -_lockThreshold) _lockRecording();
      return;
    }
    if (_isArming) {
      double dy = (gp.dy - _pressOrigin!.dy);
      if (dy > 0) dy = 0;
      dy = dy.clamp(-_armThreshold, 0).toDouble();
      setState(() => _micDragDy = dy);
      if (dy <= -_armThreshold) {
        _startRecording(gp);
        _lockRecording();
      }
    }
  }

  void _onMicPanEnd(DragEndDetails d) {
    if (_isArming && !_isRecording) {
      setState(() {
        _isArming = false;
        _micDragDy = 0.0;
      });
      return;
    }
    if (_isRecording && !_recordLocked) {
      _sendRecording();
    }
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString();
    final ss = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    final cs = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$mm:$ss,$cs';
  }

  // Playback controls for paused preview
  void _resetPlayback() {
    _playTicker?.dispose();
    _playTicker = null;
    _isPlayingBack = false;
    _playBaseProgress = 0.0;
    _playbackProgress = 0.0;
  }

  void _startPlayback() {
    if (_recordElapsed.inMilliseconds <= 0) return;
    _playTicker?.dispose();
    final int totalMs = _recordElapsed.inMilliseconds;
    _isPlayingBack = true;
    _playTicker = createTicker((elapsed) {
      final double p = (_playBaseProgress + elapsed.inMilliseconds / totalMs).clamp(0.0, 1.0);
      if (p >= 1.0) {
        _playBaseProgress = 0.0;
        _playbackProgress = 1.0;
        _playTicker?.dispose();
        _playTicker = null;
        setState(() {
          _isPlayingBack = false;
          _playbackProgress = 0.0; // rewind to start after finishing
          _playBaseProgress = 0.0;
        });
      } else {
        setState(() {
          _playbackProgress = p;
        });
      }
    })..start();
  }

  void _pausePlaybackPreview() {
    _playTicker?.dispose();
    _playTicker = null;
    _isPlayingBack = false;
    _playBaseProgress = _playbackProgress;
    setState(() {});
  }

  void _togglePlaybackPreview() {
    if (_isPlayingBack) {
      _pausePlaybackPreview();
    } else {
      _startPlayback();
    }
  }

  Widget _buildLivePreviewBubble({required String chatId, required String messageId}) {
    return Consumer2<ChatStore, UserStore>(
      builder: (context, chatStore, userStore, _) {
        final messages = chatStore.messagesFor(chatId);
        ChatMessage? m;
        for (final x in messages) {
          if (x.id == messageId) {
            m = x;
            break;
          }
        }
        if (m == null) return const SizedBox.shrink();
        final chat = widget.chat;
        String? senderName;
        if (!m.isMine && chat.type == ChatType.group) {
          senderName = userStore.usersById[m.senderId]?.displayName;
        } else if (!m.isMine && chat.type == ChatType.channel) {
          senderName = chat.title;
        }
        final body = m.kind == MessageKind.audio && m.audio != null
            ? AudioMessage(
                durationSec: m.audio!.durationSec,
                sizeBytes: m.audio!.sizeBytes,
                isMine: m.isMine,
                waveform: m.audio!.waveform,
              )
            : null;
        return MessageBubble(
          text: m.text,
          time: m.time,
          isMine: m.isMine,
          status: m.status,
          groupPosition: BubbleGroupPosition.single,
          senderName: senderName,
          reactions: m.reactions,
          myReactions: m.myReactions,
          body: body,
          isMedia: false,
          onTapReaction: (emoji) {
            final me = context.read<UserStore>().currentUser!;
            context.read<ChatStore>().toggleReaction(
                  chatId: chatId,
                  messageId: messageId,
                  emoji: emoji,
                  myUserId: me.id,
                );
          },
        );
      },
    );
  }

  Widget _buildPreviewBubble(ChatMessage m) {
    final chat = widget.chat;
    String? senderName;
    if (!m.isMine && chat.type == ChatType.group) {
      final users = context.read<UserStore>().usersById;
      senderName = users[m.senderId]?.displayName;
    } else if (!m.isMine && chat.type == ChatType.channel) {
      senderName = chat.title;
    }
    final body = m.kind == MessageKind.audio && m.audio != null
        ? AudioMessage(
            durationSec: m.audio!.durationSec,
            sizeBytes: m.audio!.sizeBytes,
            isMine: m.isMine,
            waveform: m.audio!.waveform,
          )
        : null;
    return MessageBubble(
      text: m.text,
      time: m.time,
      isMine: m.isMine,
      status: m.status,
      groupPosition: BubbleGroupPosition.single,
      senderName: senderName,
      reactions: m.reactions,
      myReactions: m.myReactions,
      body: body,
      isMedia: false,
    );
  }

  void _openContextMenu({required BuildContext context, required Rect bubbleRect, required ChatMessage message}) {
    final chat = widget.chat;
    final me = context.read<UserStore>().currentUser!;
    final showReadInfo = message.isMine && message.status == MessageStatus.read;
    final readText = showReadInfo ? 'read ${_formatDateTime(message.time.add(const Duration(minutes: 1)))}' : null;

    final reactions = ['❤️', '👍', '🔥', '🤝', '😱', '😁', '🕊️', '✅'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ctx',
      barrierColor: Colors.transparent, // disable default dimming
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final p = Curves.easeOutCubic.transform(anim.value);
        return MessageContextMenu(
          anchorRect: bubbleRect,
          reactionEmojis: reactions,
          onTapReaction: (emoji) {
            context.read<ChatStore>().toggleReaction(
                  chatId: chat.id,
                  messageId: message.id,
                  emoji: emoji,
                  myUserId: me.id,
                );
          },
          onReply: () => Navigator.of(ctx).pop(),
          onCopy: () {
            Navigator.of(ctx).pop();
            Clipboard.setData(ClipboardData(text: message.text));
          },
          onPin: () => Navigator.of(ctx).pop(),
          onForward: () => Navigator.of(ctx).pop(),
          onDelete: () {
            context.read<ChatStore>().deleteMessage(chatId: chat.id, messageId: message.id);
            Navigator.of(ctx).pop();
          },
          showReadInfo: showReadInfo,
          readAtText: readText,
          messagePreview: _buildLivePreviewBubble(chatId: chat.id, messageId: message.id),
          progress: p,
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year.toString().substring(2)}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d at $t';
  }

  @override
  void dispose() {
    _emptyIconController.dispose();
    _emojiController.dispose();
    _inputFocus.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _ticker?.dispose();
    _blinkController.dispose();
    _backSlideController.dispose();
    super.dispose();
  }

  void _openAttachmentSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'attach',
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        // Fade backdrop via anim, sheet anim handled inside widget
        final opacity = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return Opacity(
          opacity: opacity.value,
          child: const AttachmentSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = _backDragDx.clamp(0.0, screenWidth);
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(dx, 0),
          child: Scaffold(
            backgroundColor: TelegramColors.chatBackground,
            appBar: ChatAppBar(
              title: chat.title,
              status: _statusForAppBar(chat),
              onBack: () => Navigator.of(context).pop(),
              onOpenProfile: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => UserProfilePage(title: chat.title)),
              ),
            ),
            body: ChatBackground(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: FutureBuilder<void>(
                          future: _loadFuture,
                          builder: (context, snapshot) {
                            return Consumer<ChatStore>(
                              builder: (context, store, _) {
                                final List<ChatMessage> next = store.messagesFor(chat.id);
                                final List<ChatMessage> nextRev = next.reversed.toList();
                                final isLoading = snapshot.connectionState != ConnectionState.done && nextRev.isEmpty;
                                if (isLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(TelegramColors.primary),
                                    ),
                                  );
                                }

                                if (!_listInitialized && nextRev.isEmpty) {
                                  return _emptyState();
                                }

                                // Initialize local list once when data arrives the first time
                                if (!_listInitialized) {
                                  _messages = List<ChatMessage>.from(nextRev);
                                  _listInitialized = true;
                                } else {
                                  // After first build, keep AnimatedList in sync with store
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _syncAnimatedListWith(nextRev);
                                  });
                                }

                                return GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _closeEmojiIfOpen,
                                  child: AnimatedList(
                                    key: _animatedListKey,
                                    controller: _scrollController,
                                    reverse: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    initialItemCount: _messages.length,
                                    itemBuilder: (context, index, animation) {
                                      return _buildAnimatedItem(index: index, animation: animation);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: Colors.transparent),
                      SafeArea(
                        top: false,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _isPaused
                              ? _buildPausedBar()
                              : _isRecording
                                  ? _buildRecordingBar()
                                  : _buildComposer(),
                        ),
                      ),
                      // Sliding emoji panel under the composer
                      ClipRect(
                        child: SizeTransition(
                          sizeFactor: CurvedAnimation(parent: _emojiController, curve: Curves.easeOutCubic),
                          axisAlignment: -1.0,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeOutCubic))
                                .animate(_emojiController),
                            child: EmojiPanel(
                              rounded: false,
                              onSelect: (e) => _insertEmoji(e),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isRecording && !_isPaused)
                    Positioned(
                      right: -18,
                      bottom: -6,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 6),
                          child: RecordPulse(
                            size: 82,
                            color: TelegramColors.primary,
                            rings: 4,
                            center: const Icon(Icons.arrow_upward, color: Colors.white, size: 30),
                            onTapCenter: _sendRecording,
                          ),
                        ),
                      ),
                    ),
                  // Put overlay last to be on top for reliable taps
                  _buildRecordOverlay(),
                ],
              ),
            ),
          ),
        ),
        // Fullscreen horizontal drag detector; activates only if gesture starts near left edge
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (details) {
              final dxStart = details.localPosition.dx;
              _backDragActive = dxStart <= 80.0; // activate only from left 80px
              if (_backDragActive) {
                _backSlideController.stop();
              }
            },
            onHorizontalDragUpdate: (details) {
              if (!_backDragActive) return;
              final dxDelta = details.primaryDelta ?? 0.0;
              if (dxDelta <= 0 && _backDragDx <= 0) return;
              setState(() {
                _backDragDx = (_backDragDx + dxDelta).clamp(0.0, screenWidth);
              });
            },
            onHorizontalDragEnd: (details) {
              if (!_backDragActive) return;
              _backDragActive = false;
              final velocity = details.primaryVelocity ?? 0.0; // >0 => swipe right
              final shouldPopByVelocity = velocity > 600;
              final shouldPopByDistance = _backDragDx > screenWidth * 0.33;
              if (shouldPopByVelocity || shouldPopByDistance) {
                _backSlideTween = Tween<double>(begin: _backDragDx, end: screenWidth)
                    .animate(CurvedAnimation(parent: _backSlideController, curve: Curves.easeOutCubic));
                _backSlideController
                  ..value = 0
                  ..forward().whenComplete(() {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
              } else {
                _backSlideTween = Tween<double>(begin: _backDragDx, end: 0.0)
                    .animate(CurvedAnimation(parent: _backSlideController, curve: Curves.easeOutCubic));
                _backSlideController
                  ..value = 0
                  ..forward();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComposer() {
    return Container(
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openAttachmentSheet,
            child: const Icon(Icons.attach_file, color: TelegramColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: TelegramColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        focusNode: _inputFocus,
                        controller: _controller,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Write a message...',
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onTap: _closeEmojiIfOpen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleEmojiPanel,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: _emojiOpen ? 0.5 : 0.0,
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        color: _emojiOpen ? TelegramColors.primary : TelegramColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.linear,
            switchOutCurve: Curves.linear,
            transitionBuilder: (child, animation) {
              final isSend = child.key == const ValueKey('send_btn');
              final scale = animation.drive(
                Tween<double>(
                  begin: isSend ? 0.6 : 1.0,
                  end: isSend ? 1.0 : 0.8,
                ).chain(CurveTween(curve: isSend ? Curves.elasticOut : Curves.easeInBack)),
              );
              final fade = animation.drive(
                Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
              );
              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: _hasText
                ? GestureDetector(
                    key: const ValueKey('send_btn'),
                    onTap: _send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: TelegramColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: Colors.white, size: 22),
                    ),
                  )
                : Transform.translate(
                    offset: Offset(0, _isArming ? _micDragDy : 0),
                    child: GestureDetector(
                      key: const ValueKey('mic_btn'),
                      onPanDown: _onMicPanDown,
                      onPanUpdate: _onMicPanUpdate,
                      onPanEnd: _onMicPanEnd,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: TelegramColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    final time = _formatDuration(_recordElapsed);
    return Material(
      color: const Color(0xFFF5F5F7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
        child: Row(
          children: [
            // Left: blinking red dot + time
            AnimatedBuilder(
              animation: _blinkController,
              builder: (_, __) {
                return Opacity(
                  opacity: _blinkController.value,
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            // Center: Cancel (as in Telegram)
            TextButton(
              onPressed: _cancelRecording,
              child: const Text('Cancel'),
            ),
            const Spacer(),
            // Right: Send
            GestureDetector(
              onTap: _sendRecording,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: TelegramColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedBar() {
    // Simple mock waveform
    final bars = List.generate(28, (i) => (i % 4 == 0) ? 16.0 : (8.0 + (i % 5))); 
    return Material(
      color: const Color(0xFFF5F5F7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
        child: Row(
          children: [
            // Trash
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: TelegramColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            // Waveform full width with centered play/pause overlay and progress
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TelegramColors.divider),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double trackWidth = constraints.maxWidth - 24; // visual padding
                    final double progressX = (trackWidth * _playbackProgress).clamp(0.0, trackWidth);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Wave bars background across full width
                        SizedBox(
                          height: 28,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (final h in bars) ...[
                                Container(width: 3, height: h, margin: const EdgeInsets.symmetric(horizontal: 1.2), color: const Color(0xFF90CAF9)),
                              ]
                            ],
                          ),
                        ),
                        // Progress indicator line
                        Positioned(
                          left: 12 + progressX - 1,
                          top: 6,
                          bottom: 6,
                          child: Container(width: 2, color: TelegramColors.primary.withOpacity(0.6)),
                        ),
                        // Center play/pause overlay
                        GestureDetector(
                          onTap: _togglePlaybackPreview,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: TelegramColors.primary, shape: BoxShape.circle),
                            child: Icon(_isPlayingBack ? Icons.pause : Icons.play_arrow, color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send
            GestureDetector(
              onTap: _sendRecording,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: TelegramColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Сообщений пока нет',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: TelegramColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Напишите первым или отправьте этот стикер',
              textAlign: TextAlign.center,
              style: TextStyle(color: TelegramColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 72,
              height: 72,
              child: AnimatedBuilder(
                animation: _emptyIconController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _emptyIconController.value * 6.283185307179586, // 2*pi
                    child: child,
                  );
                },
                child: const Icon(Icons.auto_awesome, size: 72, color: Color(0xFF8CB885)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AnimatedList helper: build appearing item with jelly effect
  Widget _buildAnimatedItem({required int index, required Animation<double> animation}) {
    final curvedSize = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final jelly = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return SizeTransition(
      sizeFactor: curvedSize,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(jelly),
            child: _buildRow(_messages, index),
          ),
        ),
      ),
    );
  }

  // AnimatedList remove builder
  Widget _buildRemovedItem(ChatMessage removed, Animation<double> animation) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    final size = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    return SizeTransition(
      sizeFactor: size,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.0), end: const Offset(0, -0.06))
              .chain(CurveTween(curve: Curves.easeIn))
              .animate(animation),
          child: _buildPreviewBubble(removed),
        ),
      ),
    );
  }

  void _syncAnimatedListWith(List<ChatMessage> next) {
    if (_animatedListKey.currentState == null) return;

    // 1) handle removals from end to start to keep indices valid
    final nextIds = next.map((m) => m.id).toSet();
    for (int i = _messages.length - 1; i >= 0; i--) {
      final id = _messages[i].id;
      if (!nextIds.contains(id)) {
        final removed = _messages.removeAt(i);
        _animatedListKey.currentState!.removeItem(
          i,
          (context, animation) => _buildRemovedItem(removed, animation),
          duration: const Duration(milliseconds: 260),
        );
      }
    }

    // 2) handle insertions from start to end
    final currentIds = _messages.map((m) => m.id).toSet();
    for (int i = 0; i < next.length; i++) {
      final id = next[i].id;
      if (!currentIds.contains(id)) {
        _messages.insert(i, next[i]);
        _animatedListKey.currentState!.insertItem(
          i,
          duration: const Duration(milliseconds: 320),
        );
      }
    }
  }

  Widget _buildRow(List<ChatMessage> messages, int index) {
    final m = messages[index];
    final isMine = m.isMine;

    // Determine position within a block of the same author
    BubbleGroupPosition position = BubbleGroupPosition.single;
    final prev = index > 0 ? messages[index - 1] : null;
    final next = index + 1 < messages.length ? messages[index + 1] : null;
    final prevSame = prev != null && prev.isMine == isMine && prev.senderId == m.senderId;
    final nextSame = next != null && next.isMine == isMine && next.senderId == m.senderId;
    if (prevSame && nextSame) {
      position = BubbleGroupPosition.middle;
    } else if (!prevSame && nextSame) {
      position = BubbleGroupPosition.first;
    } else if (prevSame && !nextSame) {
      position = BubbleGroupPosition.last;
    }

    final chat = widget.chat;
    String? senderName;
    final isFirstOrSingle = position == BubbleGroupPosition.first || position == BubbleGroupPosition.single;
    if (!isMine && chat.type == ChatType.group && isFirstOrSingle) {
      final users = context.read<UserStore>().usersById;
      senderName = users[m.senderId]?.displayName;
    } else if (!isMine && chat.type == ChatType.channel && isFirstOrSingle) {
      senderName = chat.title;
    }

    final me = context.read<UserStore>().currentUser!;

    // Render bubble with live data from store by message id
    final bubble = Consumer<ChatStore>(
      builder: (context, store, _) {
        ChatMessage live = m;
        final list = store.messagesFor(chat.id);
        for (final x in list) {
          if (x.id == m.id) {
            live = x;
            break;
          }
        }
        final body = live.kind == MessageKind.audio && live.audio != null
            ? AudioMessage(
                durationSec: live.audio!.durationSec,
                sizeBytes: live.audio!.sizeBytes,
                isMine: isMine,
                waveform: live.audio!.waveform,
              )
            : null;
        return MessageBubble(
          text: live.text,
          time: live.time,
          isMine: isMine,
          status: live.status,
          groupPosition: position,
          senderName: senderName,
          reactions: live.reactions,
          myReactions: live.myReactions,
          body: body,
          isMedia: false,
          onTap: _closeEmojiIfOpen,
          onTapReaction: (emoji) {
            context.read<ChatStore>().toggleReaction(
                  chatId: chat.id,
                  messageId: live.id,
                  emoji: emoji,
                  myUserId: me.id,
                );
          },
          onLongPress: () {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final pos = box.localToGlobal(Offset.zero);
            final rect = Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
            _openContextMenu(context: context, bubbleRect: rect, message: live);
          },
        );
      },
    );

    final leftInset = isMine ? 60.0 : 6.0;
    final rightInset = isMine ? 6.0 : 60.0;
    return Padding(
      padding: EdgeInsets.only(
        left: leftInset,
        right: rightInset,
        top: prevSame ? 1.5 : 4,
        bottom: nextSame ? 1.5 : 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(child: bubble),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildRecordOverlay() {
    // Only show overlay controls during active recording and not paused
    if (!_isRecording || _isPaused) return const SizedBox.shrink();

    // Base position roughly where the mic button sits
    const double baseRight = 12; // composer horizontal padding
    const double baseBottom = 30 + 8; // composer bottom padding + small gap

    // Slightly above send button baseline
    const double translateY = -_armThreshold - 12;

    final bool showPause = true; // here overlay is visible only when not paused
    final bool showMicToResume = false;

    return Positioned(
      right: baseRight,
      bottom: baseBottom,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        offset: Offset(0, translateY / 40.0),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) {},
          onTap: () {
            if (showPause) {
              _pauseRecording();
            } else if (showMicToResume) {
              _resumeRecording();
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              final jelly = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
              return ScaleTransition(scale: jelly, child: child);
            },
            child: Container(
              key: ValueKey(showPause ? 'pause' : (showMicToResume ? 'mic_resume' : 'mic')),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: TelegramColors.primary, shape: BoxShape.circle),
              child: Icon(showPause ? Icons.pause : Icons.mic, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}