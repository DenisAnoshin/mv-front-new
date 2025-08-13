import 'package:flutter/material.dart';
import '../../theme/telegram_colors.dart';
import '../avatar_circle.dart';
import 'chat_header_title.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String status;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;

  const ChatAppBar({
    super.key,
    required this.title,
    required this.status,
    required this.onBack,
    required this.onOpenProfile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: TelegramColors.textPrimary, size: 20),
        onPressed: onBack,
        tooltip: 'Back',
      ),
      centerTitle: true,
      title: ChatHeaderTitle(title: title, status: status, onTap: onOpenProfile),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: onOpenProfile,
            customBorder: const CircleBorder(),
            child: AvatarCircle(title: title, size: 32, showOnline: true, onTap: onOpenProfile),
          ),
        ),
      ],
    );
  }
} 