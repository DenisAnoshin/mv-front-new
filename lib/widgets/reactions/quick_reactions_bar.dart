import 'package:flutter/material.dart';
import 'reaction_button.dart';

class QuickReactionsBar extends StatelessWidget {
  final List<String> emojis;
  final VoidCallback onExpand;
  final void Function(String emoji) onTapReaction;
  final double width;
  final double height;
  final Set<String> selected;

  const QuickReactionsBar({
    super.key,
    required this.emojis,
    required this.onExpand,
    required this.onTapReaction,
    this.width = 300,
    this.height = 48,
    this.selected = const {},
  });

  @override
  Widget build(BuildContext context) {
    final quick = emojis.take(5).toList();
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const SizedBox(width: 12),
            for (final e in quick) ...[
              ReactionButton(emoji: e, onTap: () => onTapReaction(e), selected: selected.contains(e)),
              const SizedBox(width: 10),
            ],
            const SizedBox(width: 6),
            _ExpandButton(onTap: onExpand),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ExpandButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFEDEDED)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF6C757D)),
      ),
    );
  }
} 