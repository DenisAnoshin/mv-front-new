import 'package:flutter/material.dart';
import 'reaction_button.dart';

class EmojiPickerInline extends StatelessWidget {
  final List<String> categoryTitles;
  final Map<int, List<String>> categoryEmojis;
  final void Function(String emoji) onSelect;
  final double width;
  final double height;
  final Set<String> selected;

  const EmojiPickerInline({
    super.key,
    required this.categoryTitles,
    required this.categoryEmojis,
    required this.onSelect,
    this.width = 300,
    this.height = 200,
    this.selected = const {},
  });

  @override
  Widget build(BuildContext context) {
    const Color secondaryText = Color(0xFF6C757D);
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < categoryTitles.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(categoryTitles[i], style: const TextStyle(fontSize: 16, color: secondaryText)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final em in (categoryEmojis[i] ?? const <String>[]))
                        ReactionButton(emoji: em, onTap: () => onSelect(em), selected: selected.contains(em)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 