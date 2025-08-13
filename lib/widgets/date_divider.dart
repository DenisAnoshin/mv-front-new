import 'package:flutter/material.dart';
import '../theme/telegram_colors.dart';

class DateDivider extends StatelessWidget {
  final String label;
  const DateDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: TelegramColors.divider, height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TelegramColors.divider),
              boxShadow: const [
                BoxShadow(color: TelegramColors.messageShadow, blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(color: TelegramColors.textSecondary, fontSize: 12),
            ),
          ),
          const Expanded(child: Divider(color: TelegramColors.divider, height: 1)),
        ],
      ),
    );
  }
} 