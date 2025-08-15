import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
// import 'package:characters/characters.dart';
import '../theme/telegram_colors.dart';
import '../stores/chat_store.dart';
import '../stores/user_store.dart';

class MessageBubble extends StatefulWidget {
  final String text;
  final DateTime time;
  final bool isMine;
  final MessageStatus? status;
  // Optional custom body to render instead of plain text (e.g. audio message)
  final Widget? body;
  // When content is media (image/video) we use compact styling without inner padding/background
  final bool isMedia;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  // Добавлено: позиция в группе сообщений одного отправителя для скруглений
  final BubbleGroupPosition groupPosition;
  // Добавлено: имя отправителя (для групп/каналов)
  final String? senderName;
  // Реакции и мои реакции (emoji -> set of userIds)
  final Map<String, Set<String>> reactions;
  final Set<String> myReactions;
  // Коллбек на нажатие реакции
  final void Function(String emoji)? onTapReaction;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMine,
    this.body,
    this.status,
    this.onTap,
    this.onLongPress,
    this.groupPosition = BubbleGroupPosition.single,
    this.senderName,
    this.reactions = const <String, Set<String>>{},
    this.myReactions = const <String>{},
    this.onTapReaction,
    this.isMedia = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  Timer? _holdTimer;
  final GlobalKey _reactionsKey = GlobalKey();

  void _animateTo(double target) {
    setState(() => _scale = target);
  }

