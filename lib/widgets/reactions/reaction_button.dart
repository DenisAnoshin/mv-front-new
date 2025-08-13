import 'package:flutter/material.dart';

class ReactionButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;
  final bool selected;
  const ReactionButton({super.key, required this.emoji, required this.onTap, this.selected = false});

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _pulse() async {
    setState(() => _scale = 1.08);
    await Future.delayed(const Duration(milliseconds: 110));
    if (!mounted) return;
    setState(() => _scale = 1.0);
  }

  @override
  void didUpdateWidget(covariant ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _pulse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: widget.selected ? Colors.black.withOpacity(0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(widget.emoji, style: const TextStyle(fontSize: 22.0)),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onTap();
        _pulse();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: content,
        ),
      ),
    );
  }
} 