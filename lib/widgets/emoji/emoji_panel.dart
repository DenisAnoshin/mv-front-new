import 'package:flutter/material.dart';
import '../reactions/reaction_button.dart';

class EmojiPanel extends StatelessWidget {
  final void Function(String emoji) onSelect;
  final double height;
  final bool rounded;
  const EmojiPanel({super.key, required this.onSelect, this.height = 320, this.rounded = true});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> groups = <String, List<String>>{
      'Анимированные': ['👍', '❤️', '🤣', '🔥', '😭', '💯', '💩', '😡', '😍', '🥳', '👎', '😱', '😮‍💨', '🤮', '💣', '💔', '💀', '🤟', '🎉', '🫣'],
      'Смайлы и люди': ['😀','😃','😄','😁','😆','🥹','🙂','😉','😊','😇','🥰','😘','😗','😙','😚','🫠','😋','😛','😜','🤪','😝','🤑','🤗','🤫','🤭','🤔','🤐','🤨','😐','😑','😶','😏','🙄','😬','🤥','😴','🤒','🤕','🤧','🤮','🤢','🥵','🥶','🤯','😵','🤠','🥸'],
      'Жесты': ['👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','🫶','👐'],
      'Животные и природа': ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐻‍❄️','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🐔','🐧','🐦','🐤','🦆','🦅','🦉','🦇','🐺','🐗','🐴','🦄','🐝','🪲','🦋','🐞','🦂','🐢','🐍','🦎','🦖','🐙','🦑','🪼','🐠','🐟','🐡','🐬','🐳','🐋','🦈'],
    };

    final BorderRadius radius = rounded
        ? const BorderRadius.vertical(top: Radius.circular(18))
        : BorderRadius.zero;

    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: radius,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6C757D)),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final em in entry.value)
                        ReactionButton(emoji: em, onTap: () => onSelect(em)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 