  void _startHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 220), () {
      widget.onLongPress?.call();
    });
  }

  void _cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  bool _isPointInsideReactions(Offset globalPos) {
    final ctx = _reactionsKey.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return false;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height);
    return rect.contains(globalPos);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _statusIcon() {
    switch (widget.status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 14, color: TelegramColors.textSecondary);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: TelegramColors.textSecondary);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Color(0xFF4FC3F7));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInitialAvatar(String userId, Map<String, UserProfile> users, {double size = 18}) {
    final name = users[userId]?.displayName ?? userId.replaceAll('u_', '');
    final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    // Generate consistent color by userId
    final hash = userId.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final bg = HSLColor.fromAHSL(1.0, hue, 0.55, 0.60).toColor();
    final textColor = bg.computeLuminance() > 0.6 ? const Color(0xFF222222) : Colors.white;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1), // separate overlapped avatars
      ),
      child: Text(letter, style: TextStyle(fontSize: size * 0.6, color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    final bubbleColor = widget.isMedia
        ? Colors.transparent
        : (isMine ? TelegramColors.messageOutgoing : TelegramColors.messageIncoming);
    final textColor = TelegramColors.textPrimary;
    // Радиусы зависят от позиции в группе
    final Radius tight = const Radius.circular(6);
    final Radius wide = const Radius.circular(16);
    BorderRadius radius;
    if (isMine) {
      // Хвост справа
      switch (widget.groupPosition) {
        case BubbleGroupPosition.single:
          radius = const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(6),
          );
          break;
        case BubbleGroupPosition.first:
          radius = BorderRadius.only(topLeft: wide, topRight: wide, bottomLeft: wide, bottomRight: tight);
          break;
        case BubbleGroupPosition.middle:
          radius = BorderRadius.only(topLeft: wide, topRight: wide, bottomLeft: wide, bottomRight: tight);
          break;
        case BubbleGroupPosition.last:
          radius = BorderRadius.only(topLeft: wide, topRight: wide, bottomLeft: wide, bottomRight: tight);
          break;
      }
    } else {
      // Хвост слева
      switch (widget.groupPosition) {
        case BubbleGroupPosition.single:
          radius = const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );
          break;
        case BubbleGroupPosition.first:
          radius = BorderRadius.only(topLeft: tight, topRight: wide, bottomLeft: wide, bottomRight: wide);
          break;
        case BubbleGroupPosition.middle:
          radius = BorderRadius.only(topLeft: tight, topRight: wide, bottomLeft: wide, bottomRight: wide);
          break;
        case BubbleGroupPosition.last:
          radius = BorderRadius.only(topLeft: tight, topRight: wide, bottomLeft: wide, bottomRight: wide);
          break;
      }
    }

    final hasReactions = widget.reactions.isNotEmpty;

    // Для медиа делаем равномерные скругления со всех сторон,
    // без «хвоста» как у текстовых пузырей
    if (widget.isMedia) {
      radius = BorderRadius.circular(12);
    }

    final bubble = LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth * 0.86; // ближе к краям

        // Внутреннее содержимое пузыря
        final Widget inner = Padding(
          padding: widget.isMedia ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DefaultTextStyle.merge(
            style: const TextStyle(decoration: TextDecoration.none),
            child: Stack(
              children: [
                // Контент: имя отправителя + текст или произвольное содержимое
                Padding(
                  padding: EdgeInsets.only(right: widget.isMedia ? 0 : 58),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.isMedia && !isMine && widget.senderName != null && widget.senderName!.isNotEmpty) ...[
                        Text(
                          widget.senderName!,
                          style: const TextStyle(
                            color: Color(0xFF388E3C),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (widget.body != null)
                        widget.body!
                      else
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.none,
                            decorationColor: Colors.transparent,
                          ),
                        ),
                      if (hasReactions) ...[
                        const SizedBox(height: 6),
                        Container(
                          key: _reactionsKey,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: widget.reactions.entries.map((e) {
                                final emoji = e.key;
                                final reactors = e.value;
                                final isMineReacted = widget.myReactions.contains(emoji);
                                final users = context.read<UserStore>().usersById;
                                final count = reactors.length;
                                final showAvatars = count > 0 && count <= 3;
                                final avatarIds = reactors.take(3).toList();

                                final chipCore = Container(
                                  key: ValueKey('${emoji}-${count}'),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 13, decoration: TextDecoration.none)),
                                        const SizedBox(width: 6),
                                        if (showAvatars)
                                          Builder(builder: (_) {
                                            final double aw = 18 + (avatarIds.length - 1) * 12.0;
                                            return SizedBox(
                                              width: aw,
                                              height: 18,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  for (int i = 0; i < avatarIds.length; i++)
                                                    Positioned(
                                                      left: i * 12.0,
                                                      child: _buildInitialAvatar(avatarIds[i], users, size: 18),
                                                    ),
                                                ],
                                              ),
                                            );
                                          })
                                        else
                                          Text('$count', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                );

                                // Pulse key changes when set of reactors or my own toggle changes
                                final int reactorsHash = reactors.fold<int>(0, (acc, id) => acc ^ id.hashCode);
                                final int pulseKey = reactorsHash ^ (isMineReacted ? 1 : 0);

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) {
                                    _cancelHoldTimer();
                                    _animateTo(1.0);
                                  },
                                  onTap: () => widget.onTapReaction?.call(emoji),
                                  child: _PulseOnChange(
                                    triggerKey: pulseKey,
                                    child: chipCore,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Время и статус внизу справа
                if (widget.isMedia)
                  Positioned(
                    right: 4,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(widget.time),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 4),
                            Icon(
                              widget.status == MessageStatus.read
                                  ? Icons.done_all
                                  : widget.status == MessageStatus.sent
                                      ? Icons.check
                                      : Icons.access_time,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 4,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(widget.time),
                          style: const TextStyle(
                            color: TelegramColors.textSecondary,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                            decorationColor: Colors.transparent,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          _statusIcon(),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: widget.isMedia
              ? inner
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: radius,
                    boxShadow: const [
                      BoxShadow(color: TelegramColors.messageShadow, blurRadius: 2, offset: Offset(0, 1)),
                    ],
                  ),
                  child: inner,
                ),
        );
      },
    );

    final bubbleInteractive = GestureDetector(
      onTap: widget.onTap,
      onTapDown: (details) {
        // Если тап в зоне реакций — игнорируем долгий тап
        if (_isPointInsideReactions(details.globalPosition)) {
          _cancelHoldTimer();
          _animateTo(1.0);
          return;
        }
        _animateTo(0.96);
        _startHoldTimer();
      },
      onTapUp: (_) {
        _animateTo(1.0);
        _cancelHoldTimer();
      },
      onTapCancel: () {
        _animateTo(1.0);
        _cancelHoldTimer();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: SelectionContainer.disabled(child: bubble),
      ),
    );

    // Disable ink/highlight/focus colors that could appear as yellow outlines on web
    final theme = Theme.of(context).copyWith(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
    );

    return Theme(data: theme, child: bubbleInteractive);
  }
}

/// Позиция пузыря внутри группы последовательных сообщений одного отправителя
enum BubbleGroupPosition { single, first, middle, last }

class _PulseOnChange extends StatefulWidget {
  final int triggerKey;
  final Widget child;
  const _PulseOnChange({required this.triggerKey, required this.child});

  @override
  State<_PulseOnChange> createState() => _PulseOnChangeState();
}

class _PulseOnChangeState extends State<_PulseOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));

  @override
  void didUpdateWidget(covariant _PulseOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.triggerKey != widget.triggerKey) {
      _play();
    }
  }

  void _play() async {
    try {
      await _c.forward(from: 0);
      await _c.reverse();
    } catch (_) {}
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutBack);
    return ClipRect(
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.12).animate(anim),
        child: widget.child,
      ),
    );
  }
} 