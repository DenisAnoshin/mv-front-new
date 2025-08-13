import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/telegram_colors.dart';
import 'reactions/quick_reactions_bar.dart';
import 'reactions/emoji_picker_inline.dart';

class MessageContextMenu extends StatefulWidget {
  final Rect anchorRect;
  final bool showReadInfo;
  final String? readAtText;
  final List<String> reactionEmojis;
  final void Function(String emoji) onTapReaction;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onPin;
  final VoidCallback onForward;
  final VoidCallback onDelete;
  final Widget messagePreview;
  final double progress; // kept for compatibility

  const MessageContextMenu({
    super.key,
    required this.anchorRect,
    required this.reactionEmojis,
    required this.onTapReaction,
    required this.onReply,
    required this.onCopy,
    required this.onPin,
    required this.onForward,
    required this.onDelete,
    required this.messagePreview,
    this.showReadInfo = false,
    this.readAtText,
    this.progress = 1.0,
  });

  @override
  State<MessageContextMenu> createState() => _MessageContextMenuState();
}

class _MessageContextMenuState extends State<MessageContextMenu> {
  final ScrollController _scrollController = ScrollController();
  bool _show = false;
  static const _dur = Duration(milliseconds: 240);

  // Picker state
  bool _showPicker = false;
  final GlobalKey _pickerKey = GlobalKey();

  static const List<String> _categories = [
    '😊', '👍', '🐱', '🍔', '⚽', '🌍', '💡', '🔣'
  ];
  static const Map<int, List<String>> _categoryEmojis = {
    0: ['😀','😁','😂','🤣','😊','😍','😘','😜','🤪','🤗','🤔','🤭','🤫','😴','🥳','🥺','😎','🤩'],
    1: ['👍','👎','👌','🤙','👏','🙌','💪','🙏','🤝','🤟','✌️','👊','🖐️','👉','👈','☝️','👇'],
    2: ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🦄'],
    3: ['🍏','🍎','🍊','🍋','🍌','🍉','🍇','🍓','🍒','🍑','🍍','🥭','🥝','🍅','🥕','🌮','🍔','🍟','🍕'],
    4: ['⚽','🏀','🏈','⚾','🎾','🏐','🏉','🥏','🎱','🏓','🏸','🥊','🥋','🎳','⛳','🥌'],
    5: ['🚗','✈️','🚀','🚲','🛵','🚂','🛴','🚁','🛳️','⛵','🏝️','🏔️','🏙️','🗼','🗽'],
    6: ['💡','💎','🎁','🎈','📦','📱','💻','🖥️','🖱️','⌚','📷','🎧','🔑','🔨','🧰'],
    7: ['❤️','💔','✨','⭐','🔥','❄️','⚡','✅','❌','⭕','🔺','🔻','🔶','🔷','➕','➖','➗','✔️'],
  };

