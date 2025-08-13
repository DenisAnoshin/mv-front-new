import 'package:flutter/material.dart';
import '../../theme/telegram_colors.dart';

class ChatHeaderTitle extends StatelessWidget {
  final String title;
  final String status;
  final VoidCallback? onTap;

  const ChatHeaderTitle({super.key, required this.title, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TelegramColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TelegramColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(behavior: HitTestBehavior.translucent, onTap: onTap, child: content);
  }
} 