  Set<String> _myReactions = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _show = true);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to read my reactions from preview bubble if it exposes them via inherited widgets —
    // since it's a plain Widget, we allow caller to set _myReactions through state lifting via setState when opening.
  }

  @override
  Widget build(BuildContext context) {
    // Align to side of sender
    final screenW = MediaQuery.of(context).size.width;
    final isMine = widget.anchorRect.center.dx > screenW / 2;
    final horizontalAlign = isMine ? Alignment.centerRight : Alignment.centerLeft;

    Widget animatedBlock(Widget child, {int delayMs = 0}) => child
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: _dur, curve: Curves.easeOutCubic)
        .slideY(begin: 0.45, end: 0, duration: _dur, curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.94, end: 1.0, duration: _dur, curve: Curves.easeOutBack);

    final menuMaterial = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.12),
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showReadInfo && widget.readAtText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    const Icon(Icons.done_all, size: 16, color: Color(0xFF4FC3F7)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(widget.readAtText!, style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D)))),
                  ],
                ),
              ),
            _menuItem(context, label: 'Reply', icon: Icons.reply_outlined, onTap: widget.onReply),
            _divider(),
            _menuItem(context, label: 'Copy', icon: Icons.copy_outlined, onTap: widget.onCopy),
            _divider(),
            _menuItem(context, label: 'Pin', icon: Icons.push_pin_outlined, onTap: widget.onPin),
            _divider(),
            _menuItem(context, label: 'Forward', icon: Icons.forward_outlined, onTap: widget.onForward),
            _divider(),
            _menuItem(context, label: 'Delete', icon: Icons.delete_outline, onTap: widget.onDelete, danger: true),
          ],
        ),
      ),
    );

    final reactionsKey = GlobalKey();
    final reactionsMaterial = Material(
      key: reactionsKey,
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.12),
      child: QuickReactionsBar(
        emojis: widget.reactionEmojis,
        onExpand: () => setState(() => _showPicker = !_showPicker),
        onTapReaction: (e) {
          widget.onTapReaction(e);
          setState(() => _myReactions = _toggleLocal(_myReactions, e));
        },
        width: 300,
        height: 48,
        selected: _myReactions,
      ),
    );

    final previewKey = GlobalKey();
    final menuBlockKey = GlobalKey();

    final menu = Align(alignment: horizontalAlign, child: animatedBlock(Container(key: menuBlockKey, child: menuMaterial), delayMs: 20));
    final reactions = Align(alignment: horizontalAlign, child: animatedBlock(reactionsMaterial, delayMs: 0));
    final preview = Align(alignment: horizontalAlign, child: animatedBlock(Container(key: previewKey, child: widget.messagePreview), delayMs: 10));

    final pickerInline = _showPicker
        ? Align(
            alignment: horizontalAlign,
            child: Container(
              key: _pickerKey,
              width: 300,
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: EmojiPickerInline(
                categoryTitles: _categories,
                categoryEmojis: _categoryEmojis,
                onSelect: (em) {
                  widget.onTapReaction(em);
                  setState(() {
                    _myReactions = _toggleLocal(_myReactions, em);
                    _showPicker = false;
                  });
                },
                selected: _myReactions,
              ),
            ).animate().fadeIn(duration: 160.ms).scaleXY(begin: 0.96, end: 1.0, duration: 180.ms, curve: Curves.easeOutBack),
          )
        : const SizedBox.shrink();

    return FocusTraversalGroup(
      descendantsAreFocusable: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10 * (_show ? 1 : 0).toDouble(), sigmaY: 10 * (_show ? 1 : 0).toDouble()),
              child: Container(color: Colors.white.withOpacity(0.08 * (_show ? 1 : 0).toDouble())),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        reactions,
                        const SizedBox(height: 8),
                        pickerInline,
                        if (_showPicker) const SizedBox(height: 8),
                        preview,
                        const SizedBox(height: 10),
                        menu,
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                Rect rectFromKey(GlobalKey key) {
                  final ctx = key.currentContext;
                  if (ctx == null) return Rect.zero;
                  final box = ctx.findRenderObject() as RenderBox?;
                  if (box == null) return Rect.zero;
                  final topLeft = box.localToGlobal(Offset.zero);
                  return Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height);
                }

                final bubbleRect = rectFromKey(previewKey);
                final reactionsRect = reactionsKey.currentContext != null ? rectFromKey(reactionsKey) : Rect.zero;
                final menuRect = rectFromKey(menuBlockKey);
                final pickerRect = _showPicker && _pickerKey.currentContext != null ? rectFromKey(_pickerKey) : Rect.zero;
                final pos = event.position;
                final tappedInside = bubbleRect.contains(pos) || reactionsRect.contains(pos) || menuRect.contains(pos) || pickerRect.contains(pos);
                if (!tappedInside) Navigator.of(context).pop();
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Set<String> _toggleLocal(Set<String> set, String emoji) {
    final s = Set<String>.from(set);
    if (s.contains(emoji)) {
      s.remove(emoji);
    } else {
      s.add(emoji);
    }
    return s;
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFEDEDED));

  Widget _menuItem(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap, bool danger = false}) {
    final color = danger ? Colors.red : const Color(0xFF212529);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 16))),
            const SizedBox(width: 12),
            Icon(icon, color: color),
          ],
        ),
      ),
    );
  }
